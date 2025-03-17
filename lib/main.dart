import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/learning_preferences_screen.dart';
import 'screens/auth/success_screen.dart';
import 'screens/navigation_home_bar.dart';
import 'utils/app_styles.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppStyles.primaryColor,
        scaffoldBackgroundColor: AppStyles.backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppStyles.primaryColor,
          primary: AppStyles.primaryColor,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-otp': (context) => const OtpVerificationScreen(),
        '/preferences': (context) => const LearningPreferencesScreen(),
        '/success': (context) => const SuccessScreen(),
        '/home': (context) => const HomeNavigationScreen(),
      },
    );
  }
}
