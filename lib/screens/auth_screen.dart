import 'package:flutter/material.dart';
import 'login_form.dart';
import 'register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _navy = Color(0xFF0A1628);
  static const Color _gold = Color(0xFFBFA15A);
  static const Color _goldLight = Color(0xFFD4B96A);
  static const Color _surface = Color(0xFF0F1E38);
  static const Color _cardBg = Color(0xFF152236);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchTab(bool loginTab) {
    if (isLogin == loginTab) return;
    setState(() => isLogin = loginTab);
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          // ── Decorative background geometry ──
          Positioned(
            top: -80,
            right: -80,
            child: _GlowCircle(size: 280, color: _gold.withOpacity(0.07)),
          ),
          Positioned(
            top: 160,
            left: -60,
            child: _GlowCircle(size: 160, color: _gold.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -40,
            right: 40,
            child: _GlowCircle(size: 120, color: _gold.withOpacity(0.04)),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── HERO / BRAND SECTION ──
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _gold.withOpacity(0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withOpacity(0.12),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo1.jpeg',
                            height: 68,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider rule with dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoldDot(),
                            const SizedBox(width: 8),
                            Container(
                              width: 60,
                              height: 1,
                              color: _gold.withOpacity(0.4),
                            ),
                            const SizedBox(width: 8),
                            _GoldDot(),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "MUSCAT\nMUNICIPALITY",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4.0,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Municipality Reporting System",
                          style: TextStyle(
                            fontSize: 13,
                            color: _gold,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "نظام البلاغات البلدية",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── FORM PANEL ──
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: _gold.withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Gold accent bar at top of panel
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Toggle tabs ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _gold.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                _tab("Login", true),
                                _tab("Register", false),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ── Form body ──
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 20),
                                physics: const BouncingScrollPhysics(),
                                child: isLogin
                                    ? const LoginForm(key: ValueKey("login"))
                                    : const RegisterForm(
                                        key: ValueKey("register"),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String text, bool loginTab) {
    final selected = isLogin == loginTab;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(loginTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [_gold, _goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _navy : Colors.white.withOpacity(0.45),
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ──

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GoldDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFBFA15A),
      ),
    );
  }
}
