# Wisp REST API Endpoints

Complete API specification for the Wisp running app backend.

## Base Configuration

### Base URL
```
https://your-backend.com/api/v1/
```

### Authentication
All endpoints require Supabase JWT token in the Authorization header:
```http
Authorization: Bearer <supabase_jwt_token>
```

### Response Format
All responses follow this structure:
```json
{
  "data": { ... },          // Success response data
  "error": { ... },         // Error details (if applicable)
  "timestamp": "ISO8601",   // Response timestamp
  "request_id": "uuid"      // Unique request identifier
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created successfully
- `400` - Bad request (validation error)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (RLS policy blocked access)
- `404` - Not found
- `409` - Conflict (duplicate data)
- `429` - Rate limited
- `500` - Internal server error

---

## 1. User Management

### User Profiles

#### Get Current User Profile
```http
GET /api/v1/users/profile
```

**Response:**
```json
{
  "id": "uuid",
  "username": "john_runner",
  "display_name": "John Smith",
  "profile_picture_url": "https://...",
  "created_at": "2023-12-01T10:00:00Z",
  "updated_at": "2023-12-01T10:00:00Z",
  "timezone": "America/New_York",
  "preferences": {
    "units_distance": "metric",
    "units_temperature": "celsius",
    "privacy_profile": "public",
    "privacy_runs": "friends",
    "notifications_enabled": true,
    "auto_pause_enabled": true,
    "gps_accuracy": "high"
  }
}
```

#### Update User Profile
```http
PUT /api/v1/users/profile
```

**Request Body:**
```json
{
  "display_name": "John Smith Jr.",
  "timezone": "America/Los_Angeles",
  "profile_picture_url": "https://new-avatar-url.com"
}
```

**Response:**
```json
{
  "id": "uuid",
  "username": "john_runner",
  "display_name": "John Smith Jr.",
  "updated_at": "2023-12-01T15:30:00Z"
}
```

#### Get Another User's Profile
```http
GET /api/v1/users/profile/{user_id}
```

**Response:** (Respects privacy settings)
```json
{
  "id": "uuid",
  "username": "jane_runner",
  "display_name": "Jane Doe",
  "profile_picture_url": "https://...",
  "created_at": "2023-11-15T08:00:00Z",
  "is_following": true,
  "run_stats": {
    "total_runs": 45,
    "total_distance": 180000,
    "average_pace": 285.5
  }
}
```

#### Upload Profile Picture
```http
POST /api/v1/users/profile/upload-avatar
Content-Type: multipart/form-data
```

**Request Body:**
```
avatar: <image_file>
```

**Response:**
```json
{
  "profile_picture_url": "https://supabase-storage-url/avatars/user-id.jpg"
}
```

### User Preferences

#### Get User Preferences
```http
GET /api/v1/users/preferences
```

**Response:**
```json
{
  "units_distance": "metric",
  "units_temperature": "celsius",
  "privacy_profile": "public",
  "privacy_runs": "friends",
  "notifications_enabled": true,
  "auto_pause_enabled": true,
  "gps_accuracy": "high"
}
```

#### Update User Preferences
```http
PUT /api/v1/users/preferences
```

**Request Body:**
```json
{
  "units_distance": "imperial",
  "privacy_runs": "public",
  "auto_pause_enabled": false
}
```

### OAuth Connections

#### Get OAuth Connections
```http
GET /api/v1/users/oauth/connections
```

**Response:**
```json
{
  "connections": [
    {
      "provider": "strava",
      "connected_at": "2023-11-01T10:00:00Z",
      "last_sync_at": "2023-12-01T08:00:00Z",
      "is_active": true
    },
    {
      "provider": "google",
      "connected_at": "2023-10-15T14:30:00Z",
      "is_active": true
    }
  ]
}
```

#### Connect Strava Account
```http
POST /api/v1/users/oauth/strava/connect
```

**Request Body:**
```json
{
  "authorization_code": "strava_auth_code_from_oauth_flow",
  "redirect_uri": "your-app://oauth/callback"
}
```

**Response:**
```json
{
  "provider": "strava",
  "connected_at": "2023-12-01T10:00:00Z",
  "athlete_id": "12345678"
}
```

#### Disconnect Strava Account
```http
DELETE /api/v1/users/oauth/strava/disconnect
```

#### Manual Strava Sync
```http
POST /api/v1/users/oauth/strava/sync
```

**Query Parameters:**
- `activities_limit` (optional): Number of recent activities to sync (default: 50)

**Response:**
```json
{
  "synced_activities": 12,
  "new_runs": 8,
  "updated_runs": 4,
  "sync_completed_at": "2023-12-01T10:00:00Z"
}
```

---

## 2. Run Management

### Run CRUD Operations

#### Get User's Runs
```http
GET /api/v1/runs
```

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `sort`: Sort order (`date_desc`, `date_asc`, `distance_desc`, `distance_asc`)
- `data_source`: Filter by source (`app`, `strava`, `imported`)

**Response:**
```json
{
  "runs": [
    {
      "id": "uuid",
      "title": "Morning 5K",
      "description": "Beautiful sunrise run",
      "distance": 5000.0,
      "moving_time": 1200,
      "elapsed_time": 1300,
      "average_pace": 240.0,
      "average_speed": 4.17,
      "average_heart_rate": 165,
      "max_heart_rate": 185,
      "calories_burned": 350,
      "elevation_gain": 45.5,
      "started_at": "2023-12-01T07:00:00Z",
      "finished_at": "2023-12-01T07:21:40Z",
      "data_source": "app",
      "has_route": true,
      "has_weather": true,
      "has_ghost_race": true,
      "created_at": "2023-12-01T07:25:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 145,
    "has_next": true,
    "has_previous": false
  }
}
```

#### Create New Run
```http
POST /api/v1/runs
```

**Request Body:**
```json
{
  "title": "Evening Run",
  "description": "Great tempo run in the park",
  "distance": 8000.0,
  "moving_time": 2400,
  "elapsed_time": 2500,
  "average_pace": 300.0,
  "average_speed": 3.33,
  "average_heart_rate": 165,
  "max_heart_rate": 185,
  "average_cadence": 180,
  "calories_burned": 450,
  "started_at": "2023-12-01T18:00:00Z",
  "finished_at": "2023-12-01T18:41:40Z",
  "start_latitude": 37.7749,
  "start_longitude": -122.4194,
  "end_latitude": 37.7849,
  "end_longitude": -122.4094,
  "elevation_gain": 150.0,
  "elevation_loss": 145.0,
  "max_elevation": 125.5,
  "min_elevation": 25.0,
  "timezone": "America/Los_Angeles",
  "pace_splits": [
    {"distance": 1000, "pace": 295, "time": 295},
    {"distance": 2000, "pace": 305, "time": 305},
    {"distance": 3000, "pace": 290, "time": 290}
  ],
  "heart_rate_data": [
    {"timestamp": 60, "heart_rate": 140},
    {"timestamp": 120, "heart_rate": 160},
    {"timestamp": 180, "heart_rate": 170}
  ]
}
```

**Response:**
```json
{
  "id": "uuid",
  "title": "Evening Run",
  "distance": 8000.0,
  "moving_time": 2400,
  "created_at": "2023-12-01T18:45:00Z"
}
```

#### Get Specific Run Details
```http
GET /api/v1/runs/{run_id}
```

**Response:**
```json
{
  "id": "uuid",
  "title": "Morning 5K",
  "description": "Beautiful sunrise run",
  "distance": 5000.0,
  "moving_time": 1200,
  "elapsed_time": 1300,
  "average_pace": 240.0,
  "pace_splits": [
    {"distance": 1000, "pace": 238, "time": 238},
    {"distance": 2000, "pace": 242, "time": 242}
  ],
  "heart_rate_data": [
    {"timestamp": 60, "heart_rate": 140},
    {"timestamp": 120, "heart_rate": 165}
  ],
  "route": {
    "encoded_polyline": "google_encoded_polyline_string",
    "total_points": 1250
  },
  "weather": {
    "temperature": 18.5,
    "feels_like_temperature": 17.0,
    "humidity": 0.65,
    "wind_speed": 3.2,
    "weather_condition": "Clear",
    "weather_description": "clear sky"
  },
  "ghost_race_results": [
    {
      "ghost_name": "5K Personal Best",
      "result_status": "won",
      "time_difference": -30,
      "completion_percentage": 1.0
    }
  ]
}
```

#### Update Run
```http
PUT /api/v1/runs/{run_id}
```

**Request Body:**
```json
{
  "title": "Amazing Morning 5K",
  "description": "Perfect weather and felt great!"
}
```

#### Delete Run
```http
DELETE /api/v1/runs/{run_id}
```

### Run Routes & Weather

#### Get GPS Route Data
```http
GET /api/v1/runs/{run_id}/route
```

**Response:**
```json
{
  "coordinates": [
    {"lat": 37.7749, "lng": -122.4194, "timestamp": 1609459200, "altitude": 50},
    {"lat": 37.7750, "lng": -122.4195, "timestamp": 1609459205, "altitude": 52}
  ],
  "encoded_polyline": "google_encoded_polyline_string",
  "total_points": 1250,
  "bounds": {
    "north": 37.7850,
    "south": 37.7749,
    "east": -122.4094,
    "west": -122.4194
  }
}
```

#### Save GPS Route
```http
POST /api/v1/runs/{run_id}/route
```

**Request Body:**
```json
{
  "coordinates": [
    {"lat": 37.7749, "lng": -122.4194, "timestamp": 1609459200, "altitude": 50},
    {"lat": 37.7750, "lng": -122.4195, "timestamp": 1609459205, "altitude": 52}
  ],
  "encoded_polyline": "google_encoded_polyline_string"
}
```

#### Get Weather Data
```http
GET /api/v1/runs/{run_id}/weather
```

**Response:**
```json
{
  "temperature": 18.5,
  "feels_like_temperature": 17.0,
  "humidity": 0.65,
  "wind_speed": 3.2,
  "wind_direction": 245,
  "weather_condition": "Clear",
  "weather_description": "clear sky",
  "cloud_coverage": 0.1,
  "visibility": 10000,
  "uv_index": 6,
  "pressure": 1013.25,
  "source": "openweathermap",
  "recorded_at": "2023-12-01T07:00:00Z"
}
```

#### Save Weather Data
```http
POST /api/v1/runs/{run_id}/weather
```

**Request Body:**
```json
{
  "temperature": 18.5,
  "feels_like_temperature": 17.0,
  "humidity": 0.65,
  "wind_speed": 3.2,
  "wind_direction": 245,
  "weather_condition": "Clear",
  "weather_description": "clear sky",
  "source": "openweathermap",
  "recorded_at": "2023-12-01T07:00:00Z"
}
```

### Run Statistics

#### Get Run Summary Statistics
```http
GET /api/v1/runs/stats/summary
```

**Response:**
```json
{
  "total_runs": 145,
  "total_distance": 750000.0,
  "total_moving_time": 180000,
  "average_pace": 285.5,
  "best_pace": 220.0,
  "total_elevation_gain": 5500.0,
  "total_calories": 52000,
  "this_week": {
    "runs": 4,
    "distance": 25000.0,
    "moving_time": 7200
  },
  "this_month": {
    "runs": 18,
    "distance": 95000.0,
    "moving_time": 28800
  }
}
```

#### Get Monthly Statistics
```http
GET /api/v1/runs/stats/monthly
```

**Query Parameters:**
- `year`: Year (default: current year)
- `months`: Number of months to include (default: 12)

**Response:**
```json
{
  "monthly_stats": [
    {
      "year": 2023,
      "month": 12,
      "runs": 18,
      "distance": 95000.0,
      "moving_time": 28800,
      "average_pace": 303.16,
      "elevation_gain": 850.0
    },
    {
      "year": 2023,
      "month": 11,
      "runs": 22,
      "distance": 110000.0,
      "moving_time": 33600,
      "average_pace": 305.45,
      "elevation_gain": 1200.0
    }
  ]
}
```

#### Get Personal Records
```http
GET /api/v1/runs/personal-records
```

**Response:**
```json
{
  "personal_records": [
    {
      "distance": 5000,
      "best_time": 1200,
      "best_pace": 240.0,
      "run_id": "uuid",
      "achieved_at": "2023-11-15T08:30:00Z"
    },
    {
      "distance": 10000,
      "best_time": 2700,
      "best_pace": 270.0,
      "run_id": "uuid",
      "achieved_at": "2023-10-22T09:15:00Z"
    }
  ]
}
```

---

## 3. Ghost System

### Ghost Management

#### Get User's Ghosts
```http
GET /api/v1/ghosts
```

**Query Parameters:**
- `ghost_type`: Filter by type (`personal_record`, `strava_friend`, `custom_goal`, `past_run`)
- `is_active`: Filter by active status (default: true)

**Response:**
```json
{
  "ghosts": [
    {
      "id": "uuid",
      "ghost_type": "personal_record",
      "name": "5K Personal Best",
      "description": "Your fastest 5K time - beat it!",
      "target_distance": 5000.0,
      "target_duration": 1200,
      "target_pace": 240.0,
      "based_on_run_id": "uuid",
      "based_on_run_title": "Morning 5K PR",
      "difficulty_level": 3,
      "is_active": true,
      "is_public": false,
      "created_at": "2023-11-15T10:00:00Z"
    },
    {
      "id": "uuid",
      "ghost_type": "custom_goal",
      "name": "Sub-20 5K Goal",
      "description": "Break the 20-minute barrier",
      "target_distance": 5000.0,
      "target_duration": 1200,
      "target_pace": 240.0,
      "custom_splits": [
        {"distance": 1000, "target_pace": 240},
        {"distance": 2000, "target_pace": 238}
      ],
      "difficulty_level": 4,
      "is_active": true,
      "is_public": false,
      "created_at": "2023-12-01T09:00:00Z"
    }
  ]
}
```

#### Create New Ghost
```http
POST /api/v1/ghosts
```

**Request Body (Personal Record Ghost):**
```json
{
  "ghost_type": "personal_record",
  "name": "10K Personal Best",
  "description": "Your best 10K performance",
  "based_on_run_id": "uuid",
  "is_public": false
}
```

**Request Body (Custom Goal Ghost):**
```json
{
  "ghost_type": "custom_goal",
  "name": "Sub-20 5K Goal",
  "description": "Break the 20-minute barrier",
  "target_distance": 5000.0,
  "target_duration": 1200,
  "difficulty_level": 4,
  "is_public": false,
  "custom_splits": [
    {"distance": 1000, "target_pace": 240},
    {"distance": 2000, "target_pace": 238},
    {"distance": 3000, "target_pace": 239},
    {"distance": 4000, "target_pace": 241},
    {"distance": 5000, "target_pace": 238}
  ]
}
```

**Request Body (Strava Friend Ghost):**
```json
{
  "ghost_type": "strava_friend",
  "name": "Alex's Morning 5K",
  "description": "Alex's impressive morning run",
  "strava_friend_user_id": "uuid",
  "strava_activity_id": "12345678",
  "is_public": false
}
```

#### Get Ghost Details
```http
GET /api/v1/ghosts/{ghost_id}
```

**Response:**
```json
{
  "id": "uuid",
  "ghost_type": "personal_record",
  "name": "5K Personal Best",
  "description": "Your fastest 5K time - beat it!",
  "target_distance": 5000.0,
  "target_duration": 1200,
  "target_pace": 240.0,
  "based_on_run": {
    "id": "uuid",
    "title": "Morning 5K PR",
    "started_at": "2023-11-15T08:30:00Z",
    "pace_splits": [
      {"distance": 1000, "pace": 238, "time": 238},
      {"distance": 2000, "pace": 242, "time": 242}
    ]
  },
  "race_history": {
    "total_races": 8,
    "wins": 3,
    "losses": 5,
    "best_improvement": -15,
    "last_race_at": "2023-11-30T18:00:00Z"
  }
}
```

#### Update Ghost
```http
PUT /api/v1/ghosts/{ghost_id}
```

**Request Body:**
```json
{
  "name": "Updated Ghost Name",
  "description": "New description",
  "is_active": false
}
```

#### Delete Ghost
```http
DELETE /api/v1/ghosts/{ghost_id}
```

### Ghost Discovery

#### Get Public Ghosts
```http
GET /api/v1/ghosts/public
```

**Query Parameters:**
- `ghost_type`: Filter by type
- `difficulty_level`: Filter by difficulty (1-5)
- `distance_range`: Filter by distance (`5k`, `10k`, `half_marathon`, `marathon`)

**Response:**
```json
{
  "ghosts": [
    {
      "id": "uuid",
      "ghost_type": "custom_goal",
      "name": "Elite 5K Pace",
      "description": "Train like an elite runner",
      "target_distance": 5000.0,
      "target_duration": 900,
      "target_pace": 180.0,
      "difficulty_level": 5,
      "created_by": {
        "username": "elite_runner",
        "display_name": "Elite Runner"
      },
      "usage_count": 1250,
      "average_success_rate": 0.15
    }
  ]
}
```

#### Get Recommended Ghosts
```http
GET /api/v1/ghosts/recommended
```

**Response:**
```json
{
  "recommended": [
    {
      "id": "uuid",
      "name": "Progressive 5K",
      "reason": "Based on your recent 5K times",
      "target_improvement": "2:30 faster",
      "success_probability": 0.75
    }
  ]
}
```

#### Get Friends' Public Ghosts
```http
GET /api/v1/ghosts/friends
```

**Response:**
```json
{
  "friends_ghosts": [
    {
      "id": "uuid",
      "name": "Sarah's Tempo Challenge",
      "ghost_type": "custom_goal",
      "target_distance": 8000.0,
      "created_by": {
        "username": "sarah_runs",
        "display_name": "Sarah Chen"
      },
      "your_relationship": "following"
    }
  ]
}
```

### Ghost Racing

#### Get Ghost Race Data
```http
GET /api/v1/ghosts/{ghost_id}/race-data
```

**Response:**
```json
{
  "ghost_id": "uuid",
  "target_distance": 5000.0,
  "target_duration": 1200,
  "target_pace": 240.0,
  "pacing_strategy": [
    {"distance": 1000, "target_time": 240, "target_pace": 240, "cumulative_time": 240},
    {"distance": 2000, "target_time": 240, "target_pace": 240, "cumulative_time": 480},
    {"distance": 3000, "target_time": 240, "target_pace": 240, "cumulative_time": 720},
    {"distance": 4000, "target_time": 240, "target_pace": 240, "cumulative_time": 960},
    {"distance": 5000, "target_time": 240, "target_pace": 240, "cumulative_time": 1200}
  ],
  "heart_rate_zones": {
    "zone_1": {"min": 120, "max": 140},
    "zone_2": {"min": 140, "max": 160},
    "zone_3": {"min": 160, "max": 180}
  }
}
```

#### Save Ghost Race Result
```http
POST /api/v1/ghost-races
```

**Request Body:**
```json
{
  "run_id": "uuid",
  "ghost_id": "uuid",
  "result_status": "won",
  "time_difference": -30,
  "distance_completed": 5000.0,
  "completion_percentage": 1.0,
  "split_comparisons": [
    {"distance": 1000, "user_time": 235, "ghost_time": 240, "difference": -5, "cumulative_difference": -5},
    {"distance": 2000, "user_time": 238, "ghost_time": 240, "difference": -2, "cumulative_difference": -7},
    {"distance": 3000, "user_time": 242, "ghost_time": 240, "difference": 2, "cumulative_difference": -5},
    {"distance": 4000, "user_time": 239, "ghost_time": 240, "difference": -1, "cumulative_difference": -6},
    {"distance": 5000, "user_time": 236, "ghost_time": 240, "difference": -4, "cumulative_difference": -10}
  ],
  "heart_rate_comparison": [
    {"timestamp": 300, "user_hr": 165, "ghost_hr": 160, "difference": 5},
    {"timestamp": 600, "user_hr": 170, "ghost_hr": 165, "difference": 5}
  ],
  "average_gap": -6,
  "max_gap": 2,
  "min_gap": -10
}
```

#### Get Race Results for Run
```http
GET /api/v1/ghost-races/{run_id}
```

**Response:**
```json
{
  "race_results": [
    {
      "id": "uuid",
      "ghost": {
        "id": "uuid",
        "name": "5K Personal Best",
        "ghost_type": "personal_record"
      },
      "result_status": "won",
      "time_difference": -30,
      "distance_completed": 5000.0,
      "completion_percentage": 1.0,
      "final_position": "ahead",
      "max_lead": 10,
      "created_at": "2023-12-01T07:25:00Z"
    }
  ]
}
```

#### Get Ghost Race History
```http
GET /api/v1/ghost-races/history
```

**Query Parameters:**
- `ghost_id`: Filter by specific ghost
- `result_status`: Filter by result (`won`, `lost`, `abandoned`)
- `limit`: Number of results (default: 50)

**Response:**
```json
{
  "race_history": [
    {
      "id": "uuid",
      "run": {
        "id": "uuid",
        "title": "Morning 5K",
        "started_at": "2023-12-01T07:00:00Z",
        "distance": 5000.0
      },
      "ghost": {
        "id": "uuid",
        "name": "5K Personal Best",
        "ghost_type": "personal_record"
      },
      "result_status": "won",
      "time_difference": -30,
      "improvement_trend": "improving"
    }
  ],
  "summary": {
    "total_races": 25,
    "wins": 12,
    "losses": 11,
    "abandoned": 2,
    "win_rate": 0.48,
    "average_improvement": -5.2
  }
}
```

---

## 4. Social Features

### User Discovery & Search

#### Search Users
```http
GET /api/v1/users/search
```

**Query Parameters:**
- `q`: Search query (username or display name)
- `limit`: Maximum results (default: 20)

**Response:**
```json
{
  "users": [
    {
      "id": "uuid",
      "username": "jane_runner",
      "display_name": "Jane Doe",
      "profile_picture_url": "https://...",
      "is_following": false,
      "follows_you": true,
      "mutual_friends": 3,
      "recent_activity": {
        "last_run_at": "2023-11-30T18:00:00Z",
        "total_runs_this_month": 15
      }
    }
  ]
}
```

#### Discover Recommended Users
```http
GET /api/v1/users/discover
```

**Response:**
```json
{
  "recommended_users": [
    {
      "id": "uuid",
      "username": "mike_marathon",
      "display_name": "Mike Thompson",
      "profile_picture_url": "https://...",
      "recommendation_reason": "Similar pace and distance preferences",
      "common_connections": 2,
      "compatibility_score": 0.85
    }
  ]
}
```

### Relationships

#### Get Users You Follow
```http
GET /api/v1/users/following
```

**Response:**
```json
{
  "following": [
    {
      "id": "uuid",
      "username": "alex_runner",
      "display_name": "Alex Rodriguez",
      "profile_picture_url": "https://...",
      "relationship_type": "following",
      "followed_at": "2023-10-15T10:00:00Z",
      "recent_activity": {
        "last_run_at": "2023-11-30T08:00:00Z",
        "runs_this_week": 4
      }
    }
  ],
  "count": 25
}
```

#### Get Your Followers
```http
GET /api/v1/users/followers
```

**Response:**
```json
{
  "followers": [
    {
      "id": "uuid",
      "username": "sarah_runs",
      "display_name": "Sarah Chen",
      "profile_picture_url": "https://...",
      "following_you_since": "2023-09-20T14:30:00Z",
      "you_follow_back": true
    }
  ],
  "count": 42
}
```

#### Follow a User
```http
POST /api/v1/users/follow
```

**Request Body:**
```json
{
  "user_id": "uuid"
}
```

**Response:**
```json
{
  "followed_user": {
    "id": "uuid",
    "username": "new_friend",
    "display_name": "New Friend"
  },
  "relationship_type": "following",
  "followed_at": "2023-12-01T10:00:00Z"
}
```

#### Unfollow a User
```http
DELETE /api/v1/users/unfollow/{user_id}
```

### Friend Activity

#### Get Activity Feed
```http
GET /api/v1/activity/feed
```

**Query Parameters:**
- `limit`: Number of activities (default: 50)
- `activity_type`: Filter by type (`run`, `ghost_race`, `achievement`)

**Response:**
```json
{
  "activities": [
    {
      "id": "uuid",
      "activity_type": "run",
      "user": {
        "id": "uuid",
        "username": "alex_runner",
        "display_name": "Alex Rodriguez",
        "profile_picture_url": "https://..."
      },
      "run": {
        "id": "uuid",
        "title": "Morning 10K",
        "distance": 10000.0,
        "moving_time": 2700,
        "average_pace": 270.0,
        "started_at": "2023-12-01T07:00:00Z"
      },
      "ghost_race_result": {
        "ghost_name": "Personal Best 10K",
        "result_status": "won",
        "time_difference": -45
      },
      "created_at": "2023-12-01T07:50:00Z"
    },
    {
      "id": "uuid",
      "activity_type": "achievement",
      "user": {
        "id": "uuid",
        "username": "sarah_runs",
        "display_name": "Sarah Chen",
        "profile_picture_url": "https://..."
      },
      "achievement": {
        "name": "Century Runner",
        "description": "Completed 100 runs",
        "badge_color": "#FFD700"
      },
      "created_at": "2023-11-30T20:15:00Z"
    }
  ]
}
```

#### Get Another User's Runs
```http
GET /api/v1/users/{user_id}/runs
```

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)

**Response:** (Respects privacy settings)
```json
{
  "runs": [
    {
      "id": "uuid",
      "title": "Saturday Long Run",
      "distance": 15000.0,
      "moving_time": 4500,
      "average_pace": 300.0,
      "started_at": "2023-11-25T08:00:00Z",
      "ghost_race_results": [
        {
          "ghost_name": "Half Marathon Pace",
          "result_status": "won"
        }
      ]
    }
  ],
  "user": {
    "username": "alex_runner",
    "display_name": "Alex Rodriguez",
    "privacy_level": "friends"
  },
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 78,
    "has_next": true
  }
}
```

---

## 5. Strava Integration

### Webhooks

#### Strava Webhook Endpoint
```http
POST /api/v1/strava/webhook
```

**Request Body:** (From Strava)
```json
{
  "object_type": "activity",
  "object_id": 12345678,
  "aspect_type": "create",
  "owner_id": 98765432,
  "subscription_id": 123456,
  "event_time": 1609459200
}
```

#### Webhook Verification
```http
GET /api/v1/strava/webhook
```

**Query Parameters:**
- `hub.mode`: "subscribe"
- `hub.challenge`: Random string from Strava
- `hub.verify_token`: Your verification token

### Data Sync

#### Import Activities from Strava
```http
POST /api/v1/strava/import/activities
```

**Query Parameters:**
- `after`: Unix timestamp to import activities after (optional)
- `before`: Unix timestamp to import activities before (optional)
- `limit`: Maximum activities to import (default: 50, max: 200)

**Request Body:**
```json
{
  "activity_types": ["Run", "TrailRun"],
  "include_private": false
}
```

**Response:**
```json
{
  "import_summary": {
    "total_found": 25,
    "new_imports": 18,
    "skipped_existing": 7,
    "failed_imports": 0
  },
  "imported_activities": [
    {
      "strava_id": 12345678,
      "wisp_run_id": "uuid",
      "title": "Morning Run",
      "distance": 5000.0,
      "moving_time": 1200,
      "started_at": "2023-11-30T07:00:00Z"
    }
  ],
  "import_completed_at": "2023-12-01T10:15:00Z"
}
```

#### Export Run to Strava
```http
POST /api/v1/strava/export/{run_id}
```

**Request Body:**
```json
{
  "title": "Wisp Run - Morning 5K",
  "description": "Great run tracked with Wisp! 🏃‍♂️",
  "activity_type": "Run"
}
```

**Response:**
```json
{
  "strava_activity_id": 87654321,
  "strava_url": "https://www.strava.com/activities/87654321",
  "exported_at": "2023-12-01T10:30:00Z",
  "export_status": "success"
}
```

#### Get Recent Strava Activities
```http
GET /api/v1/strava/activities/recent
```

**Query Parameters:**
- `limit`: Number of activities (default: 20, max: 100)
- `after`: Unix timestamp for activities after this time

**Response:**
```json
{
  "activities": [
    {
      "strava_id": 12345678,
      "name": "Morning Run",
      "distance": 5000.0,
      "moving_time": 1200,
      "start_date": "2023-11-30T07:00:00Z",
      "type": "Run",
      "imported_to_wisp": true,
      "wisp_run_id": "uuid"
    },
    {
      "strava_id": 12345679,
      "name": "Evening Bike Ride",
      "distance": 25000.0,
      "moving_time": 3600,
      "start_date": "2023-11-29T18:00:00Z",
      "type": "Ride",
      "imported_to_wisp": false,
      "wisp_run_id": null
    }
  ]
}
```

---

## Error Handling Examples

### Validation Error
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "distance": "Distance must be greater than 0",
      "moving_time": "Moving time is required"
    }
  },
  "timestamp": "2023-12-01T10:00:00Z",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Authentication Error
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired authentication token"
  },
  "timestamp": "2023-12-01T10:00:00Z",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Permission Error
```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "You don't have permission to access this resource",
    "details": {
      "resource": "run",
      "resource_id": "uuid",
      "required_permission": "owner_or_public"
    }
  },
  "timestamp": "2023-12-01T10:00:00Z",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Rate Limit Error
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please try again later.",
    "details": {
      "limit": 100,
      "window": "1 hour",
      "retry_after": 3600
    }
  },
  "timestamp": "2023-12-01T10:00:00Z",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## Rate Limits

| Endpoint Category | Limit | Window |
|------------------|-------|---------|
| Authentication | 5 requests | 1 minute |
| Run Creation | 10 requests | 1 minute |
| Run Updates | 20 requests | 1 minute |
| Ghost Operations | 30 requests | 1 minute |
| Social Actions | 50 requests | 1 minute |
| Data Fetching | 200 requests | 1 minute |
| Strava Sync | 20 requests | 1 hour |

## Implementation Notes

1. **Authentication**: All endpoints use Supabase JWT tokens for authentication
2. **RLS Integration**: Database queries automatically respect Row Level Security policies
3. **Privacy**: User preferences control data visibility across all endpoints
4. **Pagination**: Use consistent pagination format across list endpoints
5. **Real-time**: Consider WebSocket connections for live ghost racing features
6. **Caching**: Implement appropriate caching for frequently accessed data
7. **Monitoring**: Log all API requests for debugging and analytics