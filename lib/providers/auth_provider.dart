import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic> _currentUser = {};

  bool _hasSeenOnboarding = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  Map<String, dynamic> get currentUser => _currentUser;

  /// The Firebase UID of the current user (used as userId for trips).
  String? get uid => AuthService.instance.uid;

  final _firestore = FirebaseFirestore.instance;

  static const _staySignedInKey = 'stay_signed_in';
  static String _profileKey(String uid) => 'profile_$uid';

  Future<void> initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;

      // Check if Firebase user is already signed in
      final firebaseUser = AuthService.instance.currentUser;
      if (firebaseUser != null) {
        if (prefs.getBool(_staySignedInKey) == false) {
          // "Keep me signed in" was off last time.
          await AuthService.instance.signOut();
        } else {
          await _loadUserProfile(firebaseUser);
          _isAuthenticated = true;

          // Sync trips from/to cloud
          SyncService.instance.syncAll(firebaseUser.uid);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in AuthProvider.initApp: $e');
      }
      // Consider user not authenticated if loading fails
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  /// Register a new user with Firebase Auth and store profile in Firestore.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String emergencyContact,
  }) async {
    final user = await AuthService.instance.registerWithEmail(email, password);
    if (user == null) throw Exception('Registration failed');

    // The account exists now: a failure below mustn't lose the profile.
    try {
      await AuthService.instance.updateDisplayName(fullName);
    } catch (e) {
      if (kDebugMode) print('Warning: Failed to set display name: $e');
    }

    _currentUser = {
      'id': user.uid,
      'email': email,
      'fullName': fullName,
      'emergencyContact': emergencyContact,
    };
    await _cacheProfile();

    // Store profile data in Firestore. Offline, the write completes when
    // the phone reconnects, so it isn't awaited.
    _firestore
        .collection('users')
        .doc(user.uid)
        .set({
          'fullName': fullName,
          'email': email,
          'emergencyContact': emergencyContact,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((Object e) {
          if (kDebugMode) {
            print('Warning: Failed to save user profile to Firestore: $e');
          }
        });

    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setBool(_staySignedInKey, true);

    // Sync trips from/to cloud
    SyncService.instance.syncAll(user.uid);

    notifyListeners();
  }

  /// Sign in an existing user with Firebase Auth.
  ///
  /// With [staySignedIn] false, the next app launch signs out again.
  Future<void> signIn({
    required String email,
    required String password,
    bool staySignedIn = true,
  }) async {
    final user = await AuthService.instance.signInWithEmail(email, password);
    if (user == null) throw Exception('Sign in failed');

    await _loadUserProfile(user);
    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setBool(_staySignedInKey, staySignedIn);

    // Sync trips from/to cloud
    SyncService.instance.syncAll(user.uid);

    notifyListeners();
  }

  /// Keep the old login method for compatibility with HomeScreen's onLogin callback.
  Future<void> login(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user['email']);

    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');

    _isAuthenticated = false;
    _currentUser = {};
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Updates the profile. It applies at once (the SOS uses the new number
  /// straight away) and reaches Firestore when there's a connection.
  Future<void> updateProfile({
    required String fullName,
    required String emergencyContact,
  }) async {
    final firebaseUser = AuthService.instance.currentUser;
    if (firebaseUser == null) return;

    _currentUser = {
      ..._currentUser,
      'fullName': fullName,
      'emergencyContact': emergencyContact,
    };
    notifyListeners();
    await _cacheProfile();

    // merge: also creates the document if signup couldn't write it.
    _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set({
          'fullName': fullName,
          'emergencyContact': emergencyContact,
          'email': firebaseUser.email ?? '',
        }, SetOptions(merge: true))
        .catchError((Object e) {
          if (kDebugMode) {
            print('Warning: Failed to update user profile in Firestore: $e');
          }
        });

    try {
      await AuthService.instance.updateDisplayName(fullName);
    } catch (e) {
      if (kDebugMode) print('Warning: Failed to update display name: $e');
    }
  }

  /// Changes the password after confirming [currentPassword].
  /// Throws [FirebaseAuthException] (e.g. `wrong-password`) on failure.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => AuthService.instance.changePassword(currentPassword, newPassword);

  /// Keeps the profile on the phone, so the emergency contact is known even
  /// when Firestore can't be reached.
  Future<void> _cacheProfile() async {
    final id = _currentUser['id'] as String?;
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _profileKey(id),
        jsonEncode({
          'fullName': _currentUser['fullName'] ?? '',
          'emergencyContact': _currentUser['emergencyContact'] ?? '',
        }),
      );
    } catch (e) {
      if (kDebugMode) print('Warning: Failed to cache profile: $e');
    }
  }

  Future<Map<String, dynamic>?> _cachedProfile(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey(uid));
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Load user profile from Firestore into the currentUser map.
  ///
  /// Falls back to Firestore's offline copy, then to the copy kept on the
  /// phone, so a slow network never drops the emergency contact.
  Future<void> _loadUserProfile(User firebaseUser) async {
    final users = _firestore.collection('users');
    Map<String, dynamic>? data;
    try {
      final doc = await users
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      data = doc.exists ? doc.data() : <String, dynamic>{};
    } catch (e) {
      if (kDebugMode) print('_loadUserProfile: Firestore error $e');
      try {
        final doc = await users
            .doc(firebaseUser.uid)
            .get(const GetOptions(source: Source.cache));
        if (doc.exists) data = doc.data();
      } catch (_) {
        // Not in Firestore's cache either.
      }
    }

    final cached = await _cachedProfile(firebaseUser.uid);
    final fromServer = data ?? const <String, dynamic>{};
    String pick(String key, String fallback) {
      final value = (fromServer[key] ?? cached?[key])?.toString();
      return (value == null || value.isEmpty) ? fallback : value;
    }

    _currentUser = {
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'fullName': pick('fullName', firebaseUser.displayName ?? ''),
      'emergencyContact': pick('emergencyContact', ''),
    };
    await _cacheProfile();
  }
}
