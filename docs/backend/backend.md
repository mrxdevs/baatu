# Baatu Backend API Documentation

## Overview

Baatu Backend is a GoLang REST API for the Baatu English learning app. It provides authentication, user management, and profile features.

**Base URL:** `http://localhost:8080`

---

## Quick Start

### Prerequisites
- Go 1.21+
- PostgreSQL 15+
- Docker (optional)

### 1. Start PostgreSQL Database

**Option A: Docker (Recommended)**
```bash
docker run -d --name baatu-db \
  -e POSTGRES_USER=baatu \
  -e POSTGRES_PASSWORD=baatu123 \
  -e POSTGRES_DB=baatu \
  -p 5432:5432 postgres:15
```

**Option B: Local PostgreSQL**
```bash
createdb baatu
```

### 2. Run Database Migrations

```bash
# Using Docker PostgreSQL
psql -h localhost -U baatu -d baatu -f migrations/001_create_users.sql
# Password: baatu123

# OR using local PostgreSQL
psql -h localhost -U postgres -d baatu -f migrations/001_create_users.sql
```

### 3. Verify Migration

```bash
# List tables
psql -h localhost -U baatu -d baatu -c "\dt"

# Check users table structure
psql -h localhost -U baatu -d baatu -c "\d users"
```

Expected tables:
- `users` - User authentication data
- `user_profiles` - Extended user profile info

### 4. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values:
```env
PORT=8080
DATABASE_URL=postgres://baatu:baatu123@localhost:5432/baatu?sslmode=disable
JWT_SECRET=your-secure-secret-key
JWT_EXPIRY=24h

# Zepto Mail (for email verification)
ZEPTO_API_KEY=your-zepto-api-key
ZEPTO_FROM_EMAIL=noreply@baatu.app
ZEPTO_FROM_NAME=Baatu

# AWS S3 (for avatars)
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_BUCKET=baatu-avatars
```

### 5. Run the Server

```bash
go run cmd/server/main.go
```

Server starts at `http://localhost:8080`

---

## API Response Format

All API responses follow this structure:

### Success Response
```json
{
  "success": true,
  "message": "Operation description",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message description"
}
```

---

## Endpoints

### Health Check

#### `GET /health`

Check if the server is running.

**Request:**
```bash
curl http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "baatu-api",
  "version": "1.0.0"
}
```

---

## Authentication Endpoints (Public)

### Register New User

#### `POST /api/v1/auth/register`

Create a new user account with email and password.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "MySecurePassword123",
    "name": "John Doe"
  }'
```

**Request Body:**
| Field    | Type   | Required | Description          |
| -------- | ------ | -------- | -------------------- |
| email    | string | Yes      | Valid email address  |
| password | string | Yes      | Minimum 8 characters |
| name     | string | Yes      | User's display name  |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "is_verified": false
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Responses:**
- `400` - Email already exists or invalid data

---

### Login

#### `POST /api/v1/auth/login`

Authenticate with email and password.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "MySecurePassword123"
  }'
```

**Request Body:**
| Field    | Type   | Required | Description      |
| -------- | ------ | -------- | ---------------- |
| email    | string | Yes      | Registered email |
| password | string | Yes      | Account password |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "name": "John Doe",
      "is_verified": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Responses:**
- `401` - Invalid email or password

---

### Google OAuth

#### `POST /api/v1/auth/google`

Authenticate via Google Sign-In (from Flutter app).

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "google-id-token-from-flutter",
    "google_id": "google-user-id",
    "email": "user@gmail.com",
    "name": "John Doe"
  }'
```

**Request Body:**
| Field     | Type   | Required | Description          |
| --------- | ------ | -------- | -------------------- |
| id_token  | string | Yes      | Google ID token      |
| google_id | string | Yes      | Google user ID       |
| email     | string | Yes      | Google account email |
| name      | string | Yes      | Google account name  |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Google authentication successful",
  "data": {
    "user": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### Verify Email

#### `POST /api/v1/auth/verify-email`

Verify email with token sent to user's email.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/verify-email \
  -H "Content-Type: application/json" \
  -d '{
    "token": "verification-token-from-email"
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Email verified successfully",
  "data": null
}
```

---

### Forgot Password (OTP)

#### `POST /api/v1/auth/forgot-password`

Request a 6-digit OTP to reset password.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "If an account exists, an OTP has been sent to your email",
  "data": null
}
```

---

#### `POST /api/v1/auth/verify-otp`

Verify the OTP is valid (optional step).

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "otp": "123456"}'
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": null
}
```

