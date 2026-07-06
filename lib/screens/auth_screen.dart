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

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchTab(bool loginTab) {
    if (isLogin == loginTab) return;

    setState(() {
      isLogin = loginTab;
    });

    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                /// ✅ FIXED HERE (scrollable)
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          const Text(
                            "MUSCAT\nMUNICIPALITY",
                            key: Key("app_title"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Municipality Reporting System",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              _tab("Login", true,
                                  key: const Key("login_tab")),
                              _tab("Register", false,
                                  key: const Key("register_tab")),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: SingleChildScrollView(
                                child: isLogin
                                    ? const  LoginForm()
                                    : const  RegisterForm()
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

  Widget _tab(String text, bool loginTab, {Key? key}) {
    final selected = isLogin == loginTab;

    return Expanded(
      child: GestureDetector(

        onTap: () => _switchTab(loginTab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: selected ? _gold : Colors.transparent,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _navy : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}