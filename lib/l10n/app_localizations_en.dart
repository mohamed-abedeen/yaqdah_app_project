// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yaqdah';

  @override
  String get navHome => 'Home';

  @override
  String get navReports => 'Reports';

  @override
  String get navRest => 'Rest';

  @override
  String get navAccount => 'Account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get sectionEmergency => 'Emergency Settings';

  @override
  String get autoEmergencyTitle => 'Auto Emergency Message';

  @override
  String get autoEmergencySubtitle =>
      'When severe drowsiness is detected with no response';

  @override
  String get sectionAI => 'Artificial Intelligence';

  @override
  String get aiAssistantTitle => 'AI Assistant';

  @override
  String get aiAssistantSubtitle => 'Automatic voice tips on danger';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get notificationsSubtitle => 'Drowsiness alerts and warnings';

  @override
  String get sound => 'Sound';

  @override
  String get vibration => 'Vibration';

  @override
  String get sectionAppSettings => 'App Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Change app appearance';

  @override
  String get testLab => 'Test Lab';

  @override
  String get testLabSubtitle => 'View live model data';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get logout => 'Logout';

  @override
  String get driverStatus => 'Driver Status';

  @override
  String get drowsinessLevel => 'Drowsiness Level';

  @override
  String get statusReady => 'Ready for Trip';

  @override
  String get statusAsleep => 'Danger - Stop Now!';

  @override
  String get statusDistracted => 'Distracted - Focus!';

  @override
  String get statusDrowsy => 'Drowsy';

  @override
  String get statusAlert => 'Alert & Awake';

  @override
  String get statusNoFace => 'No Face Detected';

  @override
  String get btnEmergency => 'Emergency';

  @override
  String get btnStart => 'Start';

  @override
  String get btnStop => 'Stop';

  @override
  String get btnCamera => 'Camera';

  @override
  String get statDuration => 'Duration';

  @override
  String get statDistance => 'Distance';

  @override
  String get statSpeed => 'Speed';

  @override
  String get statHeading => 'Heading';

  @override
  String get kmUnit => 'km';

  @override
  String get kmhUnit => 'km/h';

  @override
  String get searchPlaces => 'Search places...';

  @override
  String get restScreenTitle => 'Nearby Rest Places';

  @override
  String get catAll => 'All';

  @override
  String get catHotels => 'Hotels';

  @override
  String get catCafes => 'Cafes';

  @override
  String get catMosques => 'Mosques';

  @override
  String get restEmptyState => 'No nearby places found';

  @override
  String get restRetry => 'Try Again';

  @override
  String get distanceKm => 'km';

  @override
  String get reportsTitle => 'Reports & Statistics';

  @override
  String get reportsSubtitle => 'Comprehensive driving activity analysis';

  @override
  String get reportsGeneralStats => 'General Statistics';

  @override
  String get reportsThisWeek => 'This Week';

  @override
  String get reportsAllTime => 'All Time';

  @override
  String get reportsTrips => 'Trips';

  @override
  String get reportsAlerts => 'Alerts';

  @override
  String get reportsTripStatus => 'Trip Status Distribution';

  @override
  String get reportsSafe => 'Safe';

  @override
  String get reportsAlert => 'Alerts';

  @override
  String get reportsTime => 'Time';

  @override
  String get reportsDrowsy => 'Drowsy';

  @override
  String get reportsEmergency => 'Emergency';

  @override
  String get filterAll => 'All';

  @override
  String get filterWeek => 'Week';

  @override
  String get filterMonth => 'Month';

  @override
  String get tripSafe => 'Safe';

  @override
  String get tripAlerted => 'Alert';

  @override
  String get tripDuration => 'Duration';

  @override
  String get tripDistance => 'Distance';

  @override
  String get tripAlertCount => 'Alerts';

  @override
  String get reportsEmptyTitle => 'No Trips Yet';

  @override
  String get reportsEmptySubtitle =>
      'Start a trip to see your driving stats here';

  @override
  String get loginTitle => 'Yaqdah';

  @override
  String get loginSubtitle => 'Driver Drowsiness Detection System';

  @override
  String get loginHeading => 'Sign In';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginSignup => 'Create an account';

  @override
  String get loginErrEmailRequired => 'Email is required';

  @override
  String get loginErrEmailInvalid => 'Email is invalid';

  @override
  String get loginErrPassRequired => 'Password is required';

  @override
  String get loginErrPassShort => 'Password must be at least 6 characters';

  @override
  String get loginErrNotFound => 'No account found with this email';

  @override
  String get loginErrWrongPass => 'Incorrect email or password';

  @override
  String get loginErrTooMany => 'Too many attempts. Try again later';

  @override
  String get loginErrGeneric => 'An error occurred';

  @override
  String get loginErrUnexpected => 'Unexpected error';

  @override
  String get signupHeading => 'Create Account';

  @override
  String get signupTitle => 'Register';

  @override
  String get signupFullName => 'Full Name';

  @override
  String get signupEmail => 'Email';

  @override
  String get signupPassword => 'Password';

  @override
  String get signupConfirmPassword => 'Confirm Password';

  @override
  String get signupEmergencyContact => 'Emergency Contact Number';

  @override
  String get signupButton => 'Create Account';

  @override
  String get signupHaveAccount => 'Already have an account? ';

  @override
  String get signupLogin => 'Sign In';

  @override
  String get signupErrNameRequired => 'Full name is required';

  @override
  String get signupErrEmailRequired => 'Email is required';

  @override
  String get signupErrEmailInvalid => 'Email is invalid';

  @override
  String get signupErrPassRequired => 'Password is required';

  @override
  String get signupErrPassShort => 'Password must be at least 6 characters';

  @override
  String get signupErrConfirmRequired => 'Please confirm your password';

  @override
  String get signupErrPassMismatch => 'Passwords do not match';

  @override
  String get signupErrEmergencyRequired => 'Emergency number is required';

  @override
  String get signupErrEmergencyNumbers =>
      'Emergency number must contain only digits';

  @override
  String get signupErrEmailInUse => 'Email is already in use';

  @override
  String get signupErrWeakPassword => 'Password is too weak';

  @override
  String get permCameraTitle => 'Camera Access Required';

  @override
  String get permCameraBody =>
      'Yaqdah needs your camera to monitor eye movements and detect drowsiness while driving.';

  @override
  String get permLocationTitle => 'Location Access Required';

  @override
  String get permLocationBody =>
      'Yaqdah needs your location for navigation and to send your GPS coordinates in an emergency.';

  @override
  String get permGrant => 'Grant Access';

  @override
  String get permDeny => 'Not Now';

  @override
  String get offlineBanner => 'No internet connection';
}
