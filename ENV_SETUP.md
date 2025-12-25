# Environment Variables Configuration Guide

This guide explains how to use `.env` files to keep your secret keys and configuration secure in the Baatu Flutter project.

## 📋 Overview

The project uses `flutter_dotenv` package to manage environment variables. All sensitive information like API keys, Firebase credentials, and other secrets are stored in a `.env` file that is **NOT committed to Git**.

## 🔧 Setup

### 1. Configuration Files

- **`.env`** - Contains your actual secret keys (already in `.gitignore`)
- **`lib/core/config/env_config.dart`** - Helper class to access environment variables

### 2. How It Works

1. Environment variables are loaded at app startup in `main.dart`
2. Access them anywhere in your app using the `EnvConfig` class
3. The `.env` file is excluded from version control for security

## 📝 Usage Examples

### Adding Variables to .env

Edit the `.env` file in the project root:

```env
# Firebase Configuration
FIREBASE_API_KEY=AIzaSyC...your_actual_key
FIREBASE_APP_ID=1:123456789:android:abc123
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com

# Agora Configuration
AGORA_APP_ID=your_agora_app_id

# API Keys
API_BASE_URL=https://api.yourapp.com
```

### Accessing Variables in Code

```dart
import 'package:baatu/core/config/env_config.dart';

// Access predefined variables
String apiKey = EnvConfig.firebaseApiKey;
String agoraId = EnvConfig.agoraAppId;

// Access custom variables
String customValue = EnvConfig.getEnv('CUSTOM_KEY', defaultValue: 'fallback');

// Check if configuration is loaded
if (EnvConfig.isConfigured) {
  // All required variables are present
}
```

### Example: Using in Firebase Initialization

```dart
import 'package:baatu/core/config/env_config.dart';

FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: EnvConfig.firebaseApiKey,
  appId: EnvConfig.firebaseAppId,
  messagingSenderId: EnvConfig.firebaseMessagingSenderId,
  projectId: EnvConfig.firebaseProjectId,
  storageBucket: EnvConfig.firebaseStorageBucket,
);
```

## 🔒 Security Best Practices

1. **Never commit `.env` files** - Already configured in `.gitignore`
2. **Use different `.env` files for different environments** (dev, staging, production)
3. **Share `.env.example` with your team** - Template without actual secrets
4. **Rotate keys regularly** - Update secrets periodically
5. **Use environment-specific values** - Different keys for dev/prod

## 📂 File Structure

```
baatu/
├── .env                          # Your secret keys (gitignored)
├── .env.example                  # Template file (safe to commit)
├── lib/
│   └── core/
│       └── config/
│           └── env_config.dart   # Helper class to access variables
└── pubspec.yaml                  # flutter_dotenv dependency
```

## 🚀 Deployment

### For Team Members

1. Copy `.env.example` to `.env`
2. Ask team lead for actual secret values
3. Fill in your `.env` file with real credentials

### For Production

1. Create a production `.env` file with production credentials
2. Ensure it's included in your build process
3. Never expose production keys in logs or error messages

## 🛠️ Troubleshooting

### Error: "Unable to load asset: .env"

**Solution:** Make sure `.env` is listed in `pubspec.yaml` under assets:
```yaml
flutter:
  assets:
    - .env
```

### Error: "dotenv is not initialized"

**Solution:** Ensure `dotenv.load()` is called in `main()` before using any env variables.

### Empty values returned

**Solution:** 
1. Check that your `.env` file exists in the project root
2. Verify variable names match exactly (case-sensitive)
3. Run `flutter clean` and `flutter pub get`

## 📌 Additional Tips

- Use descriptive variable names in UPPER_SNAKE_CASE
- Group related variables with comments
- Document required variables in `.env.example`
- Add validation in `EnvConfig.isConfigured` for critical variables

## 🔗 Resources

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)
- [Environment Variables Best Practices](https://12factor.net/config)
