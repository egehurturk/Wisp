 CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

  -- Create ENUM types
  CREATE TYPE ghost_type AS ENUM ('personal_record', 'strava_friend', 'custom_goal', 'past_run');
  CREATE TYPE run_source AS ENUM ('app', 'strava', 'imported');
  CREATE TYPE ghost_race_status AS ENUM ('won', 'lost', 'abandoned', 'in_progress');
  CREATE TYPE weather_source AS ENUM ('openweathermap', 'weatherapi', 'apple_weather', 'cached', 'unknown');
  CREATE TYPE relationship_type AS ENUM ('following', 'strava_friend');

  -- User profiles table (extends Supabase auth.users)
  CREATE TABLE public.profiles (
      id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
      username VARCHAR(50) UNIQUE NOT NULL,
      display_name VARCHAR(100),
      profile_picture_url TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      timezone VARCHAR(50) DEFAULT 'UTC',

      -- Constrainupts
      CONSTRAINT username_length CHECK (char_length(username) >= 3)
  );

  -- User preferences table
  CREATE TABLE public.user_preferences (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      units_distance VARCHAR(10) DEFAULT 'metric', -- 'metric' or 'imperial'
      units_temperature VARCHAR(10) DEFAULT 'celsius', -- 'celsius' or 'fahrenheit'
      privacy_profile VARCHAR(20) DEFAULT 'public', -- 'public', 'friends', 'private'
      privacy_runs VARCHAR(20) DEFAULT 'public',
      notifications_enabled BOOLEAN DEFAULT true,
      auto_pause_enabled BOOLEAN DEFAULT true,
      gps_accuracy VARCHAR(20) DEFAULT 'high', -- 'high', 'medium', 'low'
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id)
  );

  -- OAuth integrations (Strava, Google, etc.)
  CREATE TABLE public.user_oauth_connections (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      provider VARCHAR(50) NOT NULL, -- 'strava', 'google', etc.
      provider_user_id VARCHAR(255) NOT NULL,
      access_token TEXT,
      refresh_token TEXT,
      token_expires_at TIMESTAMP,
      connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_sync_at TIMESTAMP,
      is_active BOOLEAN DEFAULT true,
      metadata JSONB, -- Store additional provider-specific data
      UNIQUE(user_id, provider)
  );

  -- Runs table - core run data
  CREATE TABLE public.runs (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      external_id VARCHAR(255), -- Strava activity ID or other external ID
      data_source run_source DEFAULT 'app',

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

      -- System fields
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Constraints
      CONSTRAINT valid_distance CHECK (distance > 0),
      CONSTRAINT valid_times CHECK (moving_time > 0 AND elapsed_time >= moving_time)
  );

  -- Run routes table - GPS coordinate data
  CREATE TABLE public.run_routes (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      run_id UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
      coordinates JSONB NOT NULL, -- Array of {lat, lng, timestamp, altitude?}
      encoded_polyline TEXT, -- Google encoded polyline for efficient transmission
      total_points INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(run_id)
  );

  -- Weather data for runs
  CREATE TABLE public.run_weather (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      run_id UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
      temperature DECIMAL(5,2), -- Celsius
      feels_like_temperature DECIMAL(5,2), -- Celsius
      humidity DECIMAL(5,2), -- 0.0 to 1.0
      wind_speed DECIMAL(6,2), -- meters per second
      wind_direction INTEGER, -- degrees 0-360
      weather_condition VARCHAR(100), -- "Clear", "Clouds", "Rain", etc.
      weather_description VARCHAR(255), -- "scattered clouds", "light rain"
      cloud_coverage DECIMAL(5,2), -- 0.0 to 1.0
      visibility INTEGER, -- meters
      uv_index INTEGER, -- 0-11+
      pressure DECIMAL(7,2), -- hPa
      source weather_source DEFAULT 'unknown',
      recorded_at TIMESTAMP NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(run_id)
  );

  -- Ghosts table
  CREATE TABLE public.ghosts (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      ghost_type ghost_type NOT NULL,

      -- Ghost identity
      name VARCHAR(255) NOT NULL,
      description TEXT,
      avatar_url TEXT,

      -- Performance targets
      target_distance DECIMAL(10,2) NOT NULL, -- meters
      target_duration INTEGER NOT NULL, -- seconds
      target_pace DECIMAL(8,2), -- seconds per kilometer

      -- Source references
      based_on_run_id UUID REFERENCES public.runs(id), -- For personal_record and past_run ghosts
      strava_friend_user_id UUID REFERENCES auth.users(id), -- For strava_friend ghosts
      strava_activity_id VARCHAR(255), -- External Strava activity ID

      -- Custom goal data
      custom_splits JSONB, -- For custom training plans: [{distance: 1000, target_pace: 240}, ...]
      difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),

      -- Settings
      is_active BOOLEAN DEFAULT true,
      is_public BOOLEAN DEFAULT false, -- Can other users see/use this ghost

      -- System fields
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Constraints
      CONSTRAINT valid_targets CHECK (target_distance > 0 AND target_duration > 0)
  );

  -- Ghost race results
  CREATE TABLE public.ghost_race_results (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      run_id UUID NOT NULL REFERENCES public.runs(id) ON DELETE CASCADE,
      ghost_id UUID NOT NULL REFERENCES public.ghosts(id) ON DELETE CASCADE,

      -- Race outcome
      result_status ghost_race_status NOT NULL,
      time_difference INTEGER, -- seconds (positive = slower than ghost, negative = faster)
      distance_completed DECIMAL(10,2), -- meters completed when race ended
      completion_percentage DECIMAL(5,2), -- 0.0 to 1.0

      -- Detailed comparison data
      split_comparisons JSONB, -- Detailed split-by-split comparison
      heart_rate_comparison JSONB, -- Heart rate data comparison if available

      -- Additional metrics
      average_gap INTEGER, -- Average time gap in seconds
      max_gap INTEGER, -- Maximum time gap (furthest behind)
      min_gap INTEGER, -- Minimum time gap (closest ahead)

      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Constraints
      UNIQUE(run_id, ghost_id) -- One result per run-ghost combination
  );

  -- User relationships (following/friends)
  CREATE TABLE public.user_relationships (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      followed_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      relationship_type relationship_type DEFAULT 'following',
      status VARCHAR(20) DEFAULT 'active', -- 'active', 'blocked', 'pending'
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Constraints
      UNIQUE(follower_id, followed_id),
      CONSTRAINT no_self_follow CHECK (follower_id != followed_id)
  );

