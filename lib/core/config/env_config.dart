import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class to access .env variables
class EnvConfig {
  //google API key
  static String get googleApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Agora Configuration
  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get agoraProjectName => dotenv.env['AGORA_PROJECT_NAME'] ?? '';
  static String get agoraPrimaryCertificate => dotenv.env['AGORA_PRIMARY_CERTI'] ?? '';
  static String get agoraSecondaryCertificate => dotenv.env['AGORA_SECONDARY_CERTI'] ?? '';
  static String get agoraAppKey => dotenv.env['AGORA_APP_KEY'] ?? '';
  static String get agoraOrgName => dotenv.env['AGORA_ORG_NAME'] ?? '';
  static String get agoraName => dotenv.env['AGORA_NAME'] ?? '';
  static String get agoraWebSocketAddress => dotenv.env['AGORA_WEB_SOCKET_ADDRESS'] ?? '';
  static String get agoraChatId => dotenv.env['AGORA_CHAT_ID'] ?? '';

  /// Get any custom environment variable
  static String getEnv(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }
}
