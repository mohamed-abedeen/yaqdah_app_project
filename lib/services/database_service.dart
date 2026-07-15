import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
      version: 10,
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
        salt TEXT NOT NULL,
        fullName TEXT NOT NULL,
        emergencyContact TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        duration TEXT NOT NULL,
        distance TEXT NOT NULL,
        status TEXT NOT NULL,
        alerts TEXT,
        startTime TEXT,
        endTime TEXT,
        avgSpeed TEXT,
        maxSpeed TEXT,
        routePath TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'pending',
        firestoreId TEXT,
        score INTEGER NOT NULL DEFAULT 100
      )
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        userId TEXT PRIMARY KEY,
        level INTEGER NOT NULL DEFAULT 1,
        totalSafeKm REAL NOT NULL DEFAULT 0.0,
        badges TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      // Full reset: drop old tables and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS trips');
      await db.execute('DROP TABLE IF EXISTS user_stats');
      await _createDB(db, newVersion);
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
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
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);
      await db.insert('users', {
        'email': email,
        'password': hashedPassword,
        'salt': salt,
        'fullName': fullName,
        'emergencyContact': emergencyContact,
      });
      if (kDebugMode) {
        await debugPrintAllUsers();
      }
      return true;
    } catch (e) {
      debugPrint("❌ Register Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;

    final userCheck = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (userCheck.isEmpty) return null;

    final storedUser = userCheck.first;
    final salt = storedUser['salt'] as String;
    final hashedPassword = _hashPassword(password, salt);
    if (storedUser['password'] != hashedPassword) return null;

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
    required String userId,
    required String duration,
    required String distance,
    required String status,
    required List<String> alerts,
    required int score,
    required String startTime,
    required String endTime,
    required String avgSpeed,
    required String maxSpeed,
    required List<Map<String, double>> routePath,
    String? customDate,
  }) async {
    final db = await instance.database;
    await db.insert('trips', {
      'userId': userId,
      'date': customDate ?? DateTime.now().toIso8601String(),
      'duration': duration,
      'distance': distance,
      'status': status,
      'alerts': jsonEncode(alerts),
      'score': score,
      'startTime': startTime,
      'endTime': endTime,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'routePath': jsonEncode(routePath),
    });
  }

  Future<List<Map<String, dynamic>>> getTrips(String userId) async {
    final db = await instance.database;
    return await db.query(
      'trips',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<int> deleteTrip(int id, String userId) async {
    final db = await instance.database;
    return await db.delete(
      'trips',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> debugPrintAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    if (result.isNotEmpty) {
      for (var row in result) {
        debugPrint(row.toString());
      }
    }
  }

  /// Get all trips that haven't been synced to Firestore yet.
  Future<List<Map<String, dynamic>>> getUnsyncedTrips(String userId) async {
    final db = await instance.database;
    return await db.query(
      'trips',
      where: 'userId = ? AND syncStatus = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'date ASC',
    );
  }

  /// Mark a trip as synced with its Firestore document ID.
  Future<void> markTripSynced(int localId, String firestoreId) async {
    final db = await instance.database;
    await db.update(
      'trips',
      {'syncStatus': 'synced', 'firestoreId': firestoreId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Get the ID of the last inserted trip.
  Future<int?> getLastInsertedTripId() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT last_insert_rowid() as id');
    return result.first['id'] as int?;
  }

  /// Get user gamification stats
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_stats',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Update user gamification stats
  Future<void> updateUserStats(
    String userId,
    int level,
    double totalSafeKm,
    List<String> badges,
  ) async {
    final db = await instance.database;
    await db.insert('user_stats', {
      'userId': userId,
      'level': level,
      'totalSafeKm': totalSafeKm,
      'badges': jsonEncode(badges),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