---

#### `POST /api/v1/auth/reset-password`

Reset password using OTP.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "otp": "123456",
    "new_password": "NewSecurePassword123"
  }'
```

**Request Body:**
| Field        | Type   | Required | Description                |
| ------------ | ------ | -------- | -------------------------- |
| email        | string | Yes      | Account email              |
| otp          | string | Yes      | 6-digit OTP from email     |
| new_password | string | Yes      | New password (min 8 chars) |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password reset successful",
  "data": null
}
```

---

## Daily Words Endpoints

### Get Daily Words

#### `GET /api/v1/words/daily`

Get today's vocabulary words (10 words).

**Request:**
```bash
curl http://localhost:8080/api/v1/words/daily
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Daily words retrieved",
  "data": {
    "date": "2026-01-14",
    "word_of_day": {
      "id": 1,
      "word": "eloquent",
      "meaning": "Fluent or persuasive in speaking or writing",
      "part_of_speech": "adjective",
      "difficulty_level": "intermediate",
      "example_sentence": "The CEO gave an eloquent speech.",
      "synonyms": ["articulate", "fluent", "expressive"],
      "antonyms": ["inarticulate", "hesitant"]
    },
    "words": [...],
    "total_words": 10
  }
}
```

---

### Get Word of the Day

#### `GET /api/v1/words/today`

Get today's featured word.

**Request:**
```bash
curl http://localhost:8080/api/v1/words/today
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Word of the day",
  "data": {
    "id": 1,
    "word": "eloquent",
    "meaning": "Fluent or persuasive in speaking or writing",
    "synonyms": ["articulate", "fluent"],
    "antonyms": ["inarticulate"]
  }
}
```

---

### Get Word Details

#### `GET /api/v1/words/:id`

Get detailed information about a word.

**Request:**
```bash
curl http://localhost:8080/api/v1/words/1
```

---

### Save Word (Protected)

#### `POST /api/v1/words/:id/save`

Save a word to your collection.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/words/1/save \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### Get Saved Words (Protected)

#### `GET /api/v1/words/saved`

Get all words saved by the user.

**Request:**
```bash
curl http://localhost:8080/api/v1/words/saved \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## User Endpoints (Protected)

> **Note:** All user endpoints require authentication. Include the JWT token in the Authorization header:
> ```
> Authorization: Bearer <your-jwt-token>
> ```

---

### Get Profile

#### `GET /api/v1/users/profile`

Get the current user's profile.

**Request:**
```bash
curl http://localhost:8080/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profile retrieved",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe",
    "bio": "Learning English!",
    "avatar_url": "https://s3.amazonaws.com/baatu/avatar.jpg",
    "native_language": "hi",
    "learning_language": "en",
    "skill_level": "intermediate",
    "interests": ["movies", "music", "travel"],
    "is_premium": false,
    "total_calls": 10,
    "total_minutes": 45,
    "current_streak": 5,
    "longest_streak": 12
  }
}
```

---

### Update Profile

#### `PUT /api/v1/users/profile`

Update user profile information.

**Request:**
```bash
curl -X PUT http://localhost:8080/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bio": "Love learning new languages!",
    "skill_level": "intermediate",
    "native_language": "hi",
    "interests": ["movies", "music", "travel"]
  }'
```

**Request Body (all fields optional):**
| Field             | Type     | Description                            |
| ----------------- | -------- | -------------------------------------- |
| bio               | string   | User bio/description                   |
| skill_level       | string   | `beginner`, `intermediate`, `advanced` |
| native_language   | string   | ISO language code (e.g., `hi`, `en`)   |
| learning_language | string   | ISO language code                      |
| age_range         | string   | Age range (e.g., `18-25`, `26-35`)     |
| gender            | string   | Gender                                 |
| location          | string   | Location                               |
| timezone          | string   | Timezone (e.g., `Asia/Kolkata`)        |
| interests         | string[] | Array of interests                     |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profile updated",
  "data": { ... }
}
```

---

### Upload Avatar

#### `POST /api/v1/users/avatar`

Upload a profile picture.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/users/avatar \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "avatar=@/path/to/image.jpg"
```

**Form Data:**
| Field  | Type | Required | Description          |
| ------ | ---- | -------- | -------------------- |
| avatar | file | Yes      | Image file (max 5MB) |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Avatar updated",
  "data": {
    "avatar_url": "https://s3.amazonaws.com/baatu/avatar.jpg"
  }
}
```

