import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens/constants/app_theme.dart';
import '../providers/settings_provider.dart';
import '../screens/auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _navy = Color(0xFF0A1628);
  static const Color _gold = Color(0xFFBFA15A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ← Just update language in memory + prefs + notify
  // No restart needed on welcome screen
  void _selectLanguage(String lang) {
    final settings = context.read<SettingsProvider>();
    settings.setLanguageImmediate(lang);
  }

  Future<void> _proceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration:
        const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isArabic = settings.isArabic;

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── LOGO ──────────────────────────────
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_city,
                      color: _gold,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── APP NAME ──────────────────────────
                  const Text(
                    'MUSCAT\nMUNICIPALITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic
                        ? 'نظام البلاغات البلدية'
                        : 'Municipal Reporting System',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _gold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── LANGUAGE SELECTION ────────────────
                  Text(
                    isArabic
                        ? 'اختر لغتك'
                        : 'Select your language',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // English
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _selectLanguage('en'),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 250),
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 16),
                            decoration: BoxDecoration(
                              color: !isArabic
                                  ? _gold
                                  : Colors.transparent,
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                color: !isArabic
                                    ? _gold
                                    : Colors.white
                                    .withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🇬🇧',
                                  style: TextStyle(
                                      fontSize: 28),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'English',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.w700,
                                    color: !isArabic
                                        ? _navy
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Arabic
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _selectLanguage('ar'),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 250),
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 16),
                            decoration: BoxDecoration(
                              color: isArabic
                                  ? _gold
                                  : Colors.transparent,
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                color: isArabic
                                    ? _gold
                                    : Colors.white
                                    .withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🇴🇲',
                                  style: TextStyle(
                                      fontSize: 28),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'العربية',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.w700,
                                    color: isArabic
                                        ? _navy
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── GET STARTED BUTTON ────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _navy,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _proceed,
                      child: Text(
                        isArabic ? 'ابدأ الآن' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}