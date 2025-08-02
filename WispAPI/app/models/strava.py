#!/usr/bin/env python3
"""
Strava OAuth and API data models
Pydantic models for Strava authentication and API responses.
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

# OAuth Flow Models

class StravaAuthInitiateRequest(BaseModel):
    """Request to initiate Strava OAuth flow"""
    user_token: str = Field(..., description="Supabase JWT token for user authentication")

class StravaAuthInitiateResponse(BaseModel):
    """Response for OAuth initiation"""
    auth_url: str = Field(..., description="Strava authorization URL for user")
    state: str = Field(..., description="State token for CSRF protection")
    expires_at: datetime = Field(..., description="When the state token expires")

class StravaCallbackRequest(BaseModel):
    """Strava OAuth callback parameters"""
    code: str = Field(..., description="Authorization code from Strava")
    state: str = Field(..., description="State token for validation")
    scope: Optional[str] = Field(None, description="Granted scope from Strava")

class StravaTokenResponse(BaseModel):
    """Strava token exchange response"""
    access_token: str
    refresh_token: str
    expires_at: int
    expires_in: int
    token_type: str = "Bearer"
    athlete: Dict[str, Any]

# API Response Models

class StravaAthlete(BaseModel):
    """Strava athlete information"""
    id: int
    username: Optional[str] = None
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    profile_medium: Optional[str] = None
    profile: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    sex: Optional[str] = None
    premium: Optional[bool] = None
    summit: Optional[bool] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

class StravaActivity(BaseModel):
    """Strava activity data"""
    id: int
    external_id: Optional[str] = None
    name: str
    description: Optional[str] = None
    distance: float  # meters
    moving_time: int  # seconds
    elapsed_time: int  # seconds
    total_elevation_gain: Optional[float] = None
    type: str
    start_date: str
    start_date_local: str
    timezone: Optional[str] = None
    average_speed: Optional[float] = None
    max_speed: Optional[float] = None
    average_cadence: Optional[float] = None
    average_heartrate: Optional[float] = None
    max_heartrate: Optional[float] = None
    calories: Optional[float] = None
    start_latlng: Optional[list] = None
    end_latlng: Optional[list] = None
    polyline: Optional[str] = None

# Status and Management Models

class StravaConnectionStatus(BaseModel):
    """Strava connection status for a user"""
    connected: bool
    athlete_id: Optional[int] = None
    athlete_name: Optional[str] = None
    athlete_username: Optional[str] = None
    connected_at: Optional[datetime] = None
    token_expires_at: Optional[datetime] = None
    scopes: Optional[str] = None

class StravaDisconnectResponse(BaseModel):
    """Response for disconnecting Strava"""
    success: bool
    message: str = "Strava account disconnected successfully"

# Internal State Models

class OAuthState(BaseModel):
    """OAuth state stored temporarily during flow"""
    state_token: str
    user_id: str
    code_verifier: str
    created_at: datetime
    expires_at: datetime

# Error Models

class StravaError(BaseModel):
    """Strava API error response"""
    error: str
    message: str
    details: Optional[Dict[str, Any]] = None