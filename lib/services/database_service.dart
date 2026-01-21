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

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
        alerts TEXT,
        startTime TEXT,
        endTime TEXT,
        avgSpeed TEXT,
        maxSpeed TEXT
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
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE trips ADD COLUMN startTime TEXT');
      await db.execute('ALTER TABLE trips ADD COLUMN endTime TEXT');
      await db.execute('ALTER TABLE trips ADD COLUMN avgSpeed TEXT');
      await db.execute('ALTER TABLE trips ADD COLUMN maxSpeed TEXT');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

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
      });
      await debugPrintAllUsers(); // Show users after adding
      return true;
    } catch (e) {
      print("❌ Register Error: $e");
      return false;
    }
  }

  // ✅ UPDATED: Detailed Debugging for Login
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    print("\n🔍 --- LOGIN ATTEMPT ---");
    print("Trying to log in with Email: '$email'");

    // 1. Check if email exists
    final userCheck = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (userCheck.isEmpty) {
      print("❌ Login Failed: Email NOT FOUND in database.");
      return null;
    }

    // 2. Check password
    final storedUser = userCheck.first;
    final storedHash = storedUser['password'];

    print("✅ Email found.");
    print("Input Password Hash:  $hashedPassword");
    print("Stored Password Hash: $storedHash");

    if (storedHash != hashedPassword) {
      print("❌ Login Failed: Password HASH MISMATCH.");
      return null;
    }

    print("✅ Login Success!");
    print("-----------------------\n");
    return storedUser;
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

  Future<int> updateUser(
    String email,
    String newName,
    String newEmergency,
  ) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'fullName': newName, 'emergencyContact': newEmergency},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> saveTrip({
    required String duration,
    required String distance,
    required String status,
    required List<String> alerts,
    required String startTime,
    required String endTime,
    required String avgSpeed,
    required String maxSpeed,
  }) async {
    final db = await instance.database;
    await db.insert('trips', {
      'date': DateTime.now().toIso8601String(),
      'duration': duration,
      'distance': distance,
      'status': status,
      'alerts': jsonEncode(alerts),
      'startTime': startTime,
      'endTime': endTime,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
    });
  }

  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await instance.database;
    return await db.query('trips', orderBy: 'date DESC');
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> debugPrintAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    print("\n========= 👤 USERS TABLE DUMP =========");
    if (result.isEmpty) {
      print("No users found.");
    } else {
      for (var row in result) {
        print(row);
      }
    }
    print("=======================================\n");
  }
}
