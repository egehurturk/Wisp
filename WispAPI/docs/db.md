# Wisp Database Schema - Supabase Implementation

This document provides the complete database schema and implementation details for the Wisp running app using Supabase.

## Quick Start

### Prerequisites
- Supabase project created
- PostgreSQL with UUID extension enabled
- Row Level Security (RLS) enabled

### Setup Instructions

1. **Create a new Supabase project**
2. **Run the schema setup scripts** in the following order:
   - Core schema (tables and types)
   - RLS policies
   - Indexes and functions
3. **Configure OAuth providers** in Supabase dashboard (Strava, Google)

## Database Architecture

### Technology Stack
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth (`auth.users` table)
- **Security**: Row Level Security (RLS) policies
- **Real-time**: Supabase real-time subscriptions
- **Storage**: Supabase Storage for profile pictures

### Core Design Principles
- **Privacy First**: Comprehensive privacy controls through user preferences
- **Performance**: Optimized indexes and JSONB for complex data
- **Security**: RLS policies protect all user data
- **Scalability**: UUID primary keys and efficient relationships
- **MVP Focus**: Streamlined for essential features only

## Schema Overview

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `profiles` | User profiles extending auth.users | Username, display name, profile picture |
| `user_preferences` | App settings and privacy | Units, privacy levels, app preferences |
| `user_oauth_connections` | OAuth integrations | Strava/Google tokens and metadata |
| `runs` | Core run tracking data | Distance, pace, heart rate, GPS points |
| `run_routes` | GPS coordinate storage | JSONB coordinates, encoded polylines |
| `run_weather` | Weather during runs | Temperature, humidity, wind conditions |
| `ghosts` | Ghost competitors | 4 types: PR, Strava friends, goals, past runs |
| `ghost_race_results` | Race outcomes | Time differences, split comparisons |
| `user_relationships` | Social connections | Following system with privacy respect |

## Detailed Schema

### 1. User Management

#### `profiles` table
Extends Supabase's `auth.users` with app-specific profile data.

```sql
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    profile_picture_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    timezone VARCHAR(50) DEFAULT 'UTC',
    CONSTRAINT username_length CHECK (char_length(username) >= 3)
);
```

**Key Features:**
- References Supabase auth.users directly
- Automatic profile creation via trigger
- Username uniqueness enforced
- Timezone support for global users

#### `user_preferences` table
Controls app behavior and privacy settings.

```sql
CREATE TABLE public.user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    units_distance VARCHAR(10) DEFAULT 'metric',
    units_temperature VARCHAR(10) DEFAULT 'celsius',
    privacy_profile VARCHAR(20) DEFAULT 'public',
    privacy_runs VARCHAR(20) DEFAULT 'public',
    notifications_enabled BOOLEAN DEFAULT true,
    auto_pause_enabled BOOLEAN DEFAULT true,
    gps_accuracy VARCHAR(20) DEFAULT 'high',
    UNIQUE(user_id)
);
```

**Privacy Controls:**
- `privacy_profile`: 'public', 'friends', 'private'
- `privacy_runs`: 'public', 'friends', 'private'
- RLS policies respect these settings

### 2. Run Data Storage

#### `runs` table
Core table for all run data with comprehensive metrics.

