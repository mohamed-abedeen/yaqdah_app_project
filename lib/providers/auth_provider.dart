import 'dart:async';
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

  Future<void> initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;

      // Check if Firebase user is already signed in
      final firebaseUser = AuthService.instance.currentUser;
      if (firebaseUser != null) {
        await _loadUserProfile(firebaseUser);
        _isAuthenticated = true;

        // Sync trips from/to cloud
        SyncService.instance.syncAll(firebaseUser.uid);
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

    // Update display name
    await AuthService.instance.updateDisplayName(fullName);

    // Store profile data in Firestore
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'email': email,
        'emergencyContact': emergencyContact,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Warning: Failed to save user profile to Firestore: $e');
    }

    await _loadUserProfile(user);
    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);

    // Sync trips from/to cloud
    SyncService.instance.syncAll(user.uid);

    notifyListeners();
  }

  /// Sign in an existing user with Firebase Auth.
  Future<void> signIn({required String email, required String password}) async {
    final user = await AuthService.instance.signInWithEmail(email, password);
    if (user == null) throw Exception('Sign in failed');

    await _loadUserProfile(user);
    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);

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

  /// Update profile data in Firestore.
  Future<void> updateProfile({
    required String fullName,
    required String emergencyContact,
  }) async {
    final firebaseUser = AuthService.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'fullName': fullName,
        'emergencyContact': emergencyContact,
      });
    } catch (e) {
      if (kDebugMode) print('Warning: Failed to update user profile in Firestore: $e');
    }

    await AuthService.instance.updateDisplayName(fullName);

    _currentUser['fullName'] = fullName;
    _currentUser['emergencyContact'] = emergencyContact;
    notifyListeners();
  }

  /// Load user profile from Firestore into the currentUser map.
  Future<void> _loadUserProfile(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'fullName': data['fullName'] ?? firebaseUser.displayName ?? '',
          'emergencyContact': data['emergencyContact'] ?? '',
        };
      } else {
        _currentUser = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'fullName': firebaseUser.displayName ?? '',
          'emergencyContact': '',
        };
      }
    } on TimeoutException catch (_) {
      // Firestore unreachable — fall back to Firebase Auth data
      _currentUser = {
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'fullName': firebaseUser.displayName ?? '',
        'emergencyContact': '',
      };
      if (kDebugMode) print('_loadUserProfile: Firestore timeout, using Auth data');
    } catch (e) {
      // Firestore permission denied or other error — fall back to Auth data
      _currentUser = {
        'id': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'fullName': firebaseUser.displayName ?? '',
        'emergencyContact': '',
      };
      if (kDebugMode) print('_loadUserProfile: Firestore error $e, using Auth data');
    }
  }
}
