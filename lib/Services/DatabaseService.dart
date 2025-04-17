import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'nextconsult.db');

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        isLoggedIn INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0,
        unlockCode TEXT
      )
    ''');
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<int> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    return await db.insert(
      'users',
      {
        'name': name,
        'email': email,
        'password': _hashPassword(password),
        'isLoggedIn': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> validateUser(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user == null) return false;
    return user['password'] == _hashPassword(password);
  }

  Future<void> updateLoginStatus(String email, bool isLoggedIn) async {
    final db = await database;
    await db.update(
      'users',
      {'isLoggedIn': isLoggedIn ? 1 : 0},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> lockAccount(String email, String unlockCode) async {
    final db = await database;
    await db.update(
      'users',
      {
        'isLocked': 1,
        'unlockCode': _hashPassword(unlockCode),
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> unlockAccount(String email) async {
    final db = await database;
    await db.update(
      'users',
      {
        'isLocked': 0,
        'unlockCode': null,
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}