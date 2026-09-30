import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';

/// A sign-in error in the app language, instead of Firebase's English text.
String authErrorText(FirebaseAuthException e, AppLocalizations l10n) =>
    switch (e.code) {
      'user-not-found' => l10n.loginErrNotFound,
      'wrong-password' || 'invalid-credential' => l10n.loginErrWrongPass,
      'too-many-requests' => l10n.loginErrTooMany,
      'network-request-failed' => l10n.offlineBanner,
      'invalid-email' => l10n.loginErrEmailInvalid,
      'email-already-in-use' => l10n.signupErrEmailInUse,
      'weak-password' => l10n.signupErrWeakPassword,
      _ => l10n.loginErrGeneric,
    };
