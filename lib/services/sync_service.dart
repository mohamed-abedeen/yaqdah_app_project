import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

/// Syncs trip data between local SQLite and Cloud Firestore.
///
/// Sync strategy:
/// - On trip save: write locally first, then push to Firestore
/// - On app start: pull cloud trips, merge with local (last-write-wins)
/// - Unsynced trips are retried on next sync call
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;

  /// Reference to a user's trips collection in Firestore.
  CollectionReference _tripsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('trips');

  /// Delete a trip from Firestore.
  Future<void> deleteTrip(String userId, String firestoreId) async {
    try {
      await _tripsCollection(userId).doc(firestoreId).delete();
      if (kDebugMode) {
        debugPrint('✅ Trip deleted from Firestore: $firestoreId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to delete trip from Firestore: $e');
      }
    }
  }

  /// Push a single trip to Firestore.
  /// Called immediately after saving a trip locally.
  Future<void> pushTrip(String userId, Map<String, dynamic> localTrip) async {
    try {
      final docData = _localTripToFirestore(localTrip);
      final docRef = await _tripsCollection(userId).add(docData);

      // Mark as synced in local DB
      final localId = localTrip['id'] as int;
      await DatabaseService.instance.markTripSynced(localId, docRef.id);

      if (kDebugMode) {
        debugPrint('✅ Trip synced to Firestore: ${docRef.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to sync trip: $e');
      }
      // Trip stays as 'pending' — will retry on next syncAll()
    }
  }

  /// Sync all unsynced local trips to Firestore.
  /// Called on app start and when connectivity is restored.
  Future<void> syncAll(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Push unsynced local trips to cloud
      final unsyncedTrips = await DatabaseService.instance.getUnsyncedTrips(
        userId,
      );
      for (final trip in unsyncedTrips) {
        await pushTrip(userId, trip);
      }

      // 2. Pull cloud trips that don't exist locally
      await _pullCloudTrips(userId);

      if (kDebugMode) {
        debugPrint('✅ Sync complete: pushed ${unsyncedTrips.length} trips');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Sync failed: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull trips from Firestore that don't exist locally.
  Future<void> _pullCloudTrips(String userId) async {
    try {
      final cloudDocs = await _tripsCollection(userId).get();

      // Get all local firestoreIds to know which cloud trips we already have
      final localTrips = await DatabaseService.instance.getTrips(userId);
      final localFirestoreIds = localTrips
          .map((t) => t['firestoreId'] as String?)
          .where((id) => id != null)
          .toSet();

      for (final doc in cloudDocs.docs) {
        if (!localFirestoreIds.contains(doc.id)) {
          // This cloud trip doesn't exist locally — save it
          final cloudData = doc.data() as Map<String, dynamic>;
          await _saveCloudTripLocally(userId, doc.id, cloudData);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Pull from cloud failed: $e');
      }
    }
  }

  /// Save a cloud trip to the local SQLite database.
  Future<void> _saveCloudTripLocally(
    String userId,
    String firestoreId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Decode alerts
      List<String> alerts = [];
      if (data['alerts'] != null) {
        alerts = List<String>.from(data['alerts']);
      }

      // Decode routePath
      List<Map<String, double>> routePath = [];
      if (data['routePath'] != null) {
        routePath = List<Map<String, double>>.from(
          (data['routePath'] as List).map(
            (point) => Map<String, double>.from(point),
          ),
        );
      }

      // Get the date string
      String dateStr;
      if (data['date'] is Timestamp) {
        dateStr = (data['date'] as Timestamp).toDate().toIso8601String();
      } else {
        dateStr = data['date']?.toString() ?? DateTime.now().toIso8601String();
      }

      await DatabaseService.instance.saveTrip(
        userId: userId,
        duration: data['duration'] ?? '0:00',
        distance: data['distance'] ?? '0.0 km',
        status: data['status'] ?? 'Safe',
        alerts: alerts,
        score: data['score'] ?? 100,
        startTime: data['startTime'] ?? '',
        endTime: data['endTime'] ?? '',
        avgSpeed: data['avgSpeed'] ?? '0.0 km/h',
        maxSpeed: data['maxSpeed'] ?? '0.0 km/h',
        routePath: routePath,
        customDate: dateStr,
      );

      // Mark as synced
      final lastId = await DatabaseService.instance.getLastInsertedTripId();
      if (lastId != null) {
        await DatabaseService.instance.markTripSynced(lastId, firestoreId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to save cloud trip locally: $e');
      }
    }
  }

  /// Convert a local trip map to a Firestore-compatible map.
  Map<String, dynamic> _localTripToFirestore(Map<String, dynamic> localTrip) {
    // Parse alerts from JSON string
    List<dynamic> alerts = [];
    if (localTrip['alerts'] != null) {
      try {
        alerts = jsonDecode(localTrip['alerts']);
      } catch (_) {
        alerts = [];
      }
    }

    // Parse routePath from JSON string
    List<dynamic> routePath = [];
    if (localTrip['routePath'] != null) {
      try {
        routePath = jsonDecode(localTrip['routePath']);
      } catch (_) {
        routePath = [];
      }
    }

    return {
      'date': localTrip['date'],
      'duration': localTrip['duration'],
      'distance': localTrip['distance'],
      'status': localTrip['status'],
      'alerts': alerts,
      'score': localTrip['score'] ?? 100,
      'startTime': localTrip['startTime'],
      'endTime': localTrip['endTime'],
      'avgSpeed': localTrip['avgSpeed'],
      'maxSpeed': localTrip['maxSpeed'],
      'routePath': routePath,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
