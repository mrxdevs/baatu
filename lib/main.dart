import 'package:baatu/utils/app_config.dart';
import 'package:baatu/utils/get_package_details.dart';
import 'package:baatu/utils/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_styles.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: true
  //       ? AndroidProvider.debug
  //       : AndroidProvider.playIntegrity,
  //  appleProvider: AppleProvider.debug
  // );
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
              titleTextStyle: TextStyle(
                  color: Colors.white, fontSize: 20, fontFamily: "Poppins"
                  // fontWeight: FontWeight.bold,
                  ),
              iconTheme: IconThemeData(
                color: Colors.white,
              )),
        ),
        initialRoute: SplashScreen.routeName,
        routes: RouteHelper.routes);
  }
}
