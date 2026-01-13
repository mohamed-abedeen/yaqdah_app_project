import 'dart:convert'; // For utf8
import 'package:crypto/crypto.dart'; // ✅ For Hashing
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yaqdah.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL, 
        fullName TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration TEXT NOT NULL,
        distance TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // ✅ Helper: Hash Password (SHA-256)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register (Hashes password before saving)
  Future<bool> registerUser(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    final db = await instance.database;
    try {
      final hashedPassword = _hashPassword(password); // ✅ Hash it
      await db.insert('users', {
        'email': email,
        'password': hashedPassword,
        'fullName': fullName,
        'phone': phone,
      });
      return true;
    } catch (e) {
      return false; // Email likely exists
    }
  }

  // Login (Hashes input password to compare)
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password); // ✅ Hash it

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<int> updateUser(String email, String newName, String newPhone) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'fullName': newName, 'phone': newPhone},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> saveTrip(String duration, String distance, String status) async {
    final db = await instance.database;
    await db.insert('trips', {
      'date': DateTime.now().toIso8601String(),
      'duration': duration,
      'distance': distance,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await instance.database;
    return await db.query('trips', orderBy: 'date DESC');
  }
}
