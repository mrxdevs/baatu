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

