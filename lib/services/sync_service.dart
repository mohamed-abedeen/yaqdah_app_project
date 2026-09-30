import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

/// Syncs trip data between local SQLite and Cloud Firestore.
///
/// Sync strategy:
/// - On trip save: write locally first, then push to Firestore
/// - On app start: pull cloud trips this phone doesn't have yet
/// - Unsynced trips are retried on next sync call
///
/// A trip's Firestore id is chosen and saved locally before the upload, and
/// uploads use `set`, so retrying never makes a second copy. Deleted trips
/// are remembered so a pull doesn't bring them back.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _firestore = FirebaseFirestore.instance;
  bool _isSyncing = false;

  /// Local ids of trips being uploaded right now.
  final Set<int> _pushing = {};

  /// Reference to a user's trips collection in Firestore.
  CollectionReference _tripsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('trips');

  /// Deletes a trip on this phone and, when it was uploaded, in Firestore.
  ///
  /// The local delete happens first. Offline, Firestore finishes the cloud
  /// delete later, so it isn't awaited.
  Future<void> deleteTrip(String userId, int localId) async {
    final trip = await DatabaseService.instance.getTrip(localId);
    final firestoreId = trip?['firestoreId'] as String?;
    await DatabaseService.instance.deleteTrip(localId, userId);
    if (firestoreId == null || firestoreId.isEmpty) return;
    _tripsCollection(userId)
        .doc(firestoreId)
        .delete()
        .then(
          (_) {
            if (kDebugMode) {
              debugPrint('✅ Trip deleted from Firestore: $firestoreId');
            }
          },
          onError: (Object e) {
            if (kDebugMode) {
              debugPrint('⚠️ Failed to delete trip from Firestore: $e');
            }
          },
        );
  }

  /// Push a single trip to Firestore.
  /// Called immediately after saving a trip locally.
  Future<void> pushTrip(String userId, int localId) async {
    if (!_pushing.add(localId)) return;
    try {
      // Read it fresh: it may have been deleted or synced meanwhile.
      final localTrip = await DatabaseService.instance.getTrip(localId);
      if (localTrip == null || localTrip['syncStatus'] == 'synced') return;

      final saved = localTrip['firestoreId'] as String?;
      final docId = (saved == null || saved.isEmpty)
          ? _tripsCollection(userId).doc().id
          : saved;
      if (await DatabaseService.instance.isTripDeleted(userId, docId)) return;
      await DatabaseService.instance.setTripFirestoreId(localId, docId);

      await _tripsCollection(
        userId,
      ).doc(docId).set(_localTripToFirestore(localTrip));
      await DatabaseService.instance.markTripSynced(localId, docId);

      if (kDebugMode) {
        debugPrint('✅ Trip synced to Firestore: $docId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to sync trip: $e');
      }
      // Trip stays as 'pending' — will retry on next syncAll()
    } finally {
      _pushing.remove(localId);
    }
  }

  /// Sync all unsynced local trips to Firestore.
  /// Called on app start and when connectivity is restored.
  Future<void> syncAll(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Push unsynced local trips to cloud. Not awaited one by one:
      // offline, a write only completes once the phone is back online.
      final unsyncedTrips = await DatabaseService.instance.getUnsyncedTrips(
        userId,
      );
      for (final trip in unsyncedTrips) {
        pushTrip(userId, trip['id'] as int);
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

      // Cloud trips this phone already has, or deleted.
      final known = await DatabaseService.instance.getKnownFirestoreIds(userId);

      var imported = 0;
      for (final doc in cloudDocs.docs) {
        if (known.contains(doc.id)) continue;
        final cloudData = doc.data() as Map<String, dynamic>;
        if (await _saveCloudTripLocally(userId, doc.id, cloudData)) {
          imported++;
        }
      }
      // One reload for the whole import.
      if (imported > 0) DatabaseService.instance.notifyTripsChanged();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Pull from cloud failed: $e');
      }
    }
  }

  /// Save a cloud trip to the local SQLite database.
  Future<bool> _saveCloudTripLocally(
    String userId,
    String firestoreId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Decode alerts
      List<String> alerts = [];
      if (data['alerts'] is List) {
        alerts = [for (final a in data['alerts'] as List) a.toString()];
      }

      // Decode routePath
      final routePath = <Map<String, double>>[];
      if (data['routePath'] is List) {
        for (final point in data['routePath'] as List) {
          if (point is! Map) continue;
          final lat = point['lat'];
          final lng = point['lng'];
          if (lat is num && lng is num) {
            routePath.add({'lat': lat.toDouble(), 'lng': lng.toDouble()});
          }
        }
      }

      // Get the date string
      String dateStr;
      if (data['date'] is Timestamp) {
        dateStr = (data['date'] as Timestamp).toDate().toIso8601String();
      } else {
        dateStr = data['date']?.toString() ?? DateTime.now().toIso8601String();
      }

      // Trips uploaded by older versions stored speeds in m/s.
      String avgSpeed = data['avgSpeed']?.toString() ?? '0.0 km/h';
      String maxSpeed = data['maxSpeed']?.toString() ?? '0.0 km/h';
      if (data['speedUnit'] != 'kmh' &&
          DatabaseService.speedsLookLikeMetersPerSecond({
            'avgSpeed': avgSpeed,
            'maxSpeed': maxSpeed,
            'distance': data['distance'],
            'duration': data['duration'],
          })) {
        avgSpeed = DatabaseService.kmhLabelFromMetersPerSecond(avgSpeed);
        maxSpeed = DatabaseService.kmhLabelFromMetersPerSecond(maxSpeed);
      }

      await DatabaseService.instance.saveTrip(
        userId: userId,
        duration: data['duration']?.toString() ?? '0:00:00',
        distance: data['distance']?.toString() ?? '0.0 km',
        status: data['status']?.toString() ?? 'Safe',
        alerts: alerts,
        score: (data['score'] as num?)?.toInt() ?? 100,
        startTime: data['startTime']?.toString() ?? '',
        endTime: data['endTime']?.toString() ?? '',
        avgSpeed: avgSpeed,
        maxSpeed: maxSpeed,
        routePath: routePath,
        customDate: dateStr,
        firestoreId: firestoreId,
        notify: false,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to save cloud trip locally: $e');
      }
      return false;
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
      'speedUnit': 'kmh',
      'routePath': routePath,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
