import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Yaqdah'**
  String get appTitle;

  /// Bottom nav label - Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav label - Reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// Bottom nav label - Rest
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get navRest;

  /// Bottom nav label - Account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Edit profile link text
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @sectionEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Settings'**
  String get sectionEmergency;

  /// No description provided for @autoEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Emergency Message'**
  String get autoEmergencyTitle;

  /// No description provided for @autoEmergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When severe drowsiness is detected with no response'**
  String get autoEmergencySubtitle;

  /// No description provided for @sectionAI.
  ///
  /// In en, this message translates to:
  /// **'Artificial Intelligence'**
  String get sectionAI;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic voice tips on danger'**
  String get aiAssistantSubtitle;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drowsiness alerts and warnings'**
  String get notificationsSubtitle;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @sectionAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get sectionAppSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change app appearance'**
  String get darkModeSubtitle;

  /// No description provided for @testLab.
  ///
  /// In en, this message translates to:
  /// **'Test Lab'**
  String get testLab;

  /// No description provided for @testLabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View live model data'**
  String get testLabSubtitle;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @driverStatus.
  ///
  /// In en, this message translates to:
  /// **'Driver Status'**
  String get driverStatus;

  /// No description provided for @drowsinessLevel.
  ///
  /// In en, this message translates to:
  /// **'Drowsiness Level'**
  String get drowsinessLevel;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for Trip'**
  String get statusReady;

  /// No description provided for @statusAsleep.
  ///
  /// In en, this message translates to:
  /// **'Danger - Stop Now!'**
  String get statusAsleep;

  /// No description provided for @statusDistracted.
  ///
  /// In en, this message translates to:
  /// **'Distracted - Focus!'**
  String get statusDistracted;

  /// No description provided for @statusDrowsy.
  ///
  /// In en, this message translates to:
  /// **'Drowsy'**
  String get statusDrowsy;

  /// No description provided for @statusAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert & Awake'**
  String get statusAlert;

  /// No description provided for @statusNoFace.
  ///
  /// In en, this message translates to:
  /// **'No Face Detected'**
  String get statusNoFace;

  /// No description provided for @btnEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get btnEmergency;

  /// No description provided for @btnStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get btnStart;

  /// No description provided for @btnStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get btnStop;

  /// No description provided for @btnCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get btnCamera;

  /// No description provided for @statDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get statDuration;

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statDistance;

  /// No description provided for @statSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get statSpeed;

  /// No description provided for @statHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get statHeading;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @kmhUnit.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get kmhUnit;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search places...'**
  String get searchPlaces;

  /// No description provided for @restScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Rest Places'**
  String get restScreenTitle;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get catHotels;

  /// No description provided for @catCafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get catCafes;

  /// No description provided for @catMosques.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get catMosques;

  /// No description provided for @restEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No nearby places found'**
  String get restEmptyState;

  /// No description provided for @restRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get restRetry;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get distanceKm;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Statistics'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive driving activity analysis'**
  String get reportsSubtitle;

  /// No description provided for @reportsGeneralStats.
  ///
  /// In en, this message translates to:
  /// **'General Statistics'**
  String get reportsGeneralStats;

  /// No description provided for @reportsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get reportsThisWeek;

  /// No description provided for @reportsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get reportsAllTime;

  /// No description provided for @reportsTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get reportsTrips;

  /// No description provided for @reportsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get reportsAlerts;

  /// No description provided for @reportsTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Trip Status Distribution'**
  String get reportsTripStatus;

  /// No description provided for @reportsSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get reportsSafe;

  /// No description provided for @reportsAlert.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get reportsAlert;

  /// No description provided for @reportsTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reportsTime;

  /// No description provided for @reportsDrowsy.
  ///
  /// In en, this message translates to:
  /// **'Drowsy'**
  String get reportsDrowsy;

  /// No description provided for @reportsEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get reportsEmergency;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get filterWeek;

  /// No description provided for @filterMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get filterMonth;

  /// No description provided for @tripSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get tripSafe;

  /// No description provided for @tripAlerted.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get tripAlerted;

  /// No description provided for @tripDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tripDuration;

  /// No description provided for @tripDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get tripDistance;

  /// No description provided for @tripAlertCount.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tripAlertCount;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Trips Yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a trip to see your driving stats here'**
  String get reportsEmptySubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaqdah'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Drowsiness Detection System'**
  String get loginSubtitle;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginHeading;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginSignup.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginSignup;

  /// No description provided for @loginErrEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginErrEmailRequired;

  /// No description provided for @loginErrEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email is invalid'**
  String get loginErrEmailInvalid;

  /// No description provided for @loginErrPassRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginErrPassRequired;

  /// No description provided for @loginErrPassShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginErrPassShort;

  /// No description provided for @loginErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email'**
  String get loginErrNotFound;

  /// No description provided for @loginErrWrongPass.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get loginErrWrongPass;

  /// No description provided for @loginErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later'**
  String get loginErrTooMany;

  /// No description provided for @loginErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get loginErrGeneric;

  /// No description provided for @loginErrUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get loginErrUnexpected;

  /// No description provided for @signupHeading.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupHeading;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get signupTitle;

  /// No description provided for @signupFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupFullName;

  /// No description provided for @signupEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmail;

  /// No description provided for @signupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPassword;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Number'**
  String get signupEmergencyContact;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupButton;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupHaveAccount;

  /// No description provided for @signupLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signupLogin;

  /// No description provided for @signupErrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get signupErrNameRequired;

  /// No description provided for @signupErrEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get signupErrEmailRequired;

  /// No description provided for @signupErrEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email is invalid'**
  String get signupErrEmailInvalid;

  /// No description provided for @signupErrPassRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get signupErrPassRequired;

  /// No description provided for @signupErrPassShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get signupErrPassShort;

  /// No description provided for @signupErrConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get signupErrConfirmRequired;

  /// No description provided for @signupErrPassMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupErrPassMismatch;

  /// No description provided for @signupErrEmergencyRequired.
  ///
  /// In en, this message translates to:
  /// **'Emergency number is required'**
  String get signupErrEmergencyRequired;

  /// No description provided for @signupErrEmergencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency number must contain only digits'**
  String get signupErrEmergencyNumbers;

  /// No description provided for @signupErrEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already in use'**
  String get signupErrEmailInUse;

  /// No description provided for @signupErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get signupErrWeakPassword;

  /// No description provided for @permCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Access Required'**
  String get permCameraTitle;

  /// No description provided for @permCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Yaqdah needs your camera to monitor eye movements and detect drowsiness while driving.'**
  String get permCameraBody;

  /// No description provided for @permLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Access Required'**
  String get permLocationTitle;

  /// No description provided for @permLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Yaqdah needs your location for navigation and to send your GPS coordinates in an emergency.'**
  String get permLocationBody;

  /// No description provided for @permGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get permGrant;

  /// No description provided for @permDeny.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get permDeny;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineBanner;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
