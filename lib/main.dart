import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/learning_preferences_screen.dart';
import 'screens/auth/success_screen.dart';
import 'screens/navigation_home_bar.dart';
import 'utils/app_styles.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
   await FirebaseAppCheck.instance.activate(
    // You might need a webRecaptchaSiteKey if you enable web App Check later,
    // but for Android debug, you mainly need the androidProvider.
    // webRecaptchaSiteKey: 'recaptcha-v3-site-key', // Optional for this case
    androidProvider: true
        ? AndroidProvider.debug // Use Debug Provider in debug builds
        : AndroidProvider.playIntegrity
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _validateUserOnStartup();
  }
  
  Future<void> _validateUserOnStartup() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.validateUser();
    } catch (e) {
      print('Error during user validation: $e');
      // Handle the error gracefully
    } finally {
      // Always set initialization to true, even if validation fails
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (!_isInitialized) {
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
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppStyles.primaryColor,
            ),
          ),
        ),
      );
    }
    
    // Use a simpler approach without initialRoute or routes
    return MaterialApp(
      title: 'Baatu',
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
      // Use home directly instead of initialRoute
      home: const HomeNavigationScreen(),
      // Remove routes and onGenerateRoute completely
    );
  }
}
