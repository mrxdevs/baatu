# 🔐 .env Quick Reference

## Setup Checklist
- [x] `flutter_dotenv` package added to `pubspec.yaml`
- [x] `.env` file created in project root
- [x] `.env` added to assets in `pubspec.yaml`
- [x] `.env` file is gitignored
- [x] `dotenv.load()` called in `main.dart`
- [x] `EnvConfig` helper class created

## Quick Commands

```bash
# Install dependencies
flutter pub get

# Create your .env file from template
cp .env.example .env

# Edit your .env file
nano .env  # or use your preferred editor
```

## Common Usage Patterns

### 1. Access Firebase Config
```dart
import 'package:baatu/core/config/env_config.dart';

String apiKey = EnvConfig.firebaseApiKey;
String projectId = EnvConfig.firebaseProjectId;
```

### 2. Access Agora Config
```dart
String agoraId = EnvConfig.agoraAppId;
```

### 3. Access Custom Variables
```dart
String value = EnvConfig.getEnv('MY_CUSTOM_KEY', defaultValue: 'default');
```

### 4. Validate Configuration
```dart
if (!EnvConfig.isConfigured) {
  throw Exception('Environment not properly configured!');
}
```

## File Locations

| File                  | Path                                     | Purpose                          |
| --------------------- | ---------------------------------------- | -------------------------------- |
| Environment Variables | `.env`                                   | Your actual secrets (gitignored) |
| Template              | `.env.example`                           | Template for team (committed)    |
| Helper Class          | `lib/core/config/env_config.dart`        | Access variables                 |
| Documentation         | `ENV_SETUP.md`                           | Full guide                       |
| Example Usage         | `lib/core/config/env_usage_example.dart` | Code examples                    |

## Security Reminders

✅ **DO:**
- Keep `.env` in `.gitignore`
- Use `.env.example` as template
- Rotate keys regularly
- Use different keys for dev/prod

❌ **DON'T:**
- Commit `.env` to Git
- Share secrets in chat/email
- Hardcode secrets in code
- Log sensitive values

## Need Help?

See [ENV_SETUP.md](./ENV_SETUP.md) for detailed documentation.
