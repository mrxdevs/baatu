import 'package:baatu/services/google_sign_in.dart';
import 'package:baatu/utils/app_config.dart';
import 'package:baatu/utils/get_package_details.dart';
import 'package:baatu/utils/route_helper.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'utils/app_styles.dart';
import 'services/auth_service.dart';
import 'screens/share_screen.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();

  // Set Firebase Auth language code to avoid null X-Firebase-Locale warning
  await FirebaseAuth.instance.setLanguageCode('en');

  // Activate Firebase App Check with Debug provider in debug mode & Play Integrity in release
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('FirebaseAppCheck activation notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GoogleSignInProvider()),
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
  @override
  void initState() {
    super.initState();
    AppPackageDetails.getPackageDetails();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Baatu',
        debugShowCheckedModeBanner: AppConfig.appMode != AppMode.TEST,
        theme: ThemeData(
          primaryColor: AppStyles.primaryColor,
          scaffoldBackgroundColor: AppStyles.backgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppStyles.primaryColor,
            primary: AppStyles.primaryColor,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
              backgroundColor: AppStyles.primaryColor,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontFamily: "Poppins"
                  // fontWeight: FontWeight.bold,
                  ),
              iconTheme: IconThemeData(
                color: Colors.white,
              )),
        ),
        initialRoute: SplashScreen.routeName,
        routes: {
          ...RouteHelper.routes,
          ShareScreen.routeName: (context) => const ShareScreen(),
        });
  }
}
