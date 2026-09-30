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
  String get navDrive => 'Drive';

  @override
  String get navReports => 'Reports';

  @override
  String get navRest => 'Rest';

  @override
  String get navAccount => 'Account';

  @override
  String get offlineBanner => 'No internet connection';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingWelcomeTitle => 'Stay awake.\nArrive safe.';

  @override
  String get onboardingWelcomeBody =>
      'Yaqdah watches for signs of drowsiness while you drive and warns you before it becomes dangerous.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPermsTitle => 'Three permissions keep you safe';

  @override
  String get onboardingPermsSubtitle =>
      'You can change these any time in your phone\'s settings.';

  @override
  String get permCameraName => 'Camera';

  @override
  String get permCameraDesc =>
      'Watches your eyes and head position. Face detection runs on your phone.';

  @override
  String get permLocationName => 'Location';

  @override
  String get permLocationDesc =>
      'Finds nearby rest stops and shares where you are in an emergency.';

  @override
  String get permMicName => 'Microphone';

  @override
  String get permMicDesc =>
      'Talk to the voice assistant without taking your hands off the wheel.';

  @override
  String get onboardingAllowAccess => 'Allow access';

  @override
  String get loginHeading => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to start monitoring your drive.';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginRememberMe => 'Keep me signed in';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginNoAccount => 'New to Yaqdah? ';

  @override
  String get loginSignup => 'Create an account';

  @override
  String get loginErrEmailRequired => 'Email is required';

  @override
  String get loginErrEmailInvalid => 'Email is invalid';

  @override
  String get loginErrPassRequired => 'Password is required';

  @override
  String get loginErrPassShort => 'Use at least 6 characters';

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
  String get loginErrResetNeedsEmail =>
      'Enter your email above to reset your password';

  @override
  String loginResetSent(String email) {
    return 'We sent a reset link to $email';
  }

  @override
  String get signupTitle => 'Create your account';

  @override
  String get signupSubtitle => 'Takes about a minute.';

  @override
  String get signupFullName => 'Full name';

  @override
  String get signupEmail => 'Email';

  @override
  String get signupPassword => 'Password';

  @override
  String get signupConfirmPassword => 'Confirm password';

  @override
  String get signupButton => 'Create account';

  @override
  String get signupHaveAccount => 'Already have an account? ';

  @override
  String get signupLogin => 'Sign in';

  @override
  String get signupErrNameRequired => 'Full name is required';

  @override
  String get signupErrEmailRequired => 'Email is required';

  @override
  String get signupErrEmailInvalid => 'Email is invalid';

  @override
  String get signupErrPassRequired => 'Password is required';

  @override
  String get signupErrPassShort => 'Use at least 6 characters';

  @override
  String get signupErrConfirmRequired => 'Please confirm your password';

  @override
  String get signupErrPassMismatch => 'Passwords do not match';

  @override
  String get signupErrEmergencyRequired => 'Emergency number is required';

  @override
  String get phoneInvalid => 'Enter a valid number, like 91 234 5678';

  @override
  String get signupErrEmailInUse => 'Email is already in use';

  @override
  String get signupErrWeakPassword => 'Password is too weak';

  @override
  String get emergencyContactTitle => 'Emergency contact';

  @override
  String get emergencyContactHelp =>
      'If you don\'t respond to a danger alert, we text your location to this number.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get readyTitle => 'Ready to drive';

  @override
  String get almostReadyTitle => 'Almost ready';

  @override
  String get checksPassed => 'All checks passed';

  @override
  String get checksAttention => 'Some checks need attention';

  @override
  String get checksRunning => 'Running checks…';

  @override
  String get checkFace => 'Face visible';

  @override
  String get checkFaceFix => 'Face the camera';

  @override
  String get checkPending => 'Checking…';

  @override
  String get cameraFront => 'Front camera';

  @override
  String get cameraBack => 'Back camera';

  @override
  String get cameraExternal => 'External camera';

  @override
  String get cameraGeneric => 'Camera';

  @override
  String get checkSwitch => 'Switch';

  @override
  String get checkNoCamera => 'No camera';

  @override
  String get checkGps => 'GPS signal';

  @override
  String get gpsStrong => 'Strong';

  @override
  String get gpsWeak => 'Weak';

  @override
  String get gpsSearching => 'Searching…';

  @override
  String get gpsOff => 'Off';

  @override
  String get whereTo => 'Where to?';

  @override
  String get whereToOptional => '(optional)';

  @override
  String get clearDestination => 'Clear destination';

  @override
  String lastTripLine(String when, String distance, String alerts) {
    return 'Last trip $when · $distance km · $alerts';
  }

  @override
  String get lastTripToday => 'today';

  @override
  String get lastTripYesterday => 'yesterday';

  @override
  String lastTripOn(String day) {
    return 'on $day';
  }

  @override
  String alertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alerts',
      one: '1 alert',
      zero: 'no alerts',
    );
    return '$_temp0';
  }

  @override
  String get startTrip => 'Start trip';

  @override
  String get voiceAssistant => 'Voice assistant';

  @override
  String get searchPlaces => 'Search for a place';

  @override
  String get searchNoResults => 'No places found';

  @override
  String get droppedPin => 'Dropped pin';

  @override
  String get findingRoute => 'Finding route…';

  @override
  String get routeUnavailable => 'No route found';

  @override
  String etaLine(int minutes, String time) {
    return '$minutes min · arrive $time';
  }

  @override
  String get recenterMap => 'Recenter map';

  @override
  String get driverStatus => 'Driver status';

  @override
  String get statusAwake => 'Awake';

  @override
  String get statusDrowsy => 'Drowsy';

  @override
  String get statusDistracted => 'Distracted';

  @override
  String get statusNoFace => 'No face detected';

  @override
  String get statusDanger => 'Danger';

  @override
  String get drowsinessCaption => 'drowsiness';

  @override
  String get statTime => 'Time';

  @override
  String get statDistance => 'Distance';

  @override
  String get statSpeed => 'Speed';

  @override
  String get kmUnit => 'km';

  @override
  String get kmhUnit => 'km/h';

  @override
  String get holdForSos => 'Hold for SOS';

  @override
  String get endTrip => 'End trip';

  @override
  String get standbyTitle => 'Standby mode';

  @override
  String get standbyHint => 'Tap anywhere to wake';

  @override
  String sosSentTo(String contact) {
    return 'SOS sent to $contact';
  }

  @override
  String get stopAlarm => 'Stop alarm';

  @override
  String get sosSendFailed => 'Couldn\'t send the SOS text';

  @override
  String get sosSending => 'Sending SOS…';

  @override
  String get sosSmsBody => 'SOS from Yaqdah: the driver may be in danger.';

  @override
  String get sosSmsLocation => 'Location';

  @override
  String get voiceEndingTrip => 'Ending the trip.';

  @override
  String get voiceSendingSos => 'Sending an emergency alert.';

  @override
  String get voiceUnavailable => 'Sorry, I can\'t answer right now.';

  @override
  String get interventionDistracted => 'Eyes on the road!';

  @override
  String get interventionDrowsy => 'You look tired. Take a break soon.';

  @override
  String get drowsyAlertTitle => 'You\'re getting drowsy';

  @override
  String get drowsyAlertBody =>
      'Your eyes are closing more often. A 15-minute break makes a real difference.';

  @override
  String get nearestRestStop => 'Nearest rest stop';

  @override
  String get findingRestStop => 'Finding a rest stop…';

  @override
  String get noRestStopNearby =>
      'No rest stops found nearby. Pull over somewhere safe.';

  @override
  String get takeMeThere => 'Take me there';

  @override
  String get keepDriving => 'I\'m fine, keep driving';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get dangerAlertTitle => 'Pull over now';

  @override
  String get dangerAlertBody =>
      'Your eyes have been closed. If you don\'t respond, we\'ll text your location to your emergency contact.';

  @override
  String sosCountdown(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Sending SOS in $seconds seconds',
      one: 'Sending SOS in 1 second',
    );
    return '$_temp0';
  }

  @override
  String sosTo(String contact) {
    return 'to $contact';
  }

  @override
  String get sosAutoOff => 'Automatic SOS text is off';

  @override
  String get sosNoContact => 'No emergency contact set';

  @override
  String get sosSentTitle => 'SOS sent';

  @override
  String get imAwake => 'I\'m awake';

  @override
  String get sendSosNow => 'Send SOS now';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get filterWeek => 'Week';

  @override
  String get filterMonth => 'Month';

  @override
  String get filterAll => 'All';

  @override
  String get driverLevel => 'Driver level';

  @override
  String levelN(int level) {
    return 'Level $level';
  }

  @override
  String safeKm(String km) {
    return '$km safe km';
  }

  @override
  String kmToNextLevel(String km, int level) {
    return '$km km to Level $level';
  }

  @override
  String get badgeFirstSafeTrip => 'First Safe Trip';

  @override
  String get badgePerfect10 => 'Perfect 10';

  @override
  String get badgeNightOwl => 'Night Owl';

  @override
  String get badgeMarathoner => 'Marathoner';

  @override
  String get reportsTrips => 'Trips';

  @override
  String get reportsDistance => 'Distance';

  @override
  String get reportsAlerts => 'Alerts';

  @override
  String get legendSafeDays => 'Safe days';

  @override
  String get legendAlertDays => 'Days with alerts';

  @override
  String get recentTrips => 'Recent trips';

  @override
  String get reportsNoTripsInRange => 'No trips in this period';

  @override
  String tripRowSubtitle(String duration, String distance, String alerts) {
    return '$duration · $distance km · $alerts';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get reportsEmptyTitle => 'No trips yet';

  @override
  String get reportsEmptySubtitle =>
      'Start a trip to see your driving stats here.';

  @override
  String get tripDetailsTitle => 'Trip details';

  @override
  String get shareReport => 'Share report';

  @override
  String get tripSafe => 'Safe';

  @override
  String get safetyScore => 'Safety score';

  @override
  String get tripDuration => 'Duration';

  @override
  String get tripDistance => 'Distance';

  @override
  String get avgSpeed => 'Avg speed';

  @override
  String get topSpeed => 'Top speed';

  @override
  String get timeline => 'Timeline';

  @override
  String get tlTripStarted => 'Trip started';

  @override
  String get tlTripEnded => 'Trip ended';

  @override
  String get tlDrowsy => 'Drowsiness detected';

  @override
  String get tlDistracted => 'Distraction detected';

  @override
  String get tlDanger => 'Eyes closed: danger alert';

  @override
  String get tlSos => 'SOS sent';

  @override
  String get tlTookBreak => 'you took a break';

  @override
  String get tlKeptDriving => 'you kept driving';

  @override
  String get tlConfirmedAwake => 'you confirmed you were awake';

  @override
  String get deleteTrip => 'Delete trip';

  @override
  String get deleteTripConfirmTitle => 'Delete this trip?';

  @override
  String get deleteTripConfirmBody =>
      'This removes the trip and its report. You can\'t undo this.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noRouteRecorded => 'No route recorded';

  @override
  String get restTitle => 'Take a break';

  @override
  String restSubtitle(int km) {
    return 'Rest stops within $km km of you';
  }

  @override
  String get catAll => 'All';

  @override
  String get catCafes => 'Cafés';

  @override
  String get catMosques => 'Mosques';

  @override
  String get catHotels => 'Hotels';

  @override
  String get placeCafe => 'Café';

  @override
  String get placeMosque => 'Mosque';

  @override
  String get placeHotel => 'Hotel';

  @override
  String get placeFuel => 'Fuel station';

  @override
  String get placeRestArea => 'Rest area';

  @override
  String get placeOther => 'Place';

  @override
  String placeRowSubtitle(String type, String distance, int minutes) {
    return '$type · $distance km · $minutes min';
  }

  @override
  String get go => 'Go';

  @override
  String get restEmptyState => 'No rest stops found nearby';

  @override
  String get restRetry => 'Try again';

  @override
  String get restWaitingLocation => 'Waiting for your location…';

  @override
  String get restLocationOff => 'Turn on location to see rest stops near you.';

  @override
  String get restLoadFailed =>
      'Couldn\'t load places. Check your connection and try again.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get accountTitle => 'Account';

  @override
  String get userFallbackName => 'Driver';

  @override
  String get edit => 'Edit';

  @override
  String get sectionSafety => 'Safety';

  @override
  String get sectionAlerts => 'Alerts';

  @override
  String get sectionApp => 'App';

  @override
  String get autoSosTitle => 'Automatic SOS text';

  @override
  String get autoSosSubtitle => 'If you don\'t respond to a danger alert';

  @override
  String get notSet => 'Not set';

  @override
  String get voiceAssistantSubtitle => 'Spoken tips when you\'re at risk';

  @override
  String get alarmSound => 'Alarm sound';

  @override
  String get vibration => 'Vibration';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get testLab => 'Test lab';

  @override
  String get testLabValue => 'Live model data';

  @override
  String get signOut => 'Sign out';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileSubtitle => 'Update your details';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get deleteAllData => 'Delete all trip data';

  @override
  String get deleteAllDataSubtitle => 'Removes every trip saved on this phone';

  @override
  String get deleteDataConfirmTitle => 'Delete all trip data?';

  @override
  String get deleteDataConfirmBody =>
      'This deletes every trip saved on this phone. You can\'t undo this.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get allDataDeleted => 'All trip data deleted';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get currentPasswordWrong => 'Current password is incorrect';

  @override
  String get smsPermissionNeeded =>
      'Allow SMS so Yaqdah can text your emergency contact';
}
