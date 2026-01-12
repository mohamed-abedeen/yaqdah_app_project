import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Singleton pattern (only one instance of the database exists)
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();
  Future<int> updateUser(String email, String newName, String newPhone) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'fullName': newName, 'phone': newPhone},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // Get the database (open it if it doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yaqdah.db');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Create Tables (Run only once when the app is first installed)
  Future _createDB(Database db, int version) async {
    // 1. USERS TABLE (For Login/Signup)
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      fullName TEXT NOT NULL,
      phone TEXT
    )
    ''');

    // 2. TRIPS TABLE (For Reports)
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

  // ==========================================
  // USER METHODS (Auth)
  // ==========================================

  // Sign Up
  Future<bool> registerUser(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    final db = await instance.database;
    try {
      debugPrint("Attempting to register: $email"); // 🔍 DEBUG PRINT

      int id = await db.insert('users', {
        'email': email,
        'password': password,
        'fullName': name,
        'phone': phone,
      });

      debugPrint("User Registered! ID: $id"); // 🔍 DEBUG PRINT
      return true;
    } catch (e) {
      debugPrint("❌ REGISTRATION ERROR: $e"); // 🔍 READ THIS IN CONSOLE
      return false;
    }
  }

  // 2. UPDATED LOGIN METHOD (With Debug Prints)
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    debugPrint(
      "Attempting login for: $email with pass: $password",
    ); // 🔍 DEBUG PRINT

    try {
      final maps = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (maps.isNotEmpty) {
        debugPrint(
          "Login Successful! User found: ${maps.first}",
        ); // 🔍 DEBUG PRINT
        return maps.first;
      } else {
        debugPrint("❌ Login Failed: User not found in DB"); // 🔍 DEBUG PRINT

        // OPTIONAL: Print all users to see who IS in there
        final allUsers = await db.query('users');
        debugPrint("DUMP: Current Users in DB: $allUsers");

        return null;
      }
    } catch (e) {
      debugPrint("❌ SQL ERROR: $e");
      return null;
    }
  }

  // ==========================================
  // TRIP METHODS (Reports)
  // ==========================================

  // Save a new trip (Call this when "End Trip" is pressed)
  Future<void> saveTrip(String duration, String distance, String status) async {
    final db = await instance.database;
    await db.insert('trips', {
      'date': DateTime.now().toIso8601String(), // Saves current time
      'duration': duration,
      'distance': distance,
      'status': status, // e.g., "Safe Trip" or "Drowsiness Alert"
    });
    debugPrint("Trip Saved to SQLite!");
  }

  // Get all trips (For the Reports Screen)
  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await instance.database;
    // Get trips, newest first
    return await db.query('trips', orderBy: 'date DESC');
  }

  // Get stats (Optional: for your charts)
  Future<Map<String, int>> getStats() async {
    final db = await instance.database;
    final trips = await db.query('trips');

    int totalKm = 0;
    int alerts = 0;

    for (var trip in trips) {
      // Simple parsing logic (assuming distance is like "12 km")
      String distStr = trip['distance'] as String;
      distStr = distStr.replaceAll(RegExp(r'[^0-9.]'), ''); // remove ' km'
      totalKm += double.tryParse(distStr)?.toInt() ?? 0;

      if (trip['status'] == 'Drowsy') alerts++;
    }

    return {
      'totalTrips': trips.length,
      'totalKm': totalKm,
      'totalAlerts': alerts,
    };
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }
}
