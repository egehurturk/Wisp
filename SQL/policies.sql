  -- Enable Row Level Security
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.user_oauth_connections ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.runs ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.run_routes ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.run_weather ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.ghosts ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.ghost_race_results ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.user_relationships ENABLE ROW LEVEL SECURITY;

  -- Profiles policies
  CREATE POLICY "Users can view their own profile" ON public.profiles
      FOR SELECT USING (auth.uid() = id);

  CREATE POLICY "Users can update their own profile" ON public.profiles
      FOR UPDATE USING (auth.uid() = id);

  CREATE POLICY "Users can insert their own profile" ON public.profiles
      FOR INSERT WITH CHECK (auth.uid() = id);

  CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
      FOR SELECT USING (
          EXISTS (
              SELECT 1 FROM public.user_preferences
              WHERE user_id = profiles.id AND privacy_profile = 'public'
          )
      );

  -- User preferences policies
  CREATE POLICY "Users can manage their own preferences" ON public.user_preferences
      FOR ALL USING (auth.uid() = user_id);

  -- OAuth connections policies (highly sensitive)
  CREATE POLICY "Users can only access their own OAuth connections" ON public.user_oauth_connections
      FOR ALL USING (auth.uid() = user_id);

  -- Runs policies
  CREATE POLICY "Users can manage their own runs" ON public.runs
      FOR ALL USING (auth.uid() = user_id);

  CREATE POLICY "Public runs are viewable by everyone" ON public.runs
      FOR SELECT USING (
          EXISTS (
              SELECT 1 FROM public.user_preferences
              WHERE user_id = runs.user_id AND privacy_runs = 'public'
          )
      );

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

  -- Run routes policies (follow run permissions)
  CREATE POLICY "Users can manage their own run routes" ON public.run_routes
      FOR ALL USING (
          EXISTS (
              SELECT 1 FROM public.runs
              WHERE runs.id = run_routes.run_id AND runs.user_id = auth.uid()
          )
      );

  CREATE POLICY "Run routes follow run visibility" ON public.run_routes
      FOR SELECT USING (
          EXISTS (
              SELECT 1 FROM public.runs
              JOIN public.user_preferences up ON up.user_id = runs.user_id
              WHERE runs.id = run_routes.run_id
              AND (
                  up.privacy_runs = 'public' OR
                  (up.privacy_runs = 'friends' AND EXISTS (
                      SELECT 1 FROM public.user_relationships ur
                      WHERE ur.followed_id = runs.user_id
                      AND ur.follower_id = auth.uid()
                      AND ur.status = 'active'
                  ))
              )
          )
      );

  -- Run weather policies (follow run permissions)
  CREATE POLICY "Users can manage their own run weather" ON public.run_weather
      FOR ALL USING (
          EXISTS (
              SELECT 1 FROM public.runs
              WHERE runs.id = run_weather.run_id AND runs.user_id = auth.uid()
          )
      );

  -- Ghosts policies
  CREATE POLICY "Users can manage their own ghosts" ON public.ghosts
      FOR ALL USING (auth.uid() = user_id);

  CREATE POLICY "Public ghosts are viewable by everyone" ON public.ghosts
      FOR SELECT USING (is_public = true);

  -- Ghost race results policies
  CREATE POLICY "Users can manage their own ghost race results" ON public.ghost_race_results
      FOR ALL USING (
          EXISTS (
              SELECT 1 FROM public.runs
              WHERE runs.id = ghost_race_results.run_id AND runs.user_id = auth.uid()
          )
      );

  -- User relationships policies
  CREATE POLICY "Users can manage relationships they're involved in" ON public.user_relationships
      FOR ALL USING (auth.uid() = follower_id OR auth.uid() = followed_id);

 -- Essential indexes for MVP performance

  -- Profiles
  CREATE INDEX idx_profiles_username ON public.profiles(username);

  -- User preferences
  CREATE INDEX idx_user_preferences_user_id ON public.user_preferences(user_id);

  -- Runs (most important for performance)
  CREATE INDEX idx_runs_user_id ON public.runs(user_id);
  CREATE INDEX idx_runs_started_at ON public.runs(started_at DESC);
  CREATE INDEX idx_runs_user_started ON public.runs(user_id, started_at DESC);
  CREATE INDEX idx_runs_external_id ON public.runs(external_id);

  -- Run routes
  CREATE INDEX idx_run_routes_run_id ON public.run_routes(run_id);
  CREATE INDEX idx_run_routes_coordinates ON public.run_routes USING GIN(coordinates);

  -- Run weather
  CREATE INDEX idx_run_weather_run_id ON public.run_weather(run_id);

  -- Ghosts
  CREATE INDEX idx_ghosts_user_id ON public.ghosts(user_id);
  CREATE INDEX idx_ghosts_type ON public.ghosts(ghost_type);
  CREATE INDEX idx_ghosts_active ON public.ghosts(is_active);
  CREATE INDEX idx_ghosts_public ON public.ghosts(is_public);

  -- Ghost race results
  CREATE INDEX idx_ghost_race_results_run_id ON public.ghost_race_results(run_id);
  CREATE INDEX idx_ghost_race_results_ghost_id ON public.ghost_race_results(ghost_id);

  -- OAuth connections
  CREATE INDEX idx_oauth_user_id ON public.user_oauth_connections(user_id);
  CREATE INDEX idx_oauth_provider ON public.user_oauth_connections(provider);

  -- User relationships
  CREATE INDEX idx_relationships_follower ON public.user_relationships(follower_id);
  CREATE INDEX idx_relationships_followed ON public.user_relationships(followed_id);
  CREATE INDEX idx_relationships_active_follows ON public.user_relationships(follower_id, followed_id) WHERE status = 'active';

  -- Functions for automatic profile creation
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

  -- Trigger to create profile when user signs up
  CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

  -- Function for updated_at timestamps
  CREATE OR REPLACE FUNCTION public.update_updated_at_column()
  RETURNS TRIGGER AS $$
  BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;

  -- Apply updated_at triggers
  CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_runs_updated_at BEFORE UPDATE ON public.runs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_ghosts_updated_at BEFORE UPDATE ON public.ghosts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  CREATE TRIGGER update_user_relationships_updated_at BEFORE UPDATE ON public.user_relationships FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

  -- Simple view for user run summary
  CREATE VIEW public.user_run_summary AS
  SELECT
      p.id as user_id,
      p.username,
      p.display_name,
      COUNT(r.id) as total_runs,
      COALESCE(SUM(r.distance), 0) as total_distance,
      COALESCE(SUM(r.moving_time), 0) as total_moving_time,
      COALESCE(AVG(r.average_pace), 0) as average_pace,
      COALESCE(MIN(r.average_pace), 0) as best_pace,
      MAX(r.started_at) as last_run_date
  FROM public.profiles p
  LEFT JOIN public.runs r ON p.id = r.user_id
  GROUP BY p.id, p.username, p.display_name;