---

### Resend Verification Email

#### `POST /api/v1/users/resend-verification`

Resend the email verification link.

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/users/resend-verification \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Verification email sent",
  "data": null
}
```

---

### Delete Account

#### `DELETE /api/v1/users`

Permanently delete user account.

**Request:**
```bash
curl -X DELETE http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully",
  "data": null
}
```

---

## Flutter Integration

### Setup Dio Client

```dart
import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8080';
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));
  
  // Set auth token after login
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _dio.post('/api/v1/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    return response.data;
  }
  
  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }
  
  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/v1/users/profile');
    return response.data;
  }
  
  // Update Profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/v1/users/profile', data: data);
    return response.data;
  }
}
```

### Usage Example

```dart
final api = ApiClient();

// Register new user
final registerResult = await api.register(
  email: 'user@example.com',
  password: 'MyPassword123',
  name: 'John Doe',
);
final token = registerResult['data']['token'];
api.setAuthToken(token);

// Get profile
final profile = await api.getProfile();
print(profile['data']['name']); // John Doe

// Update profile
await api.updateProfile({
  'bio': 'Learning English daily!',
  'skill_level': 'intermediate',
  'interests': ['movies', 'music'],
});
```

---

## Database Schema

### Users Table

| Column               | Type         | Description               |
| -------------------- | ------------ | ------------------------- |
| id                   | UUID         | Primary key               |
| email                | VARCHAR(255) | Unique email address      |
| password_hash        | VARCHAR(255) | Bcrypt hashed password    |
| name                 | VARCHAR(100) | Display name              |
| auth_provider        | VARCHAR(20)  | `email` or `google`       |
| google_id            | VARCHAR(255) | Google user ID (if OAuth) |
| is_verified          | BOOLEAN      | Email verification status |
| is_active            | BOOLEAN      | Account active status     |
| verification_token   | VARCHAR(255) | Email verification token  |
| verification_expires | TIMESTAMP    | Token expiry time         |
| created_at           | TIMESTAMP    | Account creation time     |
| updated_at           | TIMESTAMP    | Last update time          |

### User Profiles Table

| Column            | Type        | Description                    |
| ----------------- | ----------- | ------------------------------ |
| id                | UUID        | Primary key                    |
| user_id           | UUID        | Foreign key to users           |
| bio               | TEXT        | User biography                 |
| avatar_url        | TEXT        | Profile picture URL            |
| native_language   | VARCHAR(10) | Native language code           |
| learning_language | VARCHAR(10) | Learning language code         |
| skill_level       | VARCHAR(20) | beginner/intermediate/advanced |
| interests         | TEXT[]      | Array of interests             |
| is_premium        | BOOLEAN     | Premium subscription status    |
| total_calls       | INTEGER     | Total practice calls           |
| total_minutes     | INTEGER     | Total practice minutes         |
| current_streak    | INTEGER     | Current day streak             |
| longest_streak    | INTEGER     | Longest day streak             |

---

## Error Codes

| HTTP Code | Description                          |
| --------- | ------------------------------------ |
| 200       | Success                              |
| 201       | Created (new resource)               |
| 400       | Bad Request (validation error)       |
| 401       | Unauthorized (invalid/missing token) |
| 404       | Not Found                            |
| 500       | Internal Server Error                |

---

## Troubleshooting

### Common Issues

**1. 404 on /api/v1**
- This is expected! Use specific endpoints like `/api/v1/auth/login`
- Test with `/health` first to verify server is running

**2. Database connection failed**
- Check PostgreSQL is running: `docker ps` or `pg_isready`
- Verify DATABASE_URL in `.env` matches your setup

**3. "relation does not exist" error**
- Run migrations: `psql -h localhost -U baatu -d baatu -f migrations/001_create_users.sql`

**4. JWT errors**
- Ensure JWT_SECRET is set in `.env`
- Token expires after JWT_EXPIRY (default 24h)

**5. Email not sending**
- Check `ZEPTO_API_KEY` is correctly set (see Email Service section)
- Verify sender domain is configured in Zepto Mail dashboard

---

## Email Service

Baatu uses [Zepto Mail](https://www.zoho.com/zeptomail/) for transactional emails.

### Configuration

Add these to your `.env`:

```env
# Zepto Mail Configuration
ZEPTO_API_KEY=PHtE6r1JF...your-zepto-token...
ZEPTO_FROM_EMAIL=noreply@yourdomain.com
ZEPTO_FROM_NAME=Baatu
```

### Getting Your Zepto API Key

1. Go to [Zepto Mail Console](https://mail.zoho.com/biz/zeptomail)
2. Navigate to **Email Sending** → **Send Mail API**
3. Copy the **Send Mail Token** (starts with `PHtE6r...`)
4. Paste it as `ZEPTO_API_KEY` in `.env`

> **Important:** The `ZEPTO_FROM_EMAIL` domain must be verified in your Zepto Mail dashboard.

### Email Templates

Baatu sends the following transactional emails:

#### 1. Email Verification

**Triggered:** After user registration via `/api/v1/auth/register`

**Subject:** `Verify your Baatu account ✉️`

**Template Features:**
- Welcome message with user's name
- Green CTA button to verify email
- Fallback link in styled box
- 24-hour expiry notice
- Baatu branding with #0dcdaa green theme

**Sample Email Content:**
```
Welcome to Baatu! 🎉

