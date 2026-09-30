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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaqdah'**
  String get appTitle;

  /// No description provided for @navDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get navDrive;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get navRest;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineBanner;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay awake.\nArrive safe.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Yaqdah watches for signs of drowsiness while you drive and warns you before it becomes dangerous.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Three permissions keep you safe'**
  String get onboardingPermsTitle;

  /// No description provided for @onboardingPermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change these any time in your phone\'s settings.'**
  String get onboardingPermsSubtitle;

  /// No description provided for @permCameraName.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permCameraName;

  /// No description provided for @permCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Watches your eyes and head position. Face detection runs on your phone.'**
  String get permCameraDesc;

  /// No description provided for @permLocationName.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permLocationName;

  /// No description provided for @permLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Finds nearby rest stops and shares where you are in an emergency.'**
  String get permLocationDesc;

  /// No description provided for @permMicName.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permMicName;

  /// No description provided for @permMicDesc.
  ///
  /// In en, this message translates to:
  /// **'Talk to the voice assistant without taking your hands off the wheel.'**
  String get permMicDesc;

  /// No description provided for @onboardingAllowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get onboardingAllowAccess;

  /// No description provided for @loginHeading.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginHeading;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start monitoring your drive.'**
  String get loginSubtitle;

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
  /// **'Keep me signed in'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Yaqdah? '**
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
  /// **'Use at least 6 characters'**
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

  /// No description provided for @loginErrResetNeedsEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above to reset your password'**
  String get loginErrResetNeedsEmail;

  /// No description provided for @loginResetSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}'**
  String loginResetSent(String email);

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Takes about a minute.'**
  String get signupSubtitle;

  /// No description provided for @signupFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
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
  /// **'Confirm password'**
  String get signupConfirmPassword;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupButton;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupHaveAccount;

  /// No description provided for @signupLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
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
  /// **'Use at least 6 characters'**
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

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number, like 91 234 5678'**
  String get phoneInvalid;

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

  /// No description provided for @emergencyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContactTitle;

  /// No description provided for @emergencyContactHelp.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t respond to a danger alert, we text your location to this number.'**
  String get emergencyContactHelp;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @readyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to drive'**
  String get readyTitle;

  /// No description provided for @almostReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost ready'**
  String get almostReadyTitle;

  /// No description provided for @checksPassed.
  ///
  /// In en, this message translates to:
  /// **'All checks passed'**
  String get checksPassed;

  /// No description provided for @checksAttention.
  ///
  /// In en, this message translates to:
  /// **'Some checks need attention'**
  String get checksAttention;

  /// No description provided for @checksRunning.
  ///
  /// In en, this message translates to:
  /// **'Running checks…'**
  String get checksRunning;

  /// No description provided for @checkFace.
  ///
  /// In en, this message translates to:
  /// **'Face visible'**
  String get checkFace;

  /// No description provided for @checkFaceFix.
  ///
  /// In en, this message translates to:
  /// **'Face the camera'**
  String get checkFaceFix;

  /// No description provided for @checkPending.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkPending;

  /// No description provided for @cameraFront.
  ///
  /// In en, this message translates to:
  /// **'Front camera'**
  String get cameraFront;

  /// No description provided for @cameraBack.
  ///
  /// In en, this message translates to:
  /// **'Back camera'**
  String get cameraBack;

  /// No description provided for @cameraExternal.
  ///
  /// In en, this message translates to:
  /// **'External camera'**
  String get cameraExternal;

  /// No description provided for @cameraGeneric.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraGeneric;

  /// No description provided for @checkSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get checkSwitch;

  /// No description provided for @checkNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera'**
  String get checkNoCamera;

  /// No description provided for @checkGps.
  ///
  /// In en, this message translates to:
  /// **'GPS signal'**
  String get checkGps;

  /// No description provided for @gpsStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get gpsStrong;

  /// No description provided for @gpsWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get gpsWeak;

  /// No description provided for @gpsSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get gpsSearching;

  /// No description provided for @gpsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get gpsOff;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @whereToOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get whereToOptional;

  /// No description provided for @clearDestination.
  ///
  /// In en, this message translates to:
  /// **'Clear destination'**
  String get clearDestination;

  /// No description provided for @lastTripLine.
  ///
  /// In en, this message translates to:
  /// **'Last trip {when} · {distance} km · {alerts}'**
  String lastTripLine(String when, String distance, String alerts);

  /// No description provided for @lastTripToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get lastTripToday;

  /// No description provided for @lastTripYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get lastTripYesterday;

  /// No description provided for @lastTripOn.
  ///
  /// In en, this message translates to:
  /// **'on {day}'**
  String lastTripOn(String day);

  /// No description provided for @alertCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no alerts} =1{1 alert} other{{count} alerts}}'**
  String alertCount(int count);

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant'**
  String get voiceAssistant;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchPlaces;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get searchNoResults;

  /// No description provided for @droppedPin.
  ///
  /// In en, this message translates to:
  /// **'Dropped pin'**
  String get droppedPin;

  /// No description provided for @findingRoute.
  ///
  /// In en, this message translates to:
  /// **'Finding route…'**
  String get findingRoute;

  /// No description provided for @routeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No route found'**
  String get routeUnavailable;

  /// No description provided for @etaLine.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · arrive {time}'**
  String etaLine(int minutes, String time);

  /// No description provided for @recenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter map'**
  String get recenterMap;

  /// No description provided for @driverStatus.
  ///
  /// In en, this message translates to:
  /// **'Driver status'**
  String get driverStatus;

  /// No description provided for @statusAwake.
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get statusAwake;

  /// No description provided for @statusDrowsy.
  ///
  /// In en, this message translates to:
  /// **'Drowsy'**
  String get statusDrowsy;

  /// No description provided for @statusDistracted.
  ///
  /// In en, this message translates to:
  /// **'Distracted'**
  String get statusDistracted;

  /// No description provided for @statusNoFace.
  ///
  /// In en, this message translates to:
  /// **'No face detected'**
  String get statusNoFace;

  /// No description provided for @statusDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get statusDanger;

  /// No description provided for @drowsinessCaption.
  ///
  /// In en, this message translates to:
  /// **'drowsiness'**
  String get drowsinessCaption;

  /// No description provided for @statTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get statTime;

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

  /// No description provided for @holdForSos.
  ///
  /// In en, this message translates to:
  /// **'Hold for SOS'**
  String get holdForSos;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @standbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Standby mode'**
  String get standbyTitle;

  /// No description provided for @standbyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to wake'**
  String get standbyHint;

  /// No description provided for @sosSentTo.
  ///
  /// In en, this message translates to:
  /// **'SOS sent to {contact}'**
  String sosSentTo(String contact);

  /// No description provided for @stopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm'**
  String get stopAlarm;

  /// No description provided for @sosSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the SOS text'**
  String get sosSendFailed;

  /// No description provided for @sosSending.
  ///
  /// In en, this message translates to:
  /// **'Sending SOS…'**
  String get sosSending;

  /// No description provided for @sosSmsBody.
  ///
  /// In en, this message translates to:
  /// **'SOS from Yaqdah: the driver may be in danger.'**
  String get sosSmsBody;

  /// No description provided for @sosSmsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sosSmsLocation;

  /// No description provided for @voiceEndingTrip.
  ///
  /// In en, this message translates to:
  /// **'Ending the trip.'**
  String get voiceEndingTrip;

  /// No description provided for @voiceSendingSos.
  ///
  /// In en, this message translates to:
  /// **'Sending an emergency alert.'**
  String get voiceSendingSos;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I can\'t answer right now.'**
  String get voiceUnavailable;

  /// No description provided for @interventionDistracted.
  ///
  /// In en, this message translates to:
  /// **'Eyes on the road!'**
  String get interventionDistracted;

  /// No description provided for @interventionDrowsy.
  ///
  /// In en, this message translates to:
  /// **'You look tired. Take a break soon.'**
  String get interventionDrowsy;

  /// No description provided for @drowsyAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re getting drowsy'**
  String get drowsyAlertTitle;

  /// No description provided for @drowsyAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Your eyes are closing more often. A 15-minute break makes a real difference.'**
  String get drowsyAlertBody;

  /// No description provided for @nearestRestStop.
  ///
  /// In en, this message translates to:
  /// **'Nearest rest stop'**
  String get nearestRestStop;

  /// No description provided for @findingRestStop.
  ///
  /// In en, this message translates to:
  /// **'Finding a rest stop…'**
  String get findingRestStop;

  /// No description provided for @noRestStopNearby.
  ///
  /// In en, this message translates to:
  /// **'No rest stops found nearby. Pull over somewhere safe.'**
  String get noRestStopNearby;

  /// No description provided for @takeMeThere.
  ///
  /// In en, this message translates to:
  /// **'Take me there'**
  String get takeMeThere;

  /// No description provided for @keepDriving.
  ///
  /// In en, this message translates to:
  /// **'I\'m fine, keep driving'**
  String get keepDriving;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @dangerAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Pull over now'**
  String get dangerAlertTitle;

  /// No description provided for @dangerAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Your eyes have been closed. If you don\'t respond, we\'ll text your location to your emergency contact.'**
  String get dangerAlertBody;

  /// No description provided for @sosCountdown.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Sending SOS in 1 second} other{Sending SOS in {seconds} seconds}}'**
  String sosCountdown(int seconds);

  /// No description provided for @sosTo.
  ///
  /// In en, this message translates to:
  /// **'to {contact}'**
  String sosTo(String contact);

  /// No description provided for @sosAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Automatic SOS text is off'**
  String get sosAutoOff;

  /// No description provided for @sosNoContact.
  ///
  /// In en, this message translates to:
  /// **'No emergency contact set'**
  String get sosNoContact;

  /// No description provided for @sosSentTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS sent'**
  String get sosSentTitle;

  /// No description provided for @imAwake.
  ///
  /// In en, this message translates to:
  /// **'I\'m awake'**
  String get imAwake;

  /// No description provided for @sendSosNow.
  ///
  /// In en, this message translates to:
  /// **'Send SOS now'**
  String get sendSosNow;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

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

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @driverLevel.
  ///
  /// In en, this message translates to:
  /// **'Driver level'**
  String get driverLevel;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelN(int level);

  /// No description provided for @safeKm.
  ///
  /// In en, this message translates to:
  /// **'{km} safe km'**
  String safeKm(String km);

  /// No description provided for @kmToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{km} km to Level {level}'**
  String kmToNextLevel(String km, int level);

  /// No description provided for @badgeFirstSafeTrip.
  ///
  /// In en, this message translates to:
  /// **'First Safe Trip'**
  String get badgeFirstSafeTrip;

  /// No description provided for @badgePerfect10.
  ///
  /// In en, this message translates to:
  /// **'Perfect 10'**
  String get badgePerfect10;

  /// No description provided for @badgeNightOwl.
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get badgeNightOwl;

  /// No description provided for @badgeMarathoner.
  ///
  /// In en, this message translates to:
  /// **'Marathoner'**
  String get badgeMarathoner;

  /// No description provided for @reportsTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get reportsTrips;

  /// No description provided for @reportsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get reportsDistance;

  /// No description provided for @reportsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get reportsAlerts;

  /// No description provided for @legendSafeDays.
  ///
  /// In en, this message translates to:
  /// **'Safe days'**
  String get legendSafeDays;

  /// No description provided for @legendAlertDays.
  ///
  /// In en, this message translates to:
  /// **'Days with alerts'**
  String get legendAlertDays;

  /// No description provided for @recentTrips.
  ///
  /// In en, this message translates to:
  /// **'Recent trips'**
  String get recentTrips;

  /// No description provided for @reportsNoTripsInRange.
  ///
  /// In en, this message translates to:
  /// **'No trips in this period'**
  String get reportsNoTripsInRange;

  /// No description provided for @tripRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{duration} · {distance} km · {alerts}'**
  String tripRowSubtitle(String duration, String distance, String alerts);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a trip to see your driving stats here.'**
  String get reportsEmptySubtitle;

  /// No description provided for @tripDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetailsTitle;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get shareReport;

  /// No description provided for @tripSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get tripSafe;

  /// No description provided for @safetyScore.
  ///
  /// In en, this message translates to:
  /// **'Safety score'**
  String get safetyScore;

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

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get avgSpeed;

  /// No description provided for @topSpeed.
  ///
  /// In en, this message translates to:
  /// **'Top speed'**
  String get topSpeed;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @tlTripStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get tlTripStarted;

  /// No description provided for @tlTripEnded.
  ///
  /// In en, this message translates to:
  /// **'Trip ended'**
  String get tlTripEnded;

  /// No description provided for @tlDrowsy.
  ///
  /// In en, this message translates to:
  /// **'Drowsiness detected'**
  String get tlDrowsy;

  /// No description provided for @tlDistracted.
  ///
  /// In en, this message translates to:
  /// **'Distraction detected'**
  String get tlDistracted;

  /// No description provided for @tlDanger.
  ///
  /// In en, this message translates to:
  /// **'Eyes closed: danger alert'**
  String get tlDanger;

  /// No description provided for @tlSos.
  ///
  /// In en, this message translates to:
  /// **'SOS sent'**
  String get tlSos;

  /// No description provided for @tlTookBreak.
  ///
  /// In en, this message translates to:
  /// **'you took a break'**
  String get tlTookBreak;

  /// No description provided for @tlKeptDriving.
  ///
  /// In en, this message translates to:
  /// **'you kept driving'**
  String get tlKeptDriving;

  /// No description provided for @tlConfirmedAwake.
  ///
  /// In en, this message translates to:
  /// **'you confirmed you were awake'**
  String get tlConfirmedAwake;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTrip;

  /// No description provided for @deleteTripConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip?'**
  String get deleteTripConfirmTitle;

  /// No description provided for @deleteTripConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the trip and its report. You can\'t undo this.'**
  String get deleteTripConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noRouteRecorded.
  ///
  /// In en, this message translates to:
  /// **'No route recorded'**
  String get noRouteRecorded;

  /// No description provided for @restTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a break'**
  String get restTitle;

  /// No description provided for @restSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rest stops within {km} km of you'**
  String restSubtitle(int km);

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catCafes.
  ///
  /// In en, this message translates to:
  /// **'Cafés'**
  String get catCafes;

  /// No description provided for @catMosques.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get catMosques;

  /// No description provided for @catHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get catHotels;

  /// No description provided for @placeCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get placeCafe;

  /// No description provided for @placeMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosque'**
  String get placeMosque;

  /// No description provided for @placeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get placeHotel;

  /// No description provided for @placeFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel station'**
  String get placeFuel;

  /// No description provided for @placeRestArea.
  ///
  /// In en, this message translates to:
  /// **'Rest area'**
  String get placeRestArea;

  /// No description provided for @placeOther.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeOther;

  /// No description provided for @placeRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} · {distance} km · {minutes} min'**
  String placeRowSubtitle(String type, String distance, int minutes);

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @restEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No rest stops found nearby'**
  String get restEmptyState;

  /// No description provided for @restRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get restRetry;

  /// No description provided for @restWaitingLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your location…'**
  String get restWaitingLocation;

  /// No description provided for @restLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see rest stops near you.'**
  String get restLocationOff;

  /// No description provided for @restLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load places. Check your connection and try again.'**
  String get restLoadFailed;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @userFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get userFallbackName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @sectionSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get sectionSafety;

  /// No description provided for @sectionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get sectionAlerts;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @autoSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic SOS text'**
  String get autoSosTitle;

  /// No description provided for @autoSosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t respond to a danger alert'**
  String get autoSosSubtitle;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @voiceAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spoken tips when you\'re at risk'**
  String get voiceAssistantSubtitle;

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get alarmSound;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

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

  /// No description provided for @testLab.
  ///
  /// In en, this message translates to:
  /// **'Test lab'**
  String get testLab;

  /// No description provided for @testLabValue.
  ///
  /// In en, this message translates to:
  /// **'Live model data'**
  String get testLabValue;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your details'**
  String get editProfileSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all trip data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes every trip saved on this phone'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all trip data?'**
  String get deleteDataConfirmTitle;

  /// No description provided for @deleteDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes every trip saved on this phone. You can\'t undo this.'**
  String get deleteDataConfirmBody;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All trip data deleted'**
  String get allDataDeleted;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @currentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordWrong;

  /// No description provided for @smsPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow SMS so Yaqdah can text your emergency contact'**
  String get smsPermissionNeeded;
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
