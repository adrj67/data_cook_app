import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Ruta a la base de datos (la misma que genera Python)
  String get dbPath {
    final currentDir = Directory.current.path;
    // Subir un nivel (desde data_cook_app/ a App_DataCook/)
    final appDataCookDir = path.normalize(path.join(currentDir, '..'));
    return path.join(appDataCookDir, 'datacook.db');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Verificar que la base de datos existe
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Base de datos no encontrada en: $dbPath\n'
          'Por favor, procesa un archivo SEPA primero.');
    }

    // Abrir la base de datos
    return await openDatabase(
      dbPath,
      readOnly: true, // Solo lectura
    );
  }

  // Ejemplo: Buscar productos por nombre
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'nombre LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
    );
  }

  // Ejemplo: Obtener un producto por ID
  Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Ejemplo: Obtener todos los productos (con límite)
  Future<List<Map<String, dynamic>>> getAllProducts({int limit = 100}) async {
    final db = await database;
    return await db.query(
      'productos',
      limit: limit,
    );
  }

  // Cerrar la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}