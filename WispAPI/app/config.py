#!/usr/bin/env python3
"""
Configuration management for Wisp Backend Service
Handles environment variables and application settings.
"""

import os
from typing import List
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    """Application settings from environment variables"""
    
    # Application Settings
    environment: str = "development"
    debug: bool = True
    secret_key: str = "your-secret-key-change-in-production"
    
    # CORS Settings  
    cors_origins: str = "http://localhost:3000,https://your-app.com"
    
    # Supabase Configuration
    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_role_key: str = ""
    
    # Strava OAuth Configuration
    strava_client_id: str = ""
    strava_client_secret: str = ""
    strava_redirect_uri: str = "http://localhost:8000/strava/callback"
    
    # External APIs
    weather_api_key: str = ""
    
    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8"
    }
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins string into list"""
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings"""
    return Settings()

# Strava OAuth Constants (matching your Swift implementation)
class StravaConstants:
    """Strava API constants and endpoints"""
    
    # OAuth Endpoints
    AUTHORIZATION_URL = "https://www.strava.com/oauth/mobile/authorize"
    MOBILE_AUTHORIZATION_URL = "strava://oauth/mobile/authoriz"
    TOKEN_URL = "https://www.strava.com/oauth/token"
    
    # API Base
    API_BASE_URL = "https://www.strava.com/api/v3"
    
    # OAuth Scopes
    DEFAULT_SCOPE = "read,activity:read"
    
    # PKCE Settings
    CODE_CHALLENGE_METHOD = "S256"
    
    # Token Settings
    TOKEN_EXPIRY_SECONDS = 21600  # 6 hours (Strava default)
    REFRESH_BUFFER_SECONDS = 300   # 5 minutes buffer before expiry