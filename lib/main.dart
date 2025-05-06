import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_styles.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: true
        ? AndroidProvider.debug
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
      }
    );
  }
}
