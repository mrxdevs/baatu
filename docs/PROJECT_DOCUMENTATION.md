# Baatu Platform - Comprehensive System & Architecture Documentation

## 1. Executive Summary & Project Overview

**Baatu** is a modern, cross-platform English language learning and real-time communication application developed by DigiWellie Technology. The platform combines AI-assisted interactive learning (AI Teacher "Nancy", Daily Words, Grammar & Media modules) with real-time peer-to-peer audio/video calling and messaging to provide an immersive language practice ecosystem.

---

## 2. Technology Stack

### 2.1 Frontend (Mobile & Multi-Platform)
- **Core Framework**: Flutter (Dart SDK `^3.6.0`)
- **Supported Targets**: Android (API 21–35+), iOS, Web, macOS, Windows, Linux
- **State Management**: `provider` (^6.1.5) & `ChangeNotifier`
- **UI & Animations**: 
  - `google_fonts` (Typography)
  - `flutter_svg`, `cached_network_image`, `shimmer` (Asset & Image optimization)
  - `lottie`, `animated_text_kit`, `avatar_glow` (Micro-interactions & AI voice animations)
  - `flutter_markdown` (AI response formatting)
- **Real-time Media & Audio**:
  - `agora_rtc_engine` (^6.5.3) for Voice/Video Call RTC streams
  - `audioplayers` (^6.5.1), `video_player` (^2.8.2), `chewie` (^1.7.4)
  - `speech_to_text` (^7.0.0) & `flutter_tts` (^4.2.0) for conversational AI
- **Networking & Persistence**:
  - `http`, `flutter_dotenv`
  - `shared_preferences` (Local key-value storage)
- **Device & System Integrations**:
  - `flutter_contacts`, `image_picker`, `permission_handler`, `share_plus`, `url_launcher`, `package_info_plus`

### 2.2 Backend & Cloud Infrastructure
- **API Runtime**: Go (Golang 1.21+) REST API Microservice
- **Primary Database**: PostgreSQL 15+ (Relational data, User accounts, Profiles, Daily Vocabulary, Call history)
- **Firebase Ecosystem**:
  - Firebase Authentication (Email/Password & Google Sign-In)
  - Cloud Firestore (Real-time user status, chat sessions, dynamic sync)
  - Firebase Cloud Messaging (FCM) & `flutter_local_notifications` (Push alerts)
  - Firebase App Check & Firebase Storage
- **AI & LLM Services**:
  - Google Gemini (`gemini-2.0-flash` via Generative Language API) with custom conversational persona prompts
  - DeepSeek API (Alternative LLM reasoning provider)
- **External Communications & Storage**:
  - **Agora RTC / Chat Engine**: Real-time voice/video channels and peer matching
  - **Zepto Mail (Zoho)**: Transactional email verification and OTP password recovery
  - **AWS S3**: Cloud storage for profile avatars and user media

---

## 3. High-Level System Architecture

```mermaid
graph TB
    subgraph Client ["Client Layer (Flutter Cross-Platform)"]
        UI["UI Screens & Widgets"]
        SM["State Management (Provider)"]
        STT_TTS["Speech-to-Text & TTS Engine"]
        AgoraClient["Agora RTC Engine"]
        FCMClient["FCM Notification Handler"]
    end

    subgraph Gateway ["Backend & Third-Party Gateways"]
        GoAPI["Baatu Go REST API (:8080)"]
        FirebaseGateway["Firebase Services (Auth / Firestore / FCM)"]
        GeminiGateway["Google Gemini 2.0 Flash API"]
        AgoraCloud["Agora Real-Time Network"]
        ZeptoGateway["Zepto Mail SMTP / API"]
        S3Gateway["AWS S3 Bucket"]
    end

    subgraph DataStore ["Persistence Layer"]
        PG["PostgreSQL Database"]
        FirestoreDB["Cloud Firestore Collections"]
    end

    UI --> SM
    SM --> STT_TTS
    SM --> GoAPI
    SM --> FirebaseGateway
    SM --> GeminiGateway
    AgoraClient --> AgoraCloud
    FCMClient --> FirebaseGateway

    GoAPI --> PG
    GoAPI --> ZeptoGateway
    GoAPI --> S3Gateway
    FirebaseGateway --> FirestoreDB
```

---

## 4. Application Architecture & Folder Structure

