import 'package:flutter/material.dart';
import 'dart:convert';
import '../../database/database_helper.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  int _totalProducts = 0;
  Map<String, dynamic> _stats = {};
  bool _showAllProducts = false; // Mostrar todos o solo los útiles

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtener total de productos
      _totalProducts = await _dbHelper.getTotalProducts();
      
      // Obtener estadísticas
      _stats = await _dbHelper.getProductStats();

      // Cargar productos (inicialmente solo 100)
      final products = await _dbHelper.getAllProducts(limit: 200);
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cargar todos los productos
  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _dbHelper.getAllProducts(limit: 5000);
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _showAllProducts = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
      return;
    }

    final searchLower = query.toLowerCase().trim();
    
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Buscar en descripción (campo principal)
        final descripcion = product['descripcion']?.toString().toLowerCase() ?? '';
        
        // Buscar en ID del producto
        final idProducto = product['id_producto']?.toString().toLowerCase() ?? '';
        
        // Buscar en unidad de medida
        final unidad = product['unidad_medida']?.toString().toLowerCase() ?? '';
        
        // Buscar en múltiples campos
        return descripcion.contains(searchLower) ||
               idProducto.contains(searchLower) ||
               unidad.contains(searchLower);
      }).toList();
    });
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    try {
      final value = double.parse(price.toString());
      if (value == 0) return 'N/A';
      return '\$${value.toStringAsFixed(2)}';
    } catch (e) {
      return price.toString();
    }
  }

  // Decodificar JSON de precios
  List<dynamic> _decodeJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return json.decode(jsonStr);
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Productos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, código o unidad...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: _searchProducts,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Información de la base de datos
                    _buildDatabaseInfo(),
                    
                    // Botón para cargar más productos
                    if (!_showAllProducts && _allProducts.length < _totalProducts)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: _loadAllProducts,
                          icon: const Icon(Icons.download),
                          label: Text('Cargar todos los productos (${_totalProducts - _allProducts.length} restantes)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    
                    // Lista de productos
                    Expanded(
                      child: _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No se encontraron productos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    Text(
                                      'Para: "${_searchController.text}"',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchProducts('');
                                    },
                                    child: const Text('Limpiar búsqueda'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDatabaseInfo() {
    final promedio = _stats['precio_promedio'] ?? 0;
    final precioMin = _stats['precio_minimo'] ?? 0;
    final precioMax = _stats['precio_maximo'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.storage,
                label: 'Total',
                value: _totalProducts.toString(),
              ),
              _buildInfoItem(
                icon: Icons.visibility,
                label: 'Cargados',
                value: _allProducts.length.toString(),
              ),
              _buildInfoItem(
                icon: Icons.search,
                label: 'Filtrados',
                value: _filteredProducts.length.toString(),
              ),
              _buildInfoItem(
                icon: Icons.trending_up,
                label: 'Precio prom.',
                value: _formatPrice(promedio),
              ),
            ],
          ),
          if (_showAllProducts)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Mostrando todos los productos',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final descripcion = product['descripcion']?.toString() ?? 'Sin descripción';
    final idProducto = product['id_producto']?.toString() ?? '';
    final precio = product['precio_promedio'];
    final sucursales = product['cantidad_sucursales'] ?? 0;
    final unidad = product['unidad_medida']?.toString() ?? '';
    final fecha = product['fecha_actualizacion']?.toString() ?? '';

    // Resaltar la palabra buscada
    final searchTerm = _searchController.text.trim();
    Widget titleWidget;
    if (searchTerm.isNotEmpty && descripcion.toLowerCase().contains(searchTerm.toLowerCase())) {
      final parts = descripcion.split(RegExp('($searchTerm)', caseSensitive: false));
      titleWidget = RichText(
        text: TextSpan(
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          children: parts.map((part) {
            if (part.toLowerCase() == searchTerm.toLowerCase()) {
              return TextSpan(
                text: part,
                style: const TextStyle(
                  backgroundColor: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return TextSpan(text: part);
          }).toList(),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      titleWidget = Text(
        descripcion,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            descripcion.isNotEmpty ? descripcion[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: titleWidget,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (idProducto.isNotEmpty)
              Text(
                'Código: $idProducto',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            Row(
              children: [
                Icon(Icons.store, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$sucursales sucursales',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                if (unidad.isNotEmpty)
                  Text(
                    'Unidad: $unidad',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            if (fecha.isNotEmpty)
              Text(
                'Actualizado: ${fecha.split('T').first}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatPrice(precio),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            if (sucursales > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$sucursales',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          _showProductDetail(product);
        },
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    final preciosLista = _decodeJson(product['precios_lista'] as String?);
    final sucursalesLista = _decodeJson(product['id_sucursales'] as String?);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          product['descripcion'] ?? 'Producto',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID Producto', product['id_producto']?.toString() ?? 'N/A'),
              _buildDetailRow('Precio promedio', _formatPrice(product['precio_promedio'])),
              _buildDetailRow('Precio referencia', _formatPrice(product['precio_referencia'])),
              _buildDetailRow('Cantidad referencia', product['cantidad_referencia']?.toString() ?? 'N/A'),
              _buildDetailRow('Unidad medida', product['unidad_medida']?.toString() ?? 'N/A'),
              _buildDetailRow('Sucursales', product['cantidad_sucursales']?.toString() ?? '0'),
              _buildDetailRow(
                'Fecha actualización',
                product['fecha_actualizacion']?.toString().split('T').first ?? 'N/A',
              ),
              
              if (preciosLista.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Precios por sucursal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...preciosLista.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${_formatPrice(p)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ],
              
              if (sucursalesLista.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'IDs de sucursales:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  sucursalesLista.join(', '),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}