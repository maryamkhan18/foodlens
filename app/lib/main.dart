import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FoodLensApp());
}

class FoodLensApp extends StatelessWidget {
  const FoodLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI FoodLens',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDF6EC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8734A),
          primary: const Color(0xFFE8734A),
          secondary: const Color(0xFF7C9A62),
          background: const Color(0xFFFDF6EC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDF6EC),
          foregroundColor: Color(0xFF3A2E28),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8734A),
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}