```
baatu/
├── android/                    # Native Android configurations, Gradle scripts & manifests
├── ios/                        # Native iOS workspace, Podfiles, Info.plist
├── assets/                     # Lottie animations, SVG icons, imagery, audio clips
├── docs/                       # Project specifications, OpenAPI schemas & backend docs
│   └── backend/docs/
│       ├── API_DOCUMENTATION.md
│       ├── PHASE2_API.md
│       ├── PHASE3_API.md
│       └── openapi.json
├── firestore.rules             # Cloud Firestore security rules
├── lib/
│   ├── main.dart               # App entrypoint, dotenv initialization, Provider tree
│   ├── core/
│   │   └── config/             # Environment configs (EnvConfig helper)
│   ├── methods/                # Common helper routines
│   ├── model/                  # Domain models (DailyWord, UserDetails, VideoModel, etc.)
│   ├── screens/                # UI Presentation Layer
│   │   ├── auth/               # Login, Register, Forgot Password, OTP screens
│   │   ├── sections/           # Feature screens:
│   │   │   ├── ai_teacher.dart          # AI Teacher 'Nancy' (Gemini Voice/Text Chat)
│   │   │   ├── words_of_the_day_screen.dart # Daily vocabulary cards
│   │   │   ├── word_detail_screen.dart  # Detailed word breakdown & phonetics
│   │   │   ├── videos_screen.dart       # Video lesson library
│   │   │   ├── video_player_screen.dart # Custom Chewie/Video Player
│   │   │   ├── grammar_screen.dart      # Grammar guides
│   │   │   └── music_screen.dart        # English learning via music
│   │   ├── call_screen.dart             # Real-time Voice Call session screen
│   │   ├── chat_screen.dart             # Real-time messaging screen
│   │   ├── chat_connection_screen.dart  # Peer discovery & connection queue
│   │   ├── profile_screen.dart          # User profile, statistics, streaks
│   │   ├── edit_profile_screen.dart     # Avatar upload & profile details editor
│   │   ├── settings_screen.dart         # Preferences, theme, language config
│   │   ├── news_screen.dart             # English news & reading articles
│   │   ├── share_screen.dart            # Referral & social sharing
│   │   └── splash_screen.dart           # App startup & authentication router
│   ├── services/               # Infrastructure & Business Logic Layer
│   │   ├── auth_service.dart            # Firebase Auth & session management
│   │   ├── google_sign_in.dart          # Google OAuth provider integration
│   │   ├── gemini_service.dart          # Gemini 2.0 Flash prompt engine & persona
│   │   ├── deepseek_service.dart        # DeepSeek API integration
│   │   ├── daily_words_service.dart     # Vocabulary API consumption & caching
│   │   ├── word_service.dart            # Offline/Mock vocabulary provider
│   │   ├── database_service.dart        # Firestore data mutations & queries
│   │   └── notification_service.dart    # FCM & Local push notification manager
│   ├── testing_console/        # Dev/debug screens & diagnostics
│   └── utils/                  # Color palettes, theme styles, text validators
└── pubspec.yaml                # Project package dependencies and assets
```

---

## 5. Core Feature Modules

### 5.1 AI Teacher "Nancy" (Interactive Conversational AI)
- **Engine**: Gemini 2.0 Flash via REST API with tailored system prompts created by DigiWellie Technology.
- **Multimodal Interaction**:
  - Real-time speech recognition using `speech_to_text` with visual microphone pulse (`avatar_glow`).
  - Text-to-Speech playback using `flutter_tts`.
  - Gentle grammar & syntax correction in conversational context.
  - Markdown-rendered responses with pronunciation keys, explanations, and follow-up queries.

### 5.2 Daily Vocabulary & Word of the Day
- **Structure**: 10 daily words curated per day plus a dedicated "Word of the Day".
- **Details**: Part of speech, CEFR difficulty level (`beginner`, `intermediate`, `advanced`), definitions, example sentences, synonyms, antonyms, and user-saved bookmarks.
- **Fallback**: Offline mock data fallback when network connectivity is disrupted.

### 5.3 Peer-to-Peer Voice Calls & Real-Time Matchmaking
- **Matchmaking Engine**: Queue-based pairing matching users by target language, native language, and proficiency level.
- **Media Engine**: Agora RTC SDK for low-latency, clear audio streams with mute/unmute, speakerphone toggle, in-call duration timers, and call rating analytics.

### 5.4 Multimedia Learning (Videos, Grammar & Audio)
- Custom video playback (`chewie` & `video_player`) featuring English video lessons and listening exercises.
- Music-assisted English comprehension with audio player streams.

### 5.5 User Profile, Gamification & Streaks
- Tracks daily practice streaks (`current_streak`, `longest_streak`), total minutes spent on voice practice, total completed calls, and custom learning targets.

---

## 6. Complete Backend REST API Reference

Base Server URL: `http://localhost:8080` (or configured `API_BASE_URL`)

### 6.1 System & Health Endpoints
| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | None | Returns service health status and API version |

---

