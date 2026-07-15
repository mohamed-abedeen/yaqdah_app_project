import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication for the Yaqdah app.
///
/// Replaces the old local-only password auth in DatabaseService.
/// The Firebase UID is used as the `userId` for trip ownership.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// The Firebase UID of the current user, or null.
  String? get uid => _auth.currentUser?.uid;

  /// Stream of auth state changes (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password.
  /// Returns the Firebase [User] on success.
  /// Throws [FirebaseAuthException] on failure.
  Future<User?> registerWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign in an existing user with email and password.
  /// Returns the Firebase [User] on success.
  /// Throws [FirebaseAuthException] on failure.
  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send a password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update the display name of the current user.
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await _auth.currentUser?.reload();
  }
}