Hi {name},

Thank you for joining Baatu – your journey to speaking 
English with confidence starts now!

Please verify your email address by clicking the button below:

[✉️ Verify Email Address]

🔗 Or copy this link:
https://yourapp.com/verify-email?token=xxxxx

⏰ Important:
This verification link will expire in 24 hours.
```

#### 2. Password Reset

**Triggered:** When password reset is requested

**Subject:** `Reset your Baatu password 🔐`

**Template Features:**
- Password reset CTA button
- 1-hour expiry notice
- Security warning box
- Baatu branding

**Sample Email Content:**
```
Password Reset Request 🔐

Hi {name},

We received a request to reset your password for your 
Baatu account. Click the button below to create a new password:

[🔑 Reset Password]

⏰ Important:
This reset link will expire in 1 hour.

⚠️ Security Tip: Never share your password or this reset 
link with anyone. Baatu will never ask for your password via email.
```

### Email API Endpoints

| Endpoint                            | Method | Description         | Email Sent           |
| ----------------------------------- | ------ | ------------------- | -------------------- |
| `/api/v1/auth/register`             | POST   | Register user       | Verification email   |
| `/api/v1/users/resend-verification` | POST   | Resend verification | Verification email   |
| `/api/v1/auth/forgot-password`      | POST   | Request reset       | Password reset email |

### Testing Email Locally

1. Set up Zepto Mail account with verified domain
2. Configure `.env` with API key
3. Register a test user:
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email@gmail.com", "password": "Test1234", "name": "Test"}'
```
4. Check your inbox for the verification email

### Email Troubleshooting

**Email not received:**
- Check spam/junk folder
- Verify `ZEPTO_API_KEY` is correct (not a JWT token)
- Check server logs for `✅ Email sent` or `❌ Zepto API error`

**401 Invalid API Token:**
- The API key format is incorrect
- Get a fresh token from Zepto Mail dashboard
- Ensure no extra spaces or characters in `.env`

**Sender not authorized:**
- Verify your sender domain in Zepto Mail
- `ZEPTO_FROM_EMAIL` must use a verified domain

---

## License

MIT
# Baatu API - Phase 2 Features

## Password Reset OTP API

### Request OTP

**`POST /api/v1/auth/forgot-password`**

Request a 6-digit OTP for password reset.

```bash
curl -X POST http://localhost:8080/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

| Field | Type   | Required | Description   |
| ----- | ------ | -------- | ------------- |
| email | string | Yes      | Account email |

**Response:** `{"success": true, "message": "If an account exists, an OTP has been sent"}`

---

### Verify OTP

**`POST /api/v1/auth/verify-otp`**

Optional: Check if OTP is valid before resetting.

```bash
curl -X POST http://localhost:8080/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "otp": "123456"}'
```

| Field | Type   | Required | Description            |
| ----- | ------ | -------- | ---------------------- |
| email | string | Yes      | Account email          |
| otp   | string | Yes      | 6-digit OTP from email |

---

### Reset Password

**`POST /api/v1/auth/reset-password`**

Reset password using OTP.

```bash
curl -X POST http://localhost:8080/api/v1/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "otp": "123456",
    "new_password": "NewSecurePass123"
  }'