### 6.2 Authentication & Account Management
| Method | Endpoint | Auth | Request Body | Description |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register` | None | `{email, password, name}` | Register new account and send email verification |
| `POST` | `/api/v1/auth/login` | None | `{email, password}` | Log in and receive JWT bearer token |
| `POST` | `/api/v1/auth/google` | None | `{id_token, google_id, email, name}` | Authenticate via Google OAuth token |
| `POST` | `/api/v1/auth/verify-email`| None | `{token}` | Verify user email with verification link token |
| `POST` | `/api/v1/auth/forgot-password` | None | `{email}` | Generate and dispatch 6-digit password reset OTP |
| `POST` | `/api/v1/auth/verify-otp` | None | `{email, otp}` | Verify correctness of OTP before resetting |
| `POST` | `/api/v1/auth/reset-password` | None | `{email, otp, new_password}` | Update account password using verified OTP |

---

### 6.3 User Profile Endpoints
| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/users/profile` | Bearer JWT | — | Fetch current user's profile, learning stats & streaks |
| `PUT` | `/api/v1/users/profile` | Bearer JWT | `{bio, skill_level, native_language, learning_language, interests, ...}` | Update profile details |
| `POST` | `/api/v1/users/avatar` | Bearer JWT | `multipart/form-data (avatar file)` | Upload new profile photo to AWS S3 |
| `POST` | `/api/v1/users/resend-verification` | Bearer JWT | — | Resend account verification email via Zepto Mail |
| `DELETE`| `/api/v1/users` | Bearer JWT | — | Permanently delete user account and profile |

---

### 6.4 Vocabulary & Daily Words Endpoints
| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/words/daily` | None / Bearer | `?date=YYYY-MM-DD` | Retrieve today's 10 vocabulary words |
| `GET` | `/api/v1/words/today` | None / Bearer | — | Retrieve the featured "Word of the Day" |
| `GET` | `/api/v1/words/:id` | None / Bearer | `id` in URL path | Fetch full metadata for a specific word |
| `POST` | `/api/v1/words/:id/save` | Bearer JWT | `id` in URL path | Bookmark/save a word to user's saved list |
| `GET` | `/api/v1/words/saved` | Bearer JWT | — | Get all words bookmarked by current user |

---

### 6.5 Voice Call Matching & Session Endpoints
| Method | Endpoint | Auth | Request Body / Params | Description |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/calls/queue` | Bearer JWT | `{skill_level, gender_preference, age_preference}` | Join the active matchmaking queue |
| `DELETE`| `/api/v1/calls/queue` | Bearer JWT | — | Cancel queue search and leave matching pool |
| `GET` | `/api/v1/calls/match` | Bearer JWT | — | Poll for a discovered conversation partner match |
| `POST` | `/api/v1/calls/start` | Bearer JWT | `{callee_id}` | Initiate RTC call channel with matched partner |
| `POST` | `/api/v1/calls/end` | Bearer JWT | `{call_id, duration_seconds}` | Terminate call and record duration stats |
| `POST` | `/api/v1/calls/:id/rate`| Bearer JWT | `{rating, feedback}` | Submit partner rating and feedback |

---

## 7. Database Schemas

### 7.1 PostgreSQL Schema
```sql
-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    auth_provider VARCHAR(20) DEFAULT 'email',
    google_id VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    verification_token VARCHAR(255),
    verification_expires TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Profiles Table
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT,
    avatar_url TEXT,
    native_language VARCHAR(10) DEFAULT 'hi',
    learning_language VARCHAR(10) DEFAULT 'en',
    skill_level VARCHAR(20) DEFAULT 'beginner',
    interests TEXT[],
    is_premium BOOLEAN DEFAULT FALSE,
    total_calls INTEGER DEFAULT 0,
    total_minutes INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 7.2 Cloud Firestore Structure
- `users/{userId}`: Real-time status, presence, settings, device tokens.
- `chats/{chatId}`: Direct messages, timestamps, read receipts.
- `calls/{callSessionId}`: Live call signaling states, channel tokens.

---

## 8. Security & Environment Configuration

### 8.1 Client `.env` Keys
```env
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...

AGORA_APP_ID=...
AGORA_PROJECT_NAME=...
AGORA_PRIMARY_CERTI=...
AGORA_APP_KEY=...

API_BASE_URL=http://localhost:8080
GEMINI_API_KEY=...
```

### 8.2 Backend `.env` Keys
```env
PORT=8080
DATABASE_URL=postgres://baatu:baatu123@localhost:5432/baatu?sslmode=disable
JWT_SECRET=your-secure-secret-key
JWT_EXPIRY=24h

ZEPTO_API_KEY=PHtE6r...
ZEPTO_FROM_EMAIL=noreply@baatu.app
ZEPTO_FROM_NAME=Baatu

AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET=baatu-avatars
```