```sql
CREATE TABLE public.runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    external_id VARCHAR(255), -- Strava activity ID
    data_source run_source DEFAULT 'app', -- 'app', 'strava', 'imported'
    
    -- Basic run info
    title VARCHAR(255),
    description TEXT,
    distance DECIMAL(10,2) NOT NULL, -- meters
    moving_time INTEGER NOT NULL, -- seconds
    elapsed_time INTEGER NOT NULL, -- seconds
    
    -- Performance metrics
    average_pace DECIMAL(8,2), -- seconds per kilometer
    average_speed DECIMAL(8,2), -- meters per second
    average_cadence INTEGER, -- steps per minute
    average_heart_rate INTEGER, -- bpm
    max_heart_rate INTEGER, -- bpm
    calories_burned INTEGER,
    
    -- Location and elevation
    start_latitude DECIMAL(10,6),
    start_longitude DECIMAL(10,6),
    end_latitude DECIMAL(10,6),
    end_longitude DECIMAL(10,6),
    elevation_gain DECIMAL(8,2), -- meters
    elevation_loss DECIMAL(8,2), -- meters
    max_elevation DECIMAL(8,2), -- meters
    min_elevation DECIMAL(8,2), -- meters
    
    -- Timing
    started_at TIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    timezone VARCHAR(50),
    
    -- Splits data (stored as JSONB array)
    pace_splits JSONB, -- [{distance: 1000, pace: 240, time: 240}, ...]
    heart_rate_data JSONB, -- [{timestamp: 60, heart_rate: 140}, ...]
    
    CONSTRAINT valid_distance CHECK (distance > 0),
    CONSTRAINT valid_times CHECK (moving_time > 0 AND elapsed_time >= moving_time)
);
```

**Data Sources:**
- `app`: Recorded directly in Wisp
- `strava`: Imported from Strava via API
- `imported`: Bulk imported from other sources

#### `run_routes` table
GPS coordinate storage optimized for performance.

```sql
CREATE TABLE public.run_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
    coordinates JSONB NOT NULL, -- Array of {lat, lng, timestamp, altitude?}
    encoded_polyline TEXT, -- Google encoded polyline
    total_points INTEGER NOT NULL,
    UNIQUE(run_id)
);
```

**Coordinate Format:**
```json
[
  {"lat": 37.7749, "lng": -122.4194, "timestamp": 1609459200, "altitude": 50},
  {"lat": 37.7750, "lng": -122.4195, "timestamp": 1609459205, "altitude": 52}
]
```

### 3. Ghost Racing System

#### `ghosts` table
Supports all 4 ghost types with flexible configuration.

```sql
CREATE TABLE public.ghosts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ghost_type ghost_type NOT NULL, -- 'personal_record', 'strava_friend', 'custom_goal', 'past_run'
    
    -- Ghost identity
    name VARCHAR(255) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    
    -- Performance targets
    target_distance DECIMAL(10,2) NOT NULL, -- meters
    target_duration INTEGER NOT NULL, -- seconds
    target_pace DECIMAL(8,2), -- seconds per kilometer
    
    -- Source references
    based_on_run_id UUID REFERENCES public.runs(id), -- For PR and past_run ghosts
    strava_friend_user_id UUID REFERENCES auth.users(id), -- For strava_friend ghosts
    strava_activity_id VARCHAR(255), -- External Strava activity ID
    
    -- Custom goal data
    custom_splits JSONB, -- [{distance: 1000, target_pace: 240}, ...]
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    is_public BOOLEAN DEFAULT false,
    
    CONSTRAINT valid_targets CHECK (target_distance > 0 AND target_duration > 0)
);
```

**Ghost Types:**
- **Personal Record**: `based_on_run_id` points to user's best run
- **Strava Friend**: `strava_friend_user_id` + `strava_activity_id`
- **Custom Goal**: Uses `custom_splits` for pacing strategy
- **Past Run**: `based_on_run_id` points to any previous run

#### `ghost_race_results` table
Detailed results from ghost races.

```sql
CREATE TABLE public.ghost_race_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
    ghost_id UUID NOT NULL REFERENCES public.ghosts(id) ON DELETE CASCADE,
    
    result_status ghost_race_status NOT NULL, -- 'won', 'lost', 'abandoned', 'in_progress'
    time_difference INTEGER, -- seconds (+ = slower, - = faster)
    distance_completed DECIMAL(10,2), -- meters when race ended
    completion_percentage DECIMAL(5,2), -- 0.0 to 1.0
    
    -- Detailed comparison data
    split_comparisons JSONB, -- Split-by-split analysis
    heart_rate_comparison JSONB, -- HR comparison if available
    
    -- Gap analysis
    average_gap INTEGER, -- Average time gap in seconds
    max_gap INTEGER, -- Maximum gap (furthest behind)
    min_gap INTEGER, -- Minimum gap (closest ahead)
    
    UNIQUE(run_id, ghost_id)
);
```

