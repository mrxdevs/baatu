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
