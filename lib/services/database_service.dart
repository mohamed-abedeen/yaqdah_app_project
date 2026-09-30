import 'dart:async';
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

  /// Bumped whenever trips are added or removed, so screens can reload.
  final ValueNotifier<int> tripsRevision = ValueNotifier<int>(0);
  Timer? _notifyTimer;

  /// Tells screens to reload trips. Bursts (e.g. a cloud import) are
  /// batched into one reload.
  void notifyTripsChanged() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(
      const Duration(milliseconds: 150),
      () => tripsRevision.value++,
    );
  }

  /// Columns of a trip row except the (large) recorded route.
  static const _tripListColumns = [
    'id',
    'userId',
    'date',
    'duration',
    'distance',
    'status',
    'alerts',
    'startTime',
    'endTime',
    'avgSpeed',
    'maxSpeed',
    'syncStatus',
    'firestoreId',
    'score',
  ];

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
      version: 11,
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

    await _createV11Tables(db);
  }

  /// Added in v11: deleted cloud trips (so a sync doesn't bring them back)
  /// and an index for per-user trip lists.
  Future<void> _createV11Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_trips (
        userId TEXT NOT NULL,
        firestoreId TEXT NOT NULL,
        PRIMARY KEY (userId, firestoreId)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_trips_user_date ON trips(userId, date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      // Full reset: drop old tables and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS trips');
      await db.execute('DROP TABLE IF EXISTS user_stats');
      await _createDB(db, newVersion);
      return;
    }
    if (oldVersion < 11) {
      await _convertOldSpeeds(db);
      await _createV11Tables(db);
    }
  }

  /// Before v11, trip speeds were saved in m/s under a "km/h" label.
  Future<void> _convertOldSpeeds(Database db) async {
    final rows = await db.query(
      'trips',
      columns: ['id', 'distance', 'duration', 'avgSpeed', 'maxSpeed'],
    );
    final batch = db.batch();
    for (final row in rows) {
      if (!speedsLookLikeMetersPerSecond(row)) continue;
      batch.update(
        'trips',
        {
          'avgSpeed': kmhLabelFromMetersPerSecond(row['avgSpeed']),
          'maxSpeed': kmhLabelFromMetersPerSecond(row['maxSpeed']),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await batch.commit(noResult: true);
  }

  static double? _number(Object? value) => double.tryParse(
    (value ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''),
  );

  /// Whether a trip's speeds were saved in m/s (older app versions).
  ///
  /// Every trip saved before v11 used m/s, unless it came from a test
  /// build of the redesign. The values themselves can tell: an average over
  /// 40 only makes sense in km/h, and in km/h the average (which skips
  /// stops) is at least distance / time, while in m/s it is well under.
  static bool speedsLookLikeMetersPerSecond(Map<String, Object?> trip) {
    final avg = _number(trip['avgSpeed']);
    if (avg == null || avg <= 0) return false;
    if (avg > 40) return false;
    final max = _number(trip['maxSpeed']) ?? 0;
    final km = _number(trip['distance']) ?? 0;
    final parts = (trip['duration'] ?? '')
        .toString()
        .split(':')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final seconds = parts.length == 3
        ? parts[0] * 3600 + parts[1] * 60 + parts[2]
        : (parts.length == 2 ? parts[0] * 60 + parts[1] : 0);
    if (km >= 0.5 && seconds >= 60) {
      final overallKmh = km / (seconds / 3600);
      if (avg < overallKmh * 0.9) return true;
      if (max > 45 && avg >= overallKmh) return false;
    }
    return true;
  }

  /// "12.5 km/h" from a value saved in m/s.
  static String kmhLabelFromMetersPerSecond(Object? value) =>
      "${((_number(value) ?? 0) * 3.6).toStringAsFixed(1)} km/h";

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

  /// Saves a trip and returns its row id.
  ///
  /// Trips imported from the cloud pass their [firestoreId] and are stored
  /// as already synced; imports pass [notify] false and notify once at the
  /// end.
  Future<int> saveTrip({
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
    String? firestoreId,
    bool notify = true,
  }) async {
    final db = await instance.database;
    final id = await db.insert('trips', {
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
      if (firestoreId != null) ...{
        'firestoreId': firestoreId,
        'syncStatus': 'synced',
      },
    });
    if (notify) notifyTripsChanged();
    return id;
  }

  /// A user's trips, newest first, without their recorded routes (see
  /// [getTripRoute]).
  Future<List<Map<String, dynamic>>> getTrips(String userId) async {
    final db = await instance.database;
    return await db.query(
      'trips',
      columns: _tripListColumns,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  /// The user's most recent trip, without its route.
  Future<Map<String, dynamic>?> getLastTrip(String userId) async {
    final db = await instance.database;
    final rows = await db.query(
      'trips',
      columns: _tripListColumns,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// One whole trip row, route included.
  Future<Map<String, dynamic>?> getTrip(int id) async {
    final db = await instance.database;
    final rows = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  /// The recorded route of a trip as saved (a JSON list of lat/lng).
  Future<String?> getTripRoute(int id) async {
    final db = await instance.database;
    final rows = await db.query(
      'trips',
      columns: ['routePath'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.first['routePath'] as String?;
  }

  /// Firestore ids this phone already has, or deleted and shouldn't re-import.
  Future<Set<String>> getKnownFirestoreIds(String userId) async {
    final db = await instance.database;
    final local = await db.query(
      'trips',
      columns: ['firestoreId'],
      where: 'userId = ? AND firestoreId IS NOT NULL',
      whereArgs: [userId],
    );
    final deleted = await db.query(
      'deleted_trips',
      columns: ['firestoreId'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return {
      for (final row in [...local, ...deleted]) row['firestoreId'] as String,
    };
  }

  Future<bool> isTripDeleted(String userId, String firestoreId) async {
    final db = await instance.database;
    final rows = await db.query(
      'deleted_trips',
      where: 'userId = ? AND firestoreId = ?',
      whereArgs: [userId, firestoreId],
    );
    return rows.isNotEmpty;
  }

  /// Deletes a trip. Its cloud copy, if any, is remembered so a sync
  /// doesn't bring it back.
  Future<int> deleteTrip(int id, String userId) async {
    final db = await instance.database;
    final count = await db.transaction((txn) async {
      final rows = await txn.query(
        'trips',
        columns: ['firestoreId'],
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
      final firestoreId = rows.isEmpty
          ? null
          : rows.first['firestoreId'] as String?;
      if (firestoreId != null && firestoreId.isNotEmpty) {
        await txn.insert('deleted_trips', {
          'userId': userId,
          'firestoreId': firestoreId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return txn.delete(
        'trips',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
    });
    notifyTripsChanged();
    return count;
  }

  /// Deletes every trip of [userId] on this phone and resets their level.
  Future<void> deleteAllTrips(String userId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO deleted_trips (userId, firestoreId) '
        'SELECT userId, firestoreId FROM trips '
        "WHERE userId = ? AND firestoreId IS NOT NULL AND firestoreId != ''",
        [userId],
      );
      await txn.delete('trips', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('user_stats', where: 'userId = ?', whereArgs: [userId]);
    });
    notifyTripsChanged();
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

  /// Records the Firestore id a trip is being uploaded under, before the
  /// upload, so a retry reuses it instead of creating a second copy.
  Future<void> setTripFirestoreId(int localId, String firestoreId) async {
    final db = await instance.database;
    await db.update(
      'trips',
      {'firestoreId': firestoreId},
      where: 'id = ?',
      whereArgs: [localId],
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
