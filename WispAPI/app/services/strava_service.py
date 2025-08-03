#!/usr/bin/env python3
"""
Strava API service
Handles token refresh, data synchronization, and API requests.
"""

import httpx
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any

from ..config import get_settings, StravaConstants
from ..utils.supabase_client import get_supabase_admin_client
from ..models.strava import StravaActivity, StravaAthlete

logger = logging.getLogger(__name__)
settings = get_settings()

class StravaService:
    """Service for Strava API interactions and token management"""
    
    def __init__(self):
        self.supabase = get_supabase_admin_client()
    
    async def get_valid_access_token(self, user_id: str) -> Optional[str]:
        """
        Get valid access token for user, refreshing if necessary
        """
        try:
            # Get current token data
            result = self.supabase.table("user_oauth_connections").select(
                "access_token, refresh_token, token_expires_at"
            ).eq("user_id", user_id).eq("provider", "strava").execute()
            
            if not result.data:
                logger.warning(f"No Strava connection found for user {user_id}")
                return None
            
            connection = result.data[0]
            access_token = connection["access_token"]
            refresh_token = connection["refresh_token"]
            expires_at_str = connection.get("token_expires_at")
            
            # Check if token needs refresh (with 5 minute buffer)
            if expires_at_str:
                expires_at = datetime.fromisoformat(expires_at_str.replace("Z", "+00:00"))
                if expires_at <= datetime.utcnow() + timedelta(minutes=5):
                    logger.info(f"Token expires soon for user {user_id}, refreshing...")
                    new_token = await self._refresh_access_token(user_id, refresh_token)
                    return new_token
            else:
                # No expiration date, refresh as precaution
                logger.warning(f"No token expiration date for user {user_id}, refreshing as precaution")
                new_token = await self._refresh_access_token(user_id, refresh_token)
                return new_token
            
            return access_token
            
        except Exception as e:
            logger.error(f"Failed to get valid access token for user {user_id}: {e}")
            return None
    
    async def _refresh_access_token(self, user_id: str, refresh_token: str) -> Optional[str]:
        """
        Refresh Strava access token
        """
        try:
            refresh_data = {
                "client_id": settings.strava_client_id,
                "client_secret": settings.strava_client_secret,
                "grant_type": "refresh_token",
                "refresh_token": refresh_token
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    StravaConstants.TOKEN_URL,
                    data=refresh_data,
                    headers={"Content-Type": "application/x-www-form-urlencoded"},
                    timeout=30.0
                )
                
                if response.status_code != 200:
                    if response.status_code in [400, 401]:
                        logger.error(f"Token refresh failed - refresh token may be expired for user {user_id}")
                        # Clear invalid tokens (matching Swift behavior)
                        await self._clear_invalid_tokens(user_id)
                    return None
                
                token_data = response.json()
                new_access_token = token_data["access_token"]
                new_refresh_token = token_data.get("refresh_token", refresh_token)  # Strava may not return new refresh token
                expires_in = token_data.get("expires_in", StravaConstants.TOKEN_EXPIRY_SECONDS)
                
                # Update tokens in database
                expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
                
                self.supabase.table("user_oauth_connections").update({
                    "access_token": new_access_token,
                    "refresh_token": new_refresh_token,
                    "token_expires_at": expires_at.isoformat()
                }).eq("user_id", user_id).eq("provider", "strava").execute()
                
                logger.info(f"Successfully refreshed token for user {user_id}")
                return new_access_token
                
        except Exception as e:
            logger.error(f"Token refresh failed for user {user_id}: {e}")
            return None
    
    async def _clear_invalid_tokens(self, user_id: str):
        """Clear invalid tokens from database"""
        try:
            self.supabase.table("user_oauth_connections").delete().eq(
                "user_id", user_id
            ).eq("provider", "strava").execute()
            logger.info(f"Cleared invalid Strava tokens for user {user_id}")
        except Exception as e:
            logger.error(f"Failed to clear invalid tokens for user {user_id}: {e}")
    
    async def fetch_athlete_activities(
        self, 
        user_id: str, 
        per_page: int = 200, 
        page: int = 1
    ) -> List[StravaActivity]:
        """
        Fetch athlete activities from Strava API
        """
        print("Starting fetch...")
        access_token = await self.get_valid_access_token(user_id)
        if not access_token:
            raise Exception("No valid access token available")
        
        try:
            # Build URL
            url = f"{StravaConstants.API_BASE_URL}/athlete/activities"
            params = {"per_page": per_page, "page": page}
            
            print("Getting runs...")
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    url,
                    params=params,
                    headers={
                        "Authorization": f"Bearer {access_token}",
                        "Accept": "application/json"
                    },
                    timeout=30.0
                )
                
                if response.status_code == 401:
                    logger.error(f"Unauthorized API request for user {user_id}")
                    await self._clear_invalid_tokens(user_id)
                    raise Exception("Unauthorized - token may be invalid")
                
                if response.status_code != 200:
                    raise Exception(f"API request failed with status {response.status_code}")
                
                activities_data = response.json()
                logger.info(activities_data)
                activities = [StravaActivity(**activity) for activity in activities_data]
                
                # Filter for runs (matching your Swift filtering)
                runs = [activity for activity in activities if activity.type == "Run"]
                print("Got runs...")
                print(f"Fetched {len(activities)} total activities, {len(runs)} runs for user {user_id}")
                
                return runs
                
        except Exception as e:
            print("Did not get runs...")
            logger.error(f"Failed to fetch activities for user {user_id}: {e}")
            raise
    
    async def sync_recent_activities(self, user_id: str, limit: int = 10):
        """Sync recent activities and store in database"""
        try:
            activities = await self.fetch_athlete_activities(user_id, per_page=limit)
            
            for activity in activities:
                await self._store_activity_in_database(user_id, activity)
            
            logger.info(f"Synced {len(activities)} activities for user {user_id}")
            
        except Exception as e:
            logger.error(f"Activity sync failed for user {user_id}: {e}")
            raise
    
    async def _store_activity_in_database(self, user_id: str, activity: StravaActivity):
        """Store Strava activity in runs table"""
        try:
            # Convert Strava activity to run data
            run_data = {
                "user_id": user_id,
                "external_id": str(activity.id),
                "data_source": "strava",
                "title": activity.name,
                "description": activity.description,
                "distance": activity.distance,
                "moving_time": activity.moving_time,
                "elapsed_time": activity.elapsed_time,
                "average_speed": activity.average_speed,
                "average_cadence": activity.average_cadence,
                "average_heart_rate": activity.average_heartrate,
                "max_heart_rate": activity.max_heartrate,
                "calories_burned": int(activity.calories) if activity.calories else None,
                "elevation_gain": activity.total_elevation_gain,
                "started_at": activity.start_date,
                "timezone": activity.timezone
            }
            
            # Handle GPS coordinates
            if activity.start_latlng and len(activity.start_latlng) >= 2:
                run_data["start_latitude"] = activity.start_latlng[0]
                run_data["start_longitude"] = activity.start_latlng[1]
            
            if activity.end_latlng and len(activity.end_latlng) >= 2:
                run_data["end_latitude"] = activity.end_latlng[0]
                run_data["end_longitude"] = activity.end_latlng[1]
            
            # Calculate average pace (seconds per kilometer)
            if activity.distance > 0:
                run_data["average_pace"] = activity.moving_time / (activity.distance / 1000)
            
            # Use upsert to handle existing activities
            self.supabase.table("runs").upsert(
                run_data,
                on_conflict="user_id,external_id"
            ).execute()
            
            # Store route data if available
            if activity.polyline:
                await self._store_route_data(run_data.get("id"), activity.polyline)
            
        except Exception as e:
            logger.error(f"Failed to store activity {activity.id} for user {user_id}: {e}")
    
    async def _store_route_data(self, run_id: str, polyline: str):
        """Store route polyline data"""
        try:
            if not run_id:
                return
                
            route_data = {
                "run_id": run_id,
                "encoded_polyline": polyline,
                "coordinates": [],  # Polyline decode would go here
                "total_points": 0
            }
            
            self.supabase.table("run_routes").upsert(
                route_data,
                on_conflict="run_id"
            ).execute()
            
        except Exception as e:
            logger.error(f"Failed to store route data for run {run_id}: {e}")

# TODO:
#   * Change for run in runs -> store run db TO bulk insertion
#   * Inspect Strava RUn type to see if it matches db
#   * Log issues?