```

| Field        | Type   | Required | Description                |
| ------------ | ------ | -------- | -------------------------- |
| email        | string | Yes      | Account email              |
| otp          | string | Yes      | 6-digit OTP                |
| new_password | string | Yes      | New password (min 8 chars) |

---

## Daily Words API

### Get Daily Words

**`GET /api/v1/words/daily`**

Returns today's 10 vocabulary words.

```bash
curl http://localhost:8080/api/v1/words/daily
```

**Response:**
```json
{
  "success": true,
  "data": {
    "date": "2026-01-14",
    "word_of_day": {...},
    "words": [
      {
        "id": 1,
        "word": "eloquent",
        "meaning": "Fluent or persuasive in speaking",
        "part_of_speech": "adjective",
        "difficulty_level": "intermediate",
        "example_sentence": "She gave an eloquent speech.",
        "synonyms": ["articulate", "fluent"],
        "antonyms": ["inarticulate"]
      }
    ],
    "total_words": 10
  }
}
```

---

### Get Word of the Day

**`GET /api/v1/words/today`**

Returns today's featured word.

```bash
curl http://localhost:8080/api/v1/words/today
```

---

### Get Word Details

**`GET /api/v1/words/:id`**

Get detailed info about a specific word.

```bash
curl http://localhost:8080/api/v1/words/1
```

---

### Save Word *(Protected)*

**`POST /api/v1/words/:id/save`**

Save a word to your collection.

```bash
curl -X POST http://localhost:8080/api/v1/words/1/save \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### Remove Saved Word *(Protected)*

**`DELETE /api/v1/words/:id/save`**

Remove a word from your collection.

```bash
curl -X DELETE http://localhost:8080/api/v1/words/1/save \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### Get Saved Words *(Protected)*

**`GET /api/v1/words/saved`**

Get all words saved by the user.

```bash
curl http://localhost:8080/api/v1/words/saved \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### Mark Word Learned *(Protected)*

**`POST /api/v1/words/:id/learned`**

Mark a saved word as learned.

```bash
curl -X POST http://localhost:8080/api/v1/words/1/learned \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Database Migration

Run before using Daily Words API:

```bash
psql -h localhost -U postgres -d baatu -f migrations/002_create_words.sql
```

---

## Word Data Model

```json
{
  "id": 1,
  "word": "eloquent",
  "meaning": "Fluent or persuasive in speaking or writing",
  "pronunciation_url": null,
  "part_of_speech": "adjective",
  "difficulty_level": "intermediate",
  "example_sentence": "The CEO gave an eloquent speech at the conference.",
  "synonyms": ["articulate", "fluent", "expressive"],
  "antonyms": ["inarticulate", "hesitant"],
  "created_at": "2026-01-14T10:00:00Z"
}
```

---

# Voice Call Matching API

## Call Queue

### Join Matching Queue *(Protected)*

**`POST /api/v1/calls/queue`**

```bash
curl -X POST http://localhost:8080/api/v1/calls/queue \
  -H "Authorization: Bearer TOKEN" \
  -d '{"skill_level": "intermediate"}'
```

| Field       | Type   | Required | Description                      |
| ----------- | ------ | -------- | -------------------------------- |
| skill_level | string | No       | beginner, intermediate, advanced |

---

### Leave Queue *(Protected)*

**`DELETE /api/v1/calls/queue`**

```bash
curl -X DELETE http://localhost:8080/api/v1/calls/queue \
  -H "Authorization: Bearer TOKEN"
```

---

### Find Match *(Protected)*

**`GET /api/v1/calls/match`**

```bash
curl http://localhost:8080/api/v1/calls/match \
  -H "Authorization: Bearer TOKEN"
```

**Response:**
```json
{
  "found": true,
  "match_id": "uuid",
  "user": {...},
  "profile": {...}
}
```

---

## Call Management

### Start Call *(Protected)*

**`POST /api/v1/calls/start`**

```bash
curl -X POST http://localhost:8080/api/v1/calls/start \
  -H "Authorization: Bearer TOKEN" \
  -d '{"callee_id": "matched-user-uuid"}'
```

---

### End Call *(Protected)*

**`POST /api/v1/calls/end`**

```bash
curl -X POST http://localhost:8080/api/v1/calls/end \
  -H "Authorization: Bearer TOKEN" \
  -d '{"call_id": "call-uuid", "duration_seconds": 300}'
```

---

### Rate Partner *(Protected)*

**`POST /api/v1/calls/:id/rate`**

```bash
curl -X POST http://localhost:8080/api/v1/calls/{call_id}/rate \
  -H "Authorization: Bearer TOKEN" \
  -d '{"thumbs_up": true}'
