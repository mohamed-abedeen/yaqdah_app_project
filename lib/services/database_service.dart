import 'dart:convert';
import 'package:crypto/crypto.dart';
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

    // ✅ Version increased to 4 (Phone number removed)
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // ✅ Removed 'phone' column
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL, 
        fullName TEXT NOT NULL,
        emergencyContact TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration TEXT NOT NULL,
        distance TEXT NOT NULL,
        status TEXT NOT NULL,
        alerts TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE trips ADD COLUMN alerts TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN emergencyContact TEXT');
    }
    // Note: SQLite does not support dropping columns easily in ALTER TABLE.
    // The 'phone' column will remain for old users but be ignored by the code.
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ✅ Removed 'phone' parameter
  Future<bool> registerUser(
    String email,
    String password,
    String fullName,
    String emergencyContact,
  ) async {
    final db = await instance.database;
    try {
      final hashedPassword = _hashPassword(password);
      await db.insert('users', {
        'email': email,
        'password': hashedPassword,
        'fullName': fullName,
        'emergencyContact': emergencyContact,
        // 'phone': phone, // ❌ Removed
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ✅ Removed 'newPhone' parameter
  Future<int> updateUser(
    String email,
    String newName,
    String newEmergency,
  ) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {
        'fullName': newName,
        'emergencyContact': newEmergency,
        // 'phone': newPhone // ❌ Removed
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> saveTrip(
    String duration,
    String distance,
    String status,
    List<String> alerts,
  ) async {
    final db = await instance.database;
    await db.insert('trips', {
      'date': DateTime.now().toIso8601String(),
      'duration': duration,
      'distance': distance,
      'status': status,
      'alerts': jsonEncode(alerts),
    });
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await instance.database;
    return await db.query('trips', orderBy: 'date DESC');
  }
}
