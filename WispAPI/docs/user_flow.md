 1. User Onboarding Flow

  Steps:
  1. User signs up with Supabase Auth
  2. handle_new_user() trigger automatically creates profile and preferences
  3. User completes profile setup
  4. User connects Strava (optional)

  Database Operations:
  # Profile setup
  UPDATE profiles SET username = ?, display_name = ?, profile_picture_url = ? WHERE id = ?

  # Strava connection
  INSERT INTO user_oauth_connections (user_id, provider, provider_user_id, access_token, refresh_token) VALUES (?, 'strava', ?, ?, ?)

  # Update preferences
  UPDATE user_preferences SET units_distance = ?, privacy_runs = ? WHERE user_id = ?

  2. Record a Run Flow

  Steps:
  1. User starts recording
  2. GPS points collected during run
  3. User finishes run
  4. Run data and route saved
  5. Weather data fetched and saved

  Database Operations:
  # Save the run
  INSERT INTO runs (user_id, title, distance, moving_time, elapsed_time, average_pace, started_at, finished_at, start_latitude, start_longitude, pace_splits, heart_rate_data) VALUES (...)

  # Save GPS route
  INSERT INTO run_routes (run_id, coordinates, encoded_polyline, total_points) VALUES (?, ?, ?, ?)

  # Save weather data
  INSERT INTO run_weather (run_id, temperature, humidity, weather_condition, recorded_at) VALUES (?, ?, ?, ?, ?)

  3. Ghost Racing Flow

  Steps:
  1. User selects a ghost before run
  2. During run, compare against ghost in real-time
  3. After run, save race results
  4. Display comparison and achievements

  Database Operations:
  # Get available ghosts
  SELECT * FROM ghosts WHERE user_id = ? AND is_active = true

  # During run - get ghost pace data
  SELECT target_pace, custom_splits FROM ghosts WHERE id = ?

  # Save race results
  INSERT INTO ghost_race_results (run_id, ghost_id, result_status, time_difference, distance_completed, completion_percentage, split_comparisons) VALUES (...)

  4. Social Features Flow

  Steps:
  1. User searches for friends
  2. User follows someone
  3. View friends' public runs
  4. Create and share ghosts

  Database Operations:
  # Follow someone
  INSERT INTO user_relationships (follower_id, followed_id, relationship_type) VALUES (?, ?, 'following')

  # Get friend runs (respects privacy)
  SELECT r.* FROM runs r
  JOIN user_preferences up ON up.user_id = r.user_id
  JOIN user_relationships ur ON ur.followed_id = r.user_id
  WHERE ur.follower_id = ? AND up.privacy_runs IN ('public', 'friends')

  # Create public ghost
  INSERT INTO ghosts (user_id, ghost_type, name, target_distance, target_duration, based_on_run_id, is_public) VALUES (?, 'personal_record', ?, ?, ?, ?, true)

  5. Strava Integration Flow

  Steps:
  1. Import runs from Strava
  2. Sync new activities via webhook
  3. Export runs to Strava

  Database Operations:
  # Import Strava run
  INSERT INTO runs (user_id, external_id, data_source, title, distance, moving_time, started_at) VALUES (?, ?, 'strava', ?, ?, ?, ?)

  # Check for existing Strava run
  SELECT id FROM runs WHERE user_id = ? AND external_id = ? AND data_source = 'strava'

  # Get user's Strava token
  SELECT access_token, refresh_token FROM user_oauth_connections WHERE user_id = ? AND provider = 'strava' AND is_active = true