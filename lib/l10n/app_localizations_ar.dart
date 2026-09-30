// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'يقظة';

  @override
  String get navDrive => 'القيادة';

  @override
  String get navReports => 'التقارير';

  @override
  String get navRest => 'الراحة';

  @override
  String get navAccount => 'الحساب';

  @override
  String get offlineBanner => 'لا يوجد اتصال بالإنترنت';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingWelcomeTitle => 'ابقَ يقظًا.\nصِل بسلام.';

  @override
  String get onboardingWelcomeBody =>
      'يراقب تطبيق يقظة علامات النعاس أثناء قيادتك وينبّهك قبل أن تصبح خطرًا.';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingPermsTitle => 'ثلاثة أذونات تحافظ على سلامتك';

  @override
  String get onboardingPermsSubtitle =>
      'يمكنك تغييرها في أي وقت من إعدادات هاتفك.';

  @override
  String get permCameraName => 'الكاميرا';

  @override
  String get permCameraDesc =>
      'تراقب عينيك ووضعية رأسك. يعمل كشف الوجه على هاتفك.';

  @override
  String get permLocationName => 'الموقع';

  @override
  String get permLocationDesc =>
      'يجد أماكن الراحة القريبة ويشارك موقعك في حالات الطوارئ.';

  @override
  String get permMicName => 'الميكروفون';

  @override
  String get permMicDesc =>
      'تحدّث إلى المساعد الصوتي دون أن ترفع يديك عن المقود.';

  @override
  String get onboardingAllowAccess => 'السماح بالوصول';

  @override
  String get loginHeading => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لبدء مراقبة قيادتك.';

  @override
  String get loginEmail => 'البريد الإلكتروني';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginRememberMe => 'إبقائي مسجّلًا';

  @override
  String get loginForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginNoAccount => 'جديد على يقظة؟ ';

  @override
  String get loginSignup => 'أنشئ حسابًا';

  @override
  String get loginErrEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get loginErrEmailInvalid => 'البريد الإلكتروني غير صحيح';

  @override
  String get loginErrPassRequired => 'كلمة المرور مطلوبة';

  @override
  String get loginErrPassShort => 'استخدم 6 أحرف على الأقل';

  @override
  String get loginErrNotFound => 'لا يوجد حساب بهذا البريد الإلكتروني';

  @override
  String get loginErrWrongPass => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get loginErrTooMany => 'محاولات كثيرة. حاول لاحقاً';

  @override
  String get loginErrGeneric => 'حدث خطأ';

  @override
  String get loginErrUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get loginErrResetNeedsEmail =>
      'أدخل بريدك الإلكتروني أعلاه لإعادة تعيين كلمة المرور';

  @override
  String loginResetSent(String email) {
    return 'أرسلنا رابط إعادة التعيين إلى $email';
  }

  @override
  String get signupTitle => 'أنشئ حسابك';

  @override
  String get signupSubtitle => 'يستغرق دقيقة تقريبًا.';

  @override
  String get signupFullName => 'الاسم الكامل';

  @override
  String get signupEmail => 'البريد الإلكتروني';

  @override
  String get signupPassword => 'كلمة المرور';

  @override
  String get signupConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get signupButton => 'إنشاء حساب';

  @override
  String get signupHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get signupLogin => 'تسجيل الدخول';

  @override
  String get signupErrNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get signupErrEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get signupErrEmailInvalid => 'البريد الإلكتروني غير صحيح';

  @override
  String get signupErrPassRequired => 'كلمة المرور مطلوبة';

  @override
  String get signupErrPassShort => 'استخدم 6 أحرف على الأقل';

  @override
  String get signupErrConfirmRequired => 'تأكيد كلمة المرور مطلوب';

  @override
  String get signupErrPassMismatch => 'كلمة المرور غير متطابقة';

  @override
  String get signupErrEmergencyRequired => 'رقم الطوارئ مطلوب';

  @override
  String get phoneInvalid => 'أدخل رقمًا صحيحًا، مثل 91 234 5678';

  @override
  String get signupErrEmailInUse => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get signupErrWeakPassword => 'كلمة المرور ضعيفة جداً';

  @override
  String get emergencyContactTitle => 'جهة اتصال الطوارئ';

  @override
  String get emergencyContactHelp =>
      'إذا لم تستجب لتنبيه الخطر، نرسل موقعك برسالة نصية إلى هذا الرقم.';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get readyTitle => 'جاهز للقيادة';

  @override
  String get almostReadyTitle => 'على وشك الجاهزية';

  @override
  String get checksPassed => 'اجتزت جميع الفحوصات';

  @override
  String get checksAttention => 'بعض الفحوصات تحتاج انتباهك';

  @override
  String get checksRunning => 'جارٍ الفحص…';

  @override
  String get checkFace => 'الوجه ظاهر';

  @override
  String get checkFaceFix => 'انظر إلى الكاميرا';

  @override
  String get checkPending => 'جارٍ الفحص…';

  @override
  String get cameraFront => 'الكاميرا الأمامية';

  @override
  String get cameraBack => 'الكاميرا الخلفية';

  @override
  String get cameraExternal => 'كاميرا خارجية';

  @override
  String get cameraGeneric => 'الكاميرا';

  @override
  String get checkSwitch => 'تبديل';

  @override
  String get checkNoCamera => 'لا توجد كاميرا';

  @override
  String get checkGps => 'إشارة GPS';

  @override
  String get gpsStrong => 'قوية';

  @override
  String get gpsWeak => 'ضعيفة';

  @override
  String get gpsSearching => 'جارٍ البحث…';

  @override
  String get gpsOff => 'متوقف';

  @override
  String get whereTo => 'إلى أين؟';

  @override
  String get whereToOptional => '(اختياري)';

  @override
  String get clearDestination => 'مسح الوجهة';

  @override
  String lastTripLine(String when, String distance, String alerts) {
    return 'آخر رحلة $when · $distance كم · $alerts';
  }

  @override
  String get lastTripToday => 'اليوم';

  @override
  String get lastTripYesterday => 'أمس';

  @override
  String lastTripOn(String day) {
    return 'يوم $day';
  }

  @override
  String alertCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تنبيه',
      many: '$count تنبيهًا',
      few: '$count تنبيهات',
      two: 'تنبيهان',
      one: 'تنبيه واحد',
      zero: 'بدون تنبيهات',
    );
    return '$_temp0';
  }

  @override
  String get startTrip => 'ابدأ الرحلة';

  @override
  String get voiceAssistant => 'المساعد الصوتي';

  @override
  String get searchPlaces => 'ابحث عن مكان';

  @override
  String get searchNoResults => 'لم يتم العثور على أماكن';

  @override
  String get droppedPin => 'نقطة محددة';

  @override
  String get findingRoute => 'جارٍ إيجاد المسار…';

  @override
  String get routeUnavailable => 'تعذّر إيجاد مسار';

  @override
  String etaLine(int minutes, String time) {
    return '$minutes د · الوصول $time';
  }

  @override
  String get recenterMap => 'توسيط الخريطة';

  @override
  String get driverStatus => 'حالة السائق';

  @override
  String get statusAwake => 'يقظ';

  @override
  String get statusDrowsy => 'نعسان';

  @override
  String get statusDistracted => 'مشتت';

  @override
  String get statusNoFace => 'لم يُكتشف وجه';

  @override
  String get statusDanger => 'خطر';

  @override
  String get drowsinessCaption => 'النعاس';

  @override
  String get statTime => 'الوقت';

  @override
  String get statDistance => 'المسافة';

  @override
  String get statSpeed => 'السرعة';

  @override
  String get kmUnit => 'كم';

  @override
  String get kmhUnit => 'كم/س';

  @override
  String get holdForSos => 'اضغط مطولًا للطوارئ';

  @override
  String get endTrip => 'إنهاء الرحلة';

  @override
  String get standbyTitle => 'وضع الاستعداد';

  @override
  String get standbyHint => 'اضغط في أي مكان للاستيقاظ';

  @override
  String sosSentTo(String contact) {
    return 'أُرسل نداء الطوارئ إلى $contact';
  }

  @override
  String get stopAlarm => 'إيقاف الإنذار';

  @override
  String get sosSendFailed => 'تعذّر إرسال رسالة الطوارئ';

  @override
  String get sosSending => 'جارٍ إرسال نداء الطوارئ…';

  @override
  String get sosSmsBody => 'نداء طوارئ من يقظة: قد يكون السائق في خطر.';

  @override
  String get sosSmsLocation => 'الموقع';

  @override
  String get voiceEndingTrip => 'جارٍ إنهاء الرحلة.';

  @override
  String get voiceSendingSos => 'جارٍ إرسال نداء الطوارئ.';

  @override
  String get voiceUnavailable => 'عذرًا، لا أستطيع الرد الآن.';

  @override
  String get interventionDistracted => 'انتبه للطريق!';

  @override
  String get interventionDrowsy => 'تبدو متعبًا. خذ استراحة قريبًا.';

  @override
  String get drowsyAlertTitle => 'بدأت تشعر بالنعاس';

  @override
  String get drowsyAlertBody =>
      'عيناك تنغلقان أكثر من المعتاد. استراحة لمدة 15 دقيقة تُحدث فرقًا حقيقيًا.';

  @override
  String get nearestRestStop => 'أقرب مكان للراحة';

  @override
  String get findingRestStop => 'جارٍ البحث عن مكان للراحة…';

  @override
  String get noRestStopNearby => 'لا توجد أماكن راحة قريبة. توقف في مكان آمن.';

  @override
  String get takeMeThere => 'خذني إلى هناك';

  @override
  String get keepDriving => 'أنا بخير، سأواصل القيادة';

  @override
  String minutesShort(int minutes) {
    return '$minutes د';
  }

  @override
  String get dangerAlertTitle => 'توقف الآن';

  @override
  String get dangerAlertBody =>
      'كانت عيناك مغمضتين. إذا لم تستجب، سنرسل موقعك برسالة نصية إلى جهة اتصال الطوارئ.';

  @override
  String sosCountdown(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'إرسال نداء الطوارئ خلال $seconds ثانية',
      few: 'إرسال نداء الطوارئ خلال $seconds ثوانٍ',
      two: 'إرسال نداء الطوارئ خلال ثانيتين',
      one: 'إرسال نداء الطوارئ خلال ثانية',
    );
    return '$_temp0';
  }

  @override
  String sosTo(String contact) {
    return 'إلى $contact';
  }

  @override
  String get sosAutoOff => 'رسالة الطوارئ التلقائية متوقفة';

  @override
  String get sosNoContact => 'لم يتم تعيين جهة اتصال للطوارئ';

  @override
  String get sosSentTitle => 'تم إرسال نداء الطوارئ';

  @override
  String get imAwake => 'أنا مستيقظ';

  @override
  String get sendSosNow => 'أرسل نداء الطوارئ الآن';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get filterWeek => 'أسبوع';

  @override
  String get filterMonth => 'شهر';

  @override
  String get filterAll => 'الكل';

  @override
  String get driverLevel => 'مستوى السائق';

  @override
  String levelN(int level) {
    return 'المستوى $level';
  }

  @override
  String safeKm(String km) {
    return '$km كم آمنة';
  }

  @override
  String kmToNextLevel(String km, int level) {
    return '$km كم للمستوى $level';
  }

  @override
  String get badgeFirstSafeTrip => 'أول رحلة آمنة';

  @override
  String get badgePerfect10 => 'العشرة المثالية';

  @override
  String get badgeNightOwl => 'بومة الليل';

  @override
  String get badgeMarathoner => 'عدّاء الماراثون';

  @override
  String get reportsTrips => 'الرحلات';

  @override
  String get reportsDistance => 'المسافة';

  @override
  String get reportsAlerts => 'التنبيهات';

  @override
  String get legendSafeDays => 'أيام آمنة';

  @override
  String get legendAlertDays => 'أيام بها تنبيهات';

  @override
  String get recentTrips => 'الرحلات الأخيرة';

  @override
  String get reportsNoTripsInRange => 'لا توجد رحلات في هذه الفترة';

  @override
  String tripRowSubtitle(String duration, String distance, String alerts) {
    return '$duration · $distance كم · $alerts';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get reportsEmptyTitle => 'لا توجد رحلات بعد';

  @override
  String get reportsEmptySubtitle => 'ابدأ رحلة لتظهر إحصائيات قيادتك هنا.';

  @override
  String get tripDetailsTitle => 'تفاصيل الرحلة';

  @override
  String get shareReport => 'مشاركة التقرير';

  @override
  String get tripSafe => 'آمنة';

  @override
  String get safetyScore => 'درجة الأمان';

  @override
  String get tripDuration => 'المدة';

  @override
  String get tripDistance => 'المسافة';

  @override
  String get avgSpeed => 'متوسط السرعة';

  @override
  String get topSpeed => 'أقصى سرعة';

  @override
  String get timeline => 'المخطط الزمني';

  @override
  String get tlTripStarted => 'بدأت الرحلة';

  @override
  String get tlTripEnded => 'انتهت الرحلة';

  @override
  String get tlDrowsy => 'رُصد نعاس';

  @override
  String get tlDistracted => 'رُصد تشتت';

  @override
  String get tlDanger => 'عينان مغمضتان: تنبيه خطر';

  @override
  String get tlSos => 'أُرسل نداء الطوارئ';

  @override
  String get tlTookBreak => 'أخذت استراحة';

  @override
  String get tlKeptDriving => 'واصلت القيادة';

  @override
  String get tlConfirmedAwake => 'أكدت أنك مستيقظ';

  @override
  String get deleteTrip => 'حذف الرحلة';

  @override
  String get deleteTripConfirmTitle => 'حذف هذه الرحلة؟';

  @override
  String get deleteTripConfirmBody =>
      'سيؤدي هذا إلى حذف الرحلة وتقريرها. لا يمكن التراجع عن ذلك.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get noRouteRecorded => 'لم يُسجَّل مسار';

  @override
  String get restTitle => 'خذ استراحة';

  @override
  String restSubtitle(int km) {
    return 'أماكن راحة ضمن $km كم منك';
  }

  @override
  String get catAll => 'الكل';

  @override
  String get catCafes => 'مقاهٍ';

  @override
  String get catMosques => 'مساجد';

  @override
  String get catHotels => 'فنادق';

  @override
  String get placeCafe => 'مقهى';

  @override
  String get placeMosque => 'مسجد';

  @override
  String get placeHotel => 'فندق';

  @override
  String get placeFuel => 'محطة وقود';

  @override
  String get placeRestArea => 'استراحة طريق';

  @override
  String get placeOther => 'مكان';

  @override
  String placeRowSubtitle(String type, String distance, int minutes) {
    return '$type · $distance كم · $minutes د';
  }

  @override
  String get go => 'انطلق';

  @override
  String get restEmptyState => 'لا توجد أماكن راحة قريبة';

  @override
  String get restRetry => 'حاول مرة أخرى';

  @override
  String get restWaitingLocation => 'بانتظار تحديد موقعك…';

  @override
  String get restLocationOff =>
      'فعّل خدمة الموقع لعرض أماكن الراحة القريبة منك.';

  @override
  String get restLoadFailed =>
      'تعذّر تحميل الأماكن. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get accountTitle => 'الحساب';

  @override
  String get userFallbackName => 'السائق';

  @override
  String get edit => 'تعديل';

  @override
  String get sectionSafety => 'السلامة';

  @override
  String get sectionAlerts => 'التنبيهات';

  @override
  String get sectionApp => 'التطبيق';

  @override
  String get autoSosTitle => 'رسالة طوارئ تلقائية';

  @override
  String get autoSosSubtitle => 'إذا لم تستجب لتنبيه الخطر';

  @override
  String get notSet => 'غير محدد';

  @override
  String get voiceAssistantSubtitle => 'نصائح صوتية عندما تكون في خطر';

  @override
  String get alarmSound => 'صوت الإنذار';

  @override
  String get vibration => 'الاهتزاز';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get testLab => 'مختبر الاختبار';

  @override
  String get testLabValue => 'بيانات النموذج المباشرة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get editProfileSubtitle => 'حدّث بياناتك';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get deleteAllData => 'حذف جميع بيانات الرحلات';

  @override
  String get deleteAllDataSubtitle => 'يحذف كل الرحلات المحفوظة على هذا الهاتف';

  @override
  String get deleteDataConfirmTitle => 'حذف جميع بيانات الرحلات؟';

  @override
  String get deleteDataConfirmBody =>
      'سيؤدي هذا إلى حذف كل الرحلات المحفوظة على هذا الهاتف. لا يمكن التراجع عن ذلك.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get allDataDeleted => 'تم حذف جميع بيانات الرحلات';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور';

  @override
  String get currentPasswordWrong => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get smsPermissionNeeded =>
      'اسمح بالرسائل النصية ليتمكن يقظة من مراسلة جهة اتصال الطوارئ';
}