### 4. Social Features

#### `user_relationships` table
Following system with privacy integration.

```sql
CREATE TABLE public.user_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    followed_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    relationship_type relationship_type DEFAULT 'following', -- 'following', 'strava_friend'
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'blocked', 'pending'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(follower_id, followed_id),
    CONSTRAINT no_self_follow CHECK (follower_id != followed_id)
);
```

## Row Level Security (RLS) Policies

### Privacy-Aware Data Access

All tables have comprehensive RLS policies that respect user privacy preferences:

#### Profile Privacy
```sql
-- Public profiles viewable by everyone
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_preferences 
            WHERE user_id = profiles.id AND privacy_profile = 'public'
        )
    );
```

#### Run Privacy
```sql
-- Runs follow user privacy settings
CREATE POLICY "Public runs are viewable by everyone" ON public.runs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_preferences 
            WHERE user_id = runs.user_id AND privacy_runs = 'public'
        )
    );

-- Friends can see friend runs
CREATE POLICY "Friends can view friend runs" ON public.runs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_preferences up
            JOIN public.user_relationships ur ON ur.followed_id = runs.user_id
            WHERE up.user_id = runs.user_id 
            AND up.privacy_runs = 'friends'
            AND ur.follower_id = auth.uid()
            AND ur.status = 'active'
        )
    );
```

## Performance Optimizations

### Essential Indexes

```sql
-- Core performance indexes
CREATE INDEX idx_runs_user_started ON public.runs(user_id, started_at DESC);
CREATE INDEX idx_ghosts_user_type_active ON public.ghosts(user_id, ghost_type, is_active);
CREATE INDEX idx_relationships_active_follows ON public.user_relationships(follower_id, followed_id) WHERE status = 'active';

-- JSONB indexes for GPS queries
CREATE INDEX idx_run_routes_coordinates ON public.run_routes USING GIN(coordinates);
```

### Query Patterns

#### Get User's Recent Runs
```sql
SELECT r.*, rr.encoded_polyline, rw.temperature
FROM runs r
LEFT JOIN run_routes rr ON r.id = rr.run_id
LEFT JOIN run_weather rw ON r.id = rw.run_id
WHERE r.user_id = auth.uid()
ORDER BY r.started_at DESC
LIMIT 20;
```

#### Get Active Ghosts for User
```sql
SELECT * FROM ghosts 
WHERE user_id = auth.uid() 
AND is_active = true 
ORDER BY created_at DESC;
```

## Supabase-Specific Features

### Automatic Profile Creation
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
    );
    
    INSERT INTO public.user_preferences (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Real-time Subscriptions
Enable real-time updates for key tables:
```sql
-- In Supabase dashboard or via API
ALTER PUBLICATION supabase_realtime ADD TABLE public.ghost_race_results;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_relationships;
```

## OAuth Integration

### Strava Configuration
In your Supabase dashboard, configure Strava OAuth:
- **Client ID**: Your Strava app client ID
- **Client Secret**: Your Strava app client secret
- **Redirect URL**: `https://your-project.supabase.co/auth/v1/callback`

### Google Configuration
- **Client ID**: Your Google OAuth client ID
- **Client Secret**: Your Google OAuth client secret

## Migration Strategy

### Production Deployment
1. Run schema in staging environment first
2. Test all RLS policies with different user scenarios
3. Verify OAuth integrations work correctly
4. Create backups before production deployment
5. Run migrations during low-traffic periods

### Data Migration from Other Sources
- Use `data_source` field to track imported data
- Preserve `external_id` for Strava activities
- Batch insert for large datasets
- Validate data integrity after migration

## Monitoring and Maintenance

### Key Metrics to Monitor
- Query performance on runs table
- RLS policy execution time
- JSONB query performance
- OAuth token refresh rates

### Regular Maintenance
- Vacuum and analyze tables weekly
- Monitor index usage and optimize
- Archive old ghost race results if needed
- Update statistics for query planner

This schema provides a solid foundation for the Wisp MVP while maintaining flexibility for future enhancements.