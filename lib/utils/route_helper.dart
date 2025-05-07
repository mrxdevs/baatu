import 'package:baatu/screens/auth/learning_preferences_screen.dart';
import 'package:baatu/screens/auth/login_screen.dart';
import 'package:baatu/screens/auth/otp_verification_screen.dart';
import 'package:baatu/screens/auth/register_screen.dart';
import 'package:baatu/screens/auth/success_screen.dart';
import 'package:baatu/screens/call_screen.dart';
import 'package:baatu/screens/chat_connection_screen.dart';
import 'package:baatu/screens/chat_screen.dart';
import 'package:baatu/screens/navigation_home_bar.dart';
import 'package:baatu/screens/news_screen.dart';
import 'package:baatu/screens/profile_screen.dart';
import 'package:baatu/screens/chat_screen.dart';
import 'package:baatu/screens/sections/grammar_screen.dart';
import 'package:baatu/screens/sections/music_screen.dart';
import 'package:baatu/screens/sections/videos_screen.dart';
import 'package:baatu/screens/sections/words_screen.dart';
import 'package:baatu/screens/settings_screen.dart';
import 'package:baatu/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class RouteHelper {
  Map<String, Widget Function(BuildContext)> routes = {
    SplashScreen.routeName: (context) => const SplashScreen(),
    LoginScreen.routeName: (context) => const LoginScreen(),
    RegisterScreen.routeName: (context) => const RegisterScreen(),
    HomeNavigationScreen.routeName: (context) => const HomeNavigationScreen(),
    LearningPreferencesScreen.routeName: (context) => const LearningPreferencesScreen(),
    OtpVerificationScreen.routeName: (context) => const OtpVerificationScreen(),
    SuccessScreen.routeName: (context) => const SuccessScreen(),
    ChatConnectionScreen.routeName: (context) => const ChatConnectionScreen(),
    GrammarScreen.routeName: (context) => const GrammarScreen(),
    MusicScreen.routeName: (context) => const MusicScreen(),
    NewsScreen.routeName: (context) => const NewsScreen(),
    ProfileScreen.routeName: (context) => const ProfileScreen(),
    SettingsScreen.routeName: (context) => const SettingsScreen(),
    VideosScreen.routeName: (context) => const VideosScreen(),
    WordsScreen.routeName: (context) => const WordsScreen(),
    ChatScreen.routeName: (context) => const ChatScreen(),
    CallScreen.routeName: (context) => const CallScreen(callingWith: "",),
    

    
  };

}