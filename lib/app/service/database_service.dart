// 1. DATABASE SERVICE
// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Method untuk inisialisasi database secara eksplisit
  Future<void> initializeDatabase() async {
    if (_database == null) {
      _database = await _initDatabase();
    }
  }

  Future<Database> get database async {
    // Pastikan database sudah diinisialisasi
    await initializeDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'app_database.db');
      print('Database path: $path'); // Debug log

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) {
          print('Database opened successfully'); // Debug log
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      print('Creating database tables...'); // Debug log

      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL
        );

        CREATE TABLE accelerometer(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          x REAL NOT NULL,
          y REAL NOT NULL,
          z REAL NOT NULL,
          timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
      ''');

      // Insert default user untuk testing
      String hashedPassword = _hashPassword('luky123');
      await db.insert('users', {
        'username': 'luky',
        'email': 'luky@gmail.com',
        'password': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Default user created successfully'); // Debug log
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  Future<void> insertSensorAccelerometer(
    double x,
    double y,
    double z,
    DateTime? timestamp,
  ) async {
    try {
      final db = await database;
      await db.insert('accelerometer', {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('Accelerometer data inserted successfully'); // Debug log
    } catch (e) {
      print('Error inserting accelerometer data: $e');
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> authenticateUser(String username, String password) async {
    try {
      final db = await database;
      String hashedPassword = _hashPassword(password);

      print('Authenticating user: $username'); // Debug log

      final result = await db.query(
        'users',
        where: '(username = ? OR email = ?) AND password = ?',
        whereArgs: [username, username, hashedPassword],
      );

      print('Query result: ${result.length} rows found'); // Debug log
      return result.isNotEmpty;
    } catch (e) {
      print('Error authenticating user: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'username = ? OR email = ?',
        whereArgs: [username, username],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Method untuk reset database (berguna untuk testing)
  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'app_database.db');
      await deleteDatabase(path);
      _database = null;
      await initializeDatabase();
      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // Method untuk cek apakah database sudah ada
  Future<bool> isDatabaseExists() async {
    try {
      String path = join(await getDatabasesPath(), 'app_database.db');
      return await databaseExists(path);
    } catch (e) {
      print('Error checking database existence: $e');
      return false;
    }
  }
}
