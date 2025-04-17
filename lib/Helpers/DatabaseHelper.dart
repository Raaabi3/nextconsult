import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app_database.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        content BLOB,
        path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // User operations
  Future<int> insertUser(String email, String password) async {
    final db = await database;
    return await db.insert(
      'users',
      {'email': email, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // File operations
  Future<int> insertFile({
    required int userId,
    required String name,
    required String type,
    Uint8List? content,
    String? path,
  }) async {
    final db = await database;
    return await db.insert(
      'files',
      {
        'user_id': userId,
        'name': name,
        'type': type,
        'content': content,
        'path': path,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUserFiles(int userId) async {
    final db = await database;
    return await db.query(
      'files',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteFile(int fileId) async {
    final db = await database;
    return await db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [fileId],
    );
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}