# Testing Wisp Backend – Strava OAuth & Supabase Integration

This guide walks you through **end-to-end testing** of the Wisp backend’s Strava integration, including:

- Authenticating a user with Supabase
- Connecting to Strava via OAuth (PKCE flow)
- Exchanging and storing tokens
- Verifying database records
- Triggering activity sync

---

## Prerequisites

- [x] Supabase project is live
- [x] `user_oauth_connections` table exists (see [schema](#supabase-table-check))
- [x] Backend server is running (e.g. at `http://localhost:8000`)
- [x] A valid Supabase JWT for a user

> You can get a test JWT by signing up with Supabase Auth and copying the session token.

---



### 1. Authenticate Supabase User

> If you don’t have a JWT yet, create a user via Supabase Auth UI or REST.

Once logged in, **copy the JWT** for use in all following steps:
```
Authorization: Bearer <SUPABASE_JWT>
```

#### Note: for REST API clients

> `<project_url>=tcpvmldytbxoyslrobot.supabase.co` in this case
```sh
curl -X POST "https://<project_url>/auth/v1/token?grant_type=password" \
  -H "apikey: <under settings api keys anon key>" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ege.hurturk@gmail.com",
    "password": "denemeTest79*a_A"
  }' 
```
This will give the JWT token, under `access_token` in the response.

---

### 2. Initiate Strava OAuth

**Request:**
```bash
curl -X POST http://localhost:8000/strava/initiate \
  -H "Authorization: Bearer <SUPABASE_JWT>"
```

**Expected Response:**
```json
{
  "auth_url": "https://www.strava.com/oauth/mobile/authorize?...",
  "state": "abc123...",
  "expires_at": "2025-08-03T12:00:00Z"
}
```

Copy `auth_url` and open it in a browser or on iOS using `Safari`.

---

### 3. Complete OAuth in Browser

1. Log into your Strava account
2. Authorize Wisp
3. Strava redirects to:
   ```
   https://your-backend.com/strava/callback?code=...&state=...
   ```

> If you’re testing locally, use a tool like [ngrok](https://ngrok.com/) to expose your `localhost` backend.

---

### 4. Manually Simulate Callback (for local testing)

If testing without redirect URL support, call the callback manually:

```bash
curl -X POST http://localhost:8000/strava/callback \
  -H "Content-Type: application/json" \
  -d '{
    "code": "<CODE_FROM_STRAVA>",
    "state": "<STATE_FROM_INITIATE>"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "athlete_id": 123456,
  "athlete_name": "Jane Doe"
}
```

---

### 5. Check Strava Connection Status

```bash
curl -X GET http://localhost:8000/strava/status \
  -H "Authorization: Bearer <SUPABASE_JWT>"
```

**Expected Response:**
```json
{
  "connected": true,
  "athlete_id": 123456,
  "athlete_name": "Jane D.",
  "connected_at": "2025-08-03T08:00:00Z",
  "token_expires_at": "2025-08-03T14:00:00Z",
  "scopes": "read,activity:read"
}
```

---

### 6. Verify Activity Sync

Check that recent runs have been saved in your Supabase `runs` table:

```sql
SELECT * FROM runs WHERE user_id = '<USER_ID_FROM_JWT>';
```

You should see:
- Strava activities with type = `Run`
- Fields like `title`, `distance`, `start_latlng`, `average_pace`

And optionally in `run_routes` if polyline is present.

---

### 7. Disconnect Strava

```bash
curl -X DELETE http://localhost:8000/strava/disconnect \
  -H "Authorization: Bearer <SUPABASE_JWT>"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Strava account disconnected successfully"
}
```

Then verify Supabase:
```sql
SELECT * FROM user_oauth_connections WHERE user_id = '<USER_ID>';
-- should return 0 rows
```

---

## Supabase Table Check

Make sure `user_oauth_connections` schema matches:

| Field             | Type          |
|------------------|---------------|
| id               | uuid (PK)     |
| user_id          | uuid          |
| provider         | varchar       |
| access_token     | text          |
| refresh_token    | text          |
| token_expires_at | timestamp     |
| connected_at     | timestamp     |
| metadata         | jsonb         |
| is_active        | boolean       |

---

## Troubleshooting

| Problem                            | Solution                                                  |
|------------------------------------|-----------------------------------------------------------|
| `Invalid or expired state`         | You waited too long after `/initiate` (state expired)     |
| `401 Unauthorized`                 | Supabase JWT missing or malformed                         |
| `token_expires_at` is `null`       | Backend bug: make sure you’re using correct field names   |
| Sync returns 0 activities          | User has no recent "Run" type workouts in Strava          |
| Callback fails locally             | Use `ngrok` to tunnel Strava redirect to your machine     |

---

## Sample Test Session

```bash
# 1. Start OAuth
curl -X POST http://localhost:8000/strava/initiate -H "Authorization: Bearer <JWT>"

# 2. Open the auth_url in browser, login, grant access

# 3. Call /callback manually
curl -X POST http://localhost:8000/strava/callback -d '{"code": "...", "state": "..."}'

# 4. Check connection status
curl -X GET http://localhost:8000/strava/status -H "Authorization: Bearer <JWT>"

# 5. Confirm activities synced in Supabase
# 6. Disconnect
curl -X DELETE http://localhost:8000/strava/disconnect -H "Authorization: Bearer <JWT>"
```