```

---

### Get Call History *(Protected)*

**`GET /api/v1/calls/history`**

```bash
curl "http://localhost:8080/api/v1/calls/history?page=1&limit=20" \
  -H "Authorization: Bearer TOKEN"
```

---

# User Interactions API

## Follow/Unfollow

### Follow User *(Protected)*

**`POST /api/v1/users/:id/follow`**

```bash
curl -X POST http://localhost:8080/api/v1/users/{user_id}/follow \
  -H "Authorization: Bearer TOKEN"
```

### Unfollow User *(Protected)*

**`DELETE /api/v1/users/:id/follow`**

### Get Followers *(Protected)*

**`GET /api/v1/users/followers`**

### Get Following *(Protected)*

**`GET /api/v1/users/following`**

---

## Block/Unblock

### Block User *(Protected)*

**`POST /api/v1/users/:id/block`**

### Unblock User *(Protected)*

**`DELETE /api/v1/users/:id/block`**

### Get Blocked Users *(Protected)*

**`GET /api/v1/users/blocked`**

---

## Report User *(Protected)*

**`POST /api/v1/users/:id/report`**

```bash
curl -X POST http://localhost:8080/api/v1/users/{user_id}/report \
  -H "Authorization: Bearer TOKEN" \
  -d '{"reason": "harassment", "description": "optional"}'
```

| Reason        | Description             |
| ------------- | ----------------------- |
| harassment    | Bullying or threatening |
| inappropriate | Inappropriate content   |
| spam          | Spam or advertising     |
| other         | Other violation         |

---

## Database Migrations

```bash
# Daily Words
psql -h localhost -U postgres -d baatu -f migrations/002_create_words.sql

# Voice Calls
psql -h localhost -U postgres -d baatu -f migrations/003_create_calls.sql
```
# Baatu API - Phase 3: Voice Call Matching

## Call Matching API

### Join Matching Queue

**`POST /api/v1/calls/queue`** *(Protected)*

Join the queue to find a conversation partner.

```bash
curl -X POST http://localhost:8080/api/v1/calls/queue \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"skill_level": "intermediate"}'
```

| Field             | Type   | Required | Description                      |
| ----------------- | ------ | -------- | -------------------------------- |
| skill_level       | string | No       | beginner, intermediate, advanced |
| gender_preference | string | No       | Premium filter                   |
| age_preference    | string | No       | Premium filter                   |

---

### Leave Queue

**`DELETE /api/v1/calls/queue`** *(Protected)*

Leave the matching queue.

```bash
curl -X DELETE http://localhost:8080/api/v1/calls/queue \
  -H "Authorization: Bearer TOKEN"
```

---

### Find Match

**`GET /api/v1/calls/match`** *(Protected)*

Check if a match is available.

```bash
curl http://localhost:8080/api/v1/calls/match \
  -H "Authorization: Bearer TOKEN"
```

**Response (match found):**
```json
{
  "success": true,
  "data": {
    "found": true,
    "match_id": "uuid",
    "user": {...},
    "profile": {...}
  }
}
```

---

### Start Call

**`POST /api/v1/calls/start`** *(Protected)*

Start a call with matched user.

```bash
curl -X POST http://localhost:8080/api/v1/calls/start \
  -H "Authorization: Bearer TOKEN" \
  -d '{"callee_id": "matched-user-uuid"}'
```

---

### End Call

**`POST /api/v1/calls/end`** *(Protected)*

End an active call.

```bash
curl -X POST http://localhost:8080/api/v1/calls/end \
  -H "Authorization: Bearer TOKEN" \
  -d '{"call_id": "call-uuid", "duration_seconds": 300}'
```

---

### Rate Call Partner

**`POST /api/v1/calls/:id/rate`** *(Protected)*

Rate your conversation partner after a call.

```bash
curl -X POST http://localhost:8080/api/v1/calls/{call_id}/rate \
  -H "Authorization: Bearer TOKEN" \
  -d '{"thumbs_up": true}'
```

---

### Get Call History

**`GET /api/v1/calls/history`** *(Protected)*

Get paginated call history.

```bash
curl "http://localhost:8080/api/v1/calls/history?page=1&limit=20" \
  -H "Authorization: Bearer TOKEN"
