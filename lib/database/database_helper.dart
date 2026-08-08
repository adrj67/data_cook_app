import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static bool _initialized = false;

  // Inicializar el factory para Windows/Linux/Mac
  static void initialize() {
    if (!_initialized) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        databaseFactory = databaseFactoryFfi;
      }
      _initialized = true;
    }
  }

  // Ruta a la base de datos
  String get dbPath {
    final currentDir = Directory.current.path;
    final appDataCookDir = path.normalize(path.join(currentDir, '..'));
    return path.join(appDataCookDir, 'datacook.db');
  }

  Future<Database> get database async {
    initialize();
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Base de datos no encontrada en: $dbPath\n'
          'Por favor, procesa un archivo SEPA primero.');
    }

    return await openDatabase(
      dbPath,
      readOnly: true,
    );
  }

  // === MÉTODOS OPTIMIZADOS PARA LA ESTRUCTURA CONOCIDA ===

  // Buscar productos por descripción
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'descripcion LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
      orderBy: 'descripcion ASC',
    );
  }

  // Obtener todos los productos
  Future<List<Map<String, dynamic>>> getAllProducts({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'productos',
      limit: limit,
      orderBy: 'descripcion ASC',
    );
  }

  // Obtener producto por ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id_producto = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Obtener productos por rango de precio
  Future<List<Map<String, dynamic>>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'precio_promedio >= ? AND precio_promedio <= ?',
      whereArgs: [minPrice, maxPrice],
      limit: limit,
      orderBy: 'precio_promedio ASC',
    );
  }

  // Obtener productos más económicos
  Future<List<Map<String, dynamic>>> getCheapestProducts({int limit = 20}) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'precio_promedio > 0',
      limit: limit,
      orderBy: 'precio_promedio ASC',
    );
  }

  // Obtener productos más caros
  Future<List<Map<String, dynamic>>> getMostExpensiveProducts({int limit = 20}) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'precio_promedio > 0',
      limit: limit,
      orderBy: 'precio_promedio DESC',
    );
  }

  // Obtener productos por cantidad de sucursales
  Future<List<Map<String, dynamic>>> getProductsBySucursales({
    int minSucursales = 2,
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'cantidad_sucursales >= ?',
      whereArgs: [minSucursales],
      limit: limit,
      orderBy: 'cantidad_sucursales DESC',
    );
  }

  // Contar total de productos
  Future<int> getTotalProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM productos');
    return result.isNotEmpty ? result.first['total'] as int? ?? 0 : 0;
  }

  // Obtener estadísticas de productos
  Future<Map<String, dynamic>> getProductStats() async {
    final db = await database;
    
    final stats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        AVG(precio_promedio) as precio_promedio,
        MIN(precio_promedio) as precio_minimo,
        MAX(precio_promedio) as precio_maximo,
        AVG(cantidad_sucursales) as sucursales_promedio
      FROM productos
      WHERE precio_promedio > 0
    ''');
    
    return stats.isNotEmpty ? stats.first : {};
  }

  // Cerrar la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}