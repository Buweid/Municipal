import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MunicipalApp());
}

class MunicipalApp extends StatelessWidget {
  const MunicipalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muscat Municipality',
      debugShowCheckedModeBanner: false,

      // 🌤️ LIGHT BEIGE THEME
      theme: ThemeData(
        brightness: Brightness.light,

        scaffoldBackgroundColor: const Color(0xFFF5F1E8), // beige background

        fontFamily: 'Cairo',

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),   // green accent
          secondary: Color(0xFF1B5E20),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF5F1E8),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F1E8),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        cardTheme: const CardThemeData(
          color: Color(0xFFFFFFFF),
          elevation: 1,
          shadowColor: Color(0x11000000),
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          hintStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 1.5,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleMedium: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 🌍 Localization
    
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],

      home: const AuthScreen(),
    );
  }
}