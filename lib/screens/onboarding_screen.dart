import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.microphone,
    ].request();
  }

  void _onIntroEnd(context) async {
    await _requestPermissions();
    if (context.mounted) {
      Provider.of<AuthProvider>(context, listen: false).completeOnboarding();
    }
  }

  Widget _buildImage(String assetName, [double width = 250]) {
    // If you don't have specific onboarding images, we can use icons
    // or the existing logo. For now, let's use Icons if images aren't there.
    // Ideally we would use: Image.asset('images/$assetName', width: width);
    // But since I don't want to break it with missing assets, I'll use a placeholder builder
    // that tries the asset but falls back to an Icon.

    return Image.asset(
      'images/$assetName',
      width: width,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.featured_play_list,
          size: 100,
          color: ThemeService.purple,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: false,

      pages: [
        PageViewModel(
          title: "مرحبًا بك في يقظة",
          body:
              "Your intelligent companion for safer driving. Stay awake, stay safe.",
          image: _buildImage('yaqdah-05.png'),
          decoration: pageDecoration.copyWith(
            pageColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 19,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
        PageViewModel(
          title: "مراقبتك الذكي",
          body:
              "نستخدم  الذكاء الاصطناعي لمراقبة عينيك ووضعية رأسك للكشف عن علامات النعاس.",
          image: Icon(
            Icons.remove_red_eye_rounded,
            size: 150,
            color: ThemeService.purple,
          ),
          decoration: pageDecoration.copyWith(
            pageColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 19,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
        PageViewModel(
          title: "Permissions Needed",
          body:
              "To protect you, we need access to your Camera (for eyes) and Location (for SOS).",
          image: Icon(Icons.security, size: 150, color: ThemeService.orange),
          decoration: pageDecoration.copyWith(
            pageColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 19,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip behavior
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Uncomment to enable RTL for Arabic
      back: const Icon(Icons.arrow_back),
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Start', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
