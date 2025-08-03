# 🛂 Strava OAuth Integration – Wisp Backend

This document outlines how Wisp handles Strava OAuth to securely connect a user's Strava account, store access tokens in Supabase, and sync activity data. It follows the [OAuth 2.0 PKCE flow](https://datatracker.ietf.org/doc/html/rfc7636), designed to work with **mobile apps** (e.g., iOS clients).

---

## 🔄 Flow Overview

```text
Frontend (iOS App)                Wisp Backend               Strava API
        |                              |                           |
1.      |  POST /strava/initiate       |                           |
        |----------------------------->|                           |
        |   ← state + auth_url         |                           |
2.      |  Open auth_url in Safari     |                           |
        |----------------------------->|                           |
        |                              |     ← user logs in       |
        |                              |<--------------------------|
3.      | Strava redirects to backend  |                           |
        |       (via redirect_uri)     |                           |
4.      |  POST /strava/callback       |                           |
        |----------------------------->|----> Token Exchange ---->|
        |                              |<--- access + refresh token
        |                              |   + athlete info          |
5.      |                              | Store token in Supabase   |
        |                              | Start background sync     |
        |         ← success JSON       |                           |
```

---

## 📲 iOS Client Responsibilities

### Step 1 – Initiate OAuth
**Endpoint**: `POST /strava/initiate`  
**Headers**: `Authorization: Bearer <Supabase_JWT>`

**Response**:
```json
{
  "auth_url": "https://www.strava.com/oauth/mobile/authorize?...",
  "state": "random-state-token",
  "expires_at": "2025-08-03T10:00:00Z"
}
```

✅ **Open `auth_url` in Safari**, not WebView.  
The URL includes PKCE challenge and state.

---

### Step 2 – Handle Redirect

After login, Strava redirects to:
```
https://your-backend.com/strava/callback?code=...&state=...
```

The iOS app does **not** handle this. The **backend handles the callback**.

---

## 🔧 Backend Responsibilities

### Step 3 – Handle Callback

**Endpoint**: `POST /strava/callback`  
Strava sends `code`, `state`, and `scope` as query/body params.

**Backend will:**
- Validate the `state`
- Exchange the `code` for:
  - `access_token`
  - `refresh_token`
  - `token_expires_at`
  - `athlete` info
- Store the tokens in `user_oauth_connections` table in Supabase
- Trigger `StravaService.sync_recent_activities(user_id)` as background task

**Response**:
```json
{
  "success": true,
  "athlete_id": 123456,
  "athlete_name": "Jane Doe"
}
```

---

## 🧾 Token Storage Schema – Supabase

Table: `user_oauth_connections`

| Field             | Description                                |
|-------------------|--------------------------------------------|
| `id`              | UUID primary key                           |
| `user_id`         | Supabase user ID (UUID)                    |
| `provider`        | `"strava"`                                 |
| `provider_user_id`| Strava athlete ID (optional)               |
| `access_token`    | OAuth access token                         |
| `refresh_token`   | OAuth refresh token                        |
| `token_expires_at`| When the token will expire (UTC)           |
| `connected_at`    | When the connection was first established  |
| `last_sync_at`    | Timestamp of last successful sync          |
| `is_active`       | Soft delete / revocation toggle            |
| `metadata`        | JSON with athlete info (name, scope, etc.) |

> ⛔ `expires_at` and `created_at` are **not valid fields** – your backend should use `token_expires_at` and `connected_at` instead.

---

## 🔁 Refreshing Tokens

Tokens are **automatically refreshed** by the backend via `StravaService.get_valid_access_token(...)`. This happens:

- Before each Strava API request
- With a **5-minute buffer** before expiry

If refresh fails (e.g. revoked token), the connection is deleted and the user must reconnect.

---

## 🔎 Check Strava Connection

**Endpoint**: `GET /strava/status`  
**Headers**: `Authorization: Bearer <Supabase_JWT>`

**Response** (connected):
```json
{
  "connected": true,
  "athlete_id": 123456,
  "athlete_name": "Jane D.",
  "connected_at": "2025-08-03T08:12:00Z",
  "token_expires_at": "2025-08-03T14:12:00Z",
  "scopes": "read,activity:read"
}
```

**Response** (not connected):
```json
{
  "connected": false
}
```

---

## 🧨 Disconnect Strava

**Endpoint**: `DELETE /strava/disconnect`  
**Headers**: `Authorization: Bearer <Supabase_JWT>`

- Revokes token with Strava
- Deletes the record from `user_oauth_connections`

---

## 🧼 Security Notes

- Uses **PKCE** + **state token** for OAuth security
- `oauth_states` (in-memory state store) should be replaced with Redis or Supabase in production
- Backend verifies and stores all tokens securely — no refresh tokens are exposed to client
- All endpoints require Supabase JWT (`Authorization: Bearer <token>`)

---

## 📂 Related Backend Code

| File | Purpose |
|------|---------|
| `routers/strava.py` | Defines `/initiate`, `/callback`, `/status`, `/disconnect` routes |
| `services/strava_service.py` | Token refresh, activity sync, Supabase run ingestion |
| `models/strava.py` | Pydantic models used in endpoints and internal logic |
| `utils/supabase_client.py` | Provides Supabase client + JWT verification |
