import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/brand.dart';

/// Two pages: welcome, then the permissions explainer.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.microphone,
      // The SOS text is sent while the driver can't answer a prompt, so
      // ask now. Only Android apps can send texts.
      if (Platform.isAndroid) Permission.sms,
    ].request();
  }

  void _onIntroEnd(BuildContext context) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await _requestPermissions();
    if (context.mounted) {
      // Location updates couldn't start before the permission was granted.
      context.read<LocationProvider>().startLocationUpdates();
      Provider.of<AuthProvider>(context, listen: false).completeOnboarding();
    }
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back (page 2 only) and Skip.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      onPressed: () => _goTo(_page - 1),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: AppIcon(
                        Symbols.arrow_back_rounded,
                        color: c.text,
                        mirror: true,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _onIntroEnd(context),
                    style: TextButton.styleFrom(
                      foregroundColor: c.subtext,
                      minimumSize: const Size(44, 44),
                    ),
                    child: Text(
                      l10n.onboardingSkip,
                      style: AppFonts.body(
                        context,
                        16,
                        weight: FontWeight.w600,
                        color: c.subtext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [_WelcomePage(), _PermissionsPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Row(
                      children: [
                        for (var i = 0; i < 2; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: i == _page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? c.primary : c.line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: _page == 0 ? 28 : 20),
                  _page == 0
                      ? AppButton(
                          label: l10n.onboardingGetStarted,
                          onPressed: () => _goTo(1),
                          trailingIcon: Symbols.arrow_forward_rounded,
                        )
                      : AppButton(
                          label: l10n.onboardingAllowAccess,
                          loading: _finishing,
                          onPressed: () => _onIntroEnd(context),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LogoTile(
              size: 152,
              radius: 44,
              logoWidth: 96,
              shadow: [
                BoxShadow(
                  color: Color(0x403C1EB4),
                  blurRadius: 60,
                  offset: Offset(0, 24),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              l10n.onboardingWelcomeTitle,
              style: AppFonts.display(
                context,
                42,
                color: c.text,
                height: 1.05,
                tracking: -0.025,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingWelcomeBody,
              style: AppFonts.body(context, 18, color: c.subtext, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingPermsTitle,
            style: AppFonts.display(
              context,
              34,
              color: c.text,
              height: 1.1,
              tracking: -0.02,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingPermsSubtitle,
            style: AppFonts.body(context, 17, color: c.subtext, height: 1.5),
          ),
          const SizedBox(height: 32),
          _PermissionCard(
            icon: Symbols.photo_camera_rounded,
            title: l10n.permCameraName,
            body: l10n.permCameraDesc,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            icon: Symbols.location_on_rounded,
            title: l10n.permLocationName,
            body: l10n.permLocationDesc,
          ),
          const SizedBox(height: 12),
          _PermissionCard(
            icon: Symbols.mic_rounded,
            title: l10n.permMicName,
            body: l10n.permMicDesc,
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: icon,
            background: c.primarySoft,
            foreground: c.primary,
            size: 48,
            radius: 14,
            iconSize: 26,
            filled: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.body(
                    context,
                    17,
                    weight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppFonts.body(
                    context,
                    15,
                    color: c.subtext,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