```

---

## User Interactions API

### Follow User

**`POST /api/v1/users/:id/follow`** *(Protected)*

```bash
curl -X POST http://localhost:8080/api/v1/users/{user_id}/follow \
  -H "Authorization: Bearer TOKEN"
```

### Unfollow User

**`DELETE /api/v1/users/:id/follow`** *(Protected)*

### Get Followers

**`GET /api/v1/users/followers`** *(Protected)*

### Get Following

**`GET /api/v1/users/following`** *(Protected)*

---

### Block User

**`POST /api/v1/users/:id/block`** *(Protected)*

Blocks a user (also unfollows both ways).

### Unblock User

**`DELETE /api/v1/users/:id/block`** *(Protected)*

### Get Blocked Users

**`GET /api/v1/users/blocked`** *(Protected)*

---

### Report User

**`POST /api/v1/users/:id/report`** *(Protected)*

```bash
curl -X POST http://localhost:8080/api/v1/users/{user_id}/report \
  -H "Authorization: Bearer TOKEN" \
  -d '{"reason": "harassment", "description": "optional details"}'
```

| Reason        | Description                      |
| ------------- | -------------------------------- |
| harassment    | Bullying or threatening behavior |
| inappropriate | Inappropriate content/language   |
| spam          | Spam or advertising              |
| other         | Other violation                  |

---

## Database Migration

```bash
psql -h localhost -U postgres -d baatu -f migrations/003_create_calls.sql
```

---

## Matching Algorithm

1. User joins queue with skill_level
2. System finds users with same or adjacent skill level
3. Blocked users are excluded
4. Sorted by: wait_time (longest first), rating (higher first)
5. Best match returned
# Baatu Backend API

A GoLang backend for the Baatu English learning app.

## 🚀 Production

**Live API:** https://baatu-backend-production.up.railway.app

| Endpoint  | Description       |
| --------- | ----------------- |
| `/health` | Health check      |
| `/api/v1` | API documentation |

---

## Quick Start (Local Development)

### Prerequisites
- Go 1.21+
- [Supabase](https://supabase.com) account (free tier available)

### 1. Setup Supabase Database

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to **Settings → Database → Connection string → Session pooler**
3. Copy the connection URL (format below):
   ```
   postgresql://postgres.[PROJECT-REF]:[PASSWORD]@aws-1-[REGION].pooler.supabase.com:5432/postgres?sslmode=require
   ```

### 2. Run Migrations

Via `psql`:
```bash
export DATABASE_URL="your-supabase-session-pooler-url"
psql "$DATABASE_URL" -f migrations/001_create_users.sql
psql "$DATABASE_URL" -f migrations/002_create_words.sql
psql "$DATABASE_URL" -f migrations/003_create_calls.sql
```

Or paste the SQL directly into **Supabase Dashboard → SQL Editor**.

### 3. Configure Environment
```bash
cp .env.example .env
# Edit .env with your values
```

### 4. Run Server
```bash
go run cmd/server/main.go
```

Server starts at `http://localhost:8080`

---

## 🚢 Deployment (Railway)

### Prerequisites
- [Railway CLI](https://docs.railway.app/develop/cli) installed
- Railway account

### Deploy
```bash
# Login to Railway
railway login

# Initialize project (first time only)
railway init --name baatu-backend

# Link service
railway service

# Set environment variables
railway variables set \
  PORT=8080 \
  "DATABASE_URL=your-supabase-session-pooler-url" \
  "JWT_SECRET=your-secret" \
  JWT_EXPIRY=24h \
  # ... other variables

# Deploy
railway up

# Generate public domain
railway domain
```

### Environment Variables

| Variable                | Description                 |
| ----------------------- | --------------------------- |
| `PORT`                  | Server port (8080)          |
| `DATABASE_URL`          | Supabase Session Pooler URL |
| `JWT_SECRET`            | JWT signing secret          |
| `JWT_EXPIRY`            | Token expiry (24h)          |
| `ZEPTO_API_KEY`         | Zepto Mail API key          |
| `ZEPTO_FROM_EMAIL`      | Sender email                |
| `AWS_REGION`            | S3 region                   |
| `AWS_ACCESS_KEY_ID`     | AWS access key              |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key              |
| `S3_BUCKET`             | S3 bucket name              |

---

## API Endpoints

### Authentication (Public)

| Method | Endpoint                       | Description               |
| ------ | ------------------------------ | ------------------------- |
| POST   | `/api/v1/auth/register`        | Register new user         |
| POST   | `/api/v1/auth/login`           | Login with email/password |
| POST   | `/api/v1/auth/google`          | Google OAuth              |
| POST   | `/api/v1/auth/verify-email`    | Verify email token        |
| POST   | `/api/v1/auth/forgot-password` | Request password reset    |
| POST   | `/api/v1/auth/verify-otp`      | Verify OTP                |
| POST   | `/api/v1/auth/reset-password`  | Reset password            |

### User Profile (Protected)

| Method | Endpoint                | Description              |
| ------ | ----------------------- | ------------------------ |
| GET    | `/api/v1/users/profile` | Get current user profile |
| PUT    | `/api/v1/users/profile` | Update profile           |
| POST   | `/api/v1/users/avatar`  | Upload avatar            |
| DELETE | `/api/v1/users`         | Delete account           |

### Words (Public + Protected)

| Method | Endpoint                    | Description            |
| ------ | --------------------------- | ---------------------- |
| GET    | `/api/v1/words/daily`       | Get daily words        |
| GET    | `/api/v1/words/today`       | Get word of the day    |
| GET    | `/api/v1/words/:id`         | Get word by ID         |
| POST   | `/api/v1/words/:id/save`    | Save word (auth)       |
| POST   | `/api/v1/words/:id/learned` | Mark as learned (auth) |
| GET    | `/api/v1/words/saved`       | Get saved words (auth) |

### Calls (Protected)

| Method | Endpoint                 | Description         |
| ------ | ------------------------ | ------------------- |
| POST   | `/api/v1/calls/queue`    | Join matching queue |
| DELETE | `/api/v1/calls/queue`    | Leave queue         |
| GET    | `/api/v1/calls/match`    | Find match          |
| POST   | `/api/v1/calls/start`    | Start call          |
| POST   | `/api/v1/calls/end`      | End call            |
| POST   | `/api/v1/calls/:id/rate` | Rate call           |
| GET    | `/api/v1/calls/history`  | Get call history    |

### User Interactions (Protected)

| Method | Endpoint                   | Description       |
| ------ | -------------------------- | ----------------- |
| POST   | `/api/v1/users/:id/follow` | Follow user       |
| DELETE | `/api/v1/users/:id/follow` | Unfollow user     |
| GET    | `/api/v1/users/followers`  | Get followers     |
| GET    | `/api/v1/users/following`  | Get following     |
| POST   | `/api/v1/users/:id/block`  | Block user        |
| DELETE | `/api/v1/users/:id/block`  | Unblock user      |
| GET    | `/api/v1/users/blocked`    | Get blocked users |
| POST   | `/api/v1/users/:id/report` | Report user       |

---

## Example Requests

### Register
```bash
curl -X POST https://baatu-backend-production.up.railway.app/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "MyPassword123",
    "name": "John Doe"
  }'
```

### Login
```bash
curl -X POST https://baatu-backend-production.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "MyPassword123"
  }'
```

### Get Daily Words
```bash
curl https://baatu-backend-production.up.railway.app/api/v1/words/daily
```

---

## Project Structure

```
backend/
├── cmd/server/main.go       # Entry point
├── internal/
│   ├── config/              # Configuration
│   ├── database/            # DB connection
│   ├── middleware/          # JWT auth, CORS
│   ├── models/              # Data models
│   ├── handlers/            # HTTP handlers
│   ├── services/            # Business logic
│   └── repository/          # Database operations
├── pkg/
│   ├── email/               # Zepto Mail
│   └── utils/               # Utilities
├── migrations/              # SQL migrations
├── Dockerfile               # Docker build
└── railway.toml             # Railway config
```

---

## Flutter Integration

```dart
const String baseUrl = 'https://baatu-backend-production.up.railway.app';

// Register
final response = await dio.post(
  '$baseUrl/api/v1/auth/register',
  data: {
    'email': email,
    'password': password,
    'name': name,
  },
);
final token = response.data['data']['token'];

// Store token and use in subsequent requests
dio.options.headers['Authorization'] = 'Bearer $token';

// Get profile
final profile = await dio.get('$baseUrl/api/v1/users/profile');

// Get daily words
final words = await dio.get('$baseUrl/api/v1/words/daily');
```

---

## Tech Stack

- **Runtime:** Go 1.21
- **Framework:** Gin
- **Database:** Supabase (PostgreSQL)
- **Hosting:** Railway
- **Email:** Zepto Mail
- **Storage:** AWS S3

## License

MIT
