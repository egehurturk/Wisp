#!/usr/bin/env python3
"""
Strava OAuth router
Handles Strava authentication flow, token management, and API integration.
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.responses import RedirectResponse
import httpx
import secrets
import hashlib
import base64
import logging
from datetime import datetime, timedelta
from typing import Optional
import json

from ..models.strava import (
    StravaAuthInitiateResponse,
    StravaCallbackRequest,
    StravaConnectionStatus,
    StravaDisconnectResponse,
    StravaTokenResponse,
    OAuthState
)
from ..routers.auth import get_current_user
from ..config import get_settings, StravaConstants
from ..utils.supabase_client import get_supabase_admin_client
from ..services.strava_service import StravaService

router = APIRouter()
logger = logging.getLogger(__name__)
settings = get_settings()

# In-memory store for OAuth states (in production, use Redis or database)
oauth_states = {}

def generate_pkce_verifier() -> str:
    """Generate PKCE code verifier (mimicking your Swift implementation)"""
    # Generate 128 random bytes and base64url encode
    verifier_bytes = secrets.token_bytes(96)  # 96 bytes = 128 chars base64url
    return base64.urlsafe_b64encode(verifier_bytes).decode('utf-8').rstrip('=')

def generate_pkce_challenge(verifier: str) -> str:
    """Generate PKCE code challenge from verifier"""
    digest = hashlib.sha256(verifier.encode('utf-8')).digest()
    return base64.urlsafe_b64encode(digest).decode('utf-8').rstrip('=')

@router.post("/initiate", response_model=StravaAuthInitiateResponse)
async def initiate_strava_oauth(current_user: str = Depends(get_current_user)):
    """
    Initiate Strava OAuth flow
    Returns authorization URL and state token for the mobile app
    """
    try:
        # Generate PKCE parameters (following your Swift implementation)
        code_verifier = generate_pkce_verifier()
        code_challenge = generate_pkce_challenge(code_verifier)
        state_token = secrets.token_urlsafe(32)
        
        # Store OAuth state temporarily (expires in 10 minutes)
        expires_at = datetime.utcnow() + timedelta(minutes=10)
        oauth_state = OAuthState(
            state_token=state_token,
            user_id=current_user,
            code_verifier=code_verifier,
            created_at=datetime.utcnow(),
            expires_at=expires_at
        )
        oauth_states[state_token] = oauth_state
        
        # Build Strava authorization URL (matching your Swift URL structure)
        auth_params = {
            "client_id": settings.strava_client_id,
            "redirect_uri": settings.strava_redirect_uri,
            "response_type": "code",
            "approval_prompt": "auto",
            "scope": StravaConstants.DEFAULT_SCOPE,
            "state": state_token,
            "code_challenge": code_challenge,
            "code_challenge_method": StravaConstants.CODE_CHALLENGE_METHOD
        }
        
        # Build URL
        auth_url = f"{StravaConstants.AUTHORIZATION_URL}?"
        auth_url += "&".join([f"{key}={value}" for key, value in auth_params.items()])
        
        logger.info(f"Generated Strava OAuth URL for user {current_user}")
        
        return StravaAuthInitiateResponse(
            auth_url=auth_url,
            state=state_token,
            expires_at=expires_at
        )
        
    except Exception as e:
        logger.error(f"Failed to initiate Strava OAuth: {e}")
        raise HTTPException(status_code=500, detail="Failed to initiate OAuth flow")


# This is called by Strava (via redirect) after login.
@router.post("/callback")
async def handle_strava_callback(
    callback_data: StravaCallbackRequest,
    background_tasks: BackgroundTasks
):
    """
    Handle Strava OAuth callback
    Exchanges authorization code for access tokens and stores them
    """
    try:
        # Validate state token
        if callback_data.state not in oauth_states:
            logger.error(f"Invalid or expired state token: {callback_data.state}")
            raise HTTPException(status_code=400, detail="Invalid or expired state token")
        
        oauth_state = oauth_states[callback_data.state]
        
        # Check expiration
        if datetime.utcnow() > oauth_state.expires_at:
            del oauth_states[callback_data.state]
            raise HTTPException(status_code=400, detail="State token expired")
        
        # Exchange code for tokens
        token_data = await exchange_code_for_tokens(
            code=callback_data.code,
            code_verifier=oauth_state.code_verifier
        )
        
        # Store tokens in database
        await store_strava_tokens(
            user_id=oauth_state.user_id,
            token_data=token_data
        )
        
        # Clean up state
        del oauth_states[callback_data.state]
        
        # Optionally sync initial data in background
        background_tasks.add_task(sync_initial_strava_data, oauth_state.user_id)
        
        logger.info(f"Successfully completed Strava OAuth for user {oauth_state.user_id}")
        
        return {
            "success": True,
            "message": "Strava account connected successfully",
            "athlete_id": token_data.athlete.get("id"),
            "athlete_name": f"{token_data.athlete.get('firstname', '')} {token_data.athlete.get('lastname', '')}".strip()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Callback handling failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to complete OAuth flow")

@router.get("/status", response_model=StravaConnectionStatus)
async def get_strava_status(current_user: str = Depends(get_current_user)):
    """Get current Strava connection status for user"""
    try:
        supabase = get_supabase_admin_client()
        
        # Query user's Strava connection
        result = supabase.table("user_oauth_connections").select(
            "provider, access_token, refresh_token, token_expires_at, metadata, connected_at"
        ).eq("user_id", current_user).eq("provider", "strava").execute()
        
        if not result.data:
            return StravaConnectionStatus(connected=False)
        
        connection = result.data[0]
        metadata = connection.get("metadata", {})
        
        # Check if token is expired
        expires_at = None
        if connection.get("token_expires_at"):
            expires_at = datetime.fromisoformat(connection["token_expires_at"].replace("Z", "+00:00"))

        
        return StravaConnectionStatus(
            connected=True,
            athlete_id=metadata.get("athlete_id"),
            athlete_name=metadata.get("athlete_name"),
            athlete_username=metadata.get("athlete_username"),
            connected_at=datetime.fromisoformat(connection["connected_at"].replace("Z", "+00:00")),
            token_expires_at=expires_at,
            scopes=metadata.get("scope")
        )
        
    except Exception as e:
        logger.error(f"Failed to get Strava status: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve connection status")

@router.delete("/disconnect", response_model=StravaDisconnectResponse)
async def disconnect_strava(current_user: str = Depends(get_current_user)):
    """Disconnect Strava account and revoke tokens"""
    try:
        supabase = get_supabase_admin_client()
        
        # Get current connection to revoke token
        result = supabase.table("user_oauth_connections").select(
            "access_token"
        ).eq("user_id", current_user).eq("provider", "strava").execute()
        
        if result.data:
            # Revoke token with Strava (optional but recommended)
            access_token = result.data[0]["access_token"]
            await revoke_strava_token(access_token)
        
        # Delete connection from database
        supabase.table("user_oauth_connections").delete().eq(
            "user_id", current_user
        ).eq("provider", "strava").execute()
        
        logger.info(f"Disconnected Strava for user {current_user}")
        
        return StravaDisconnectResponse(success=True)
        
    except Exception as e:
        logger.error(f"Failed to disconnect Strava: {e}")
        raise HTTPException(status_code=500, detail="Failed to disconnect Strava account")

# Helper Functions

async def exchange_code_for_tokens(code: str, code_verifier: str) -> StravaTokenResponse:
    """Exchange authorization code for access tokens (mimicking your Swift implementation)"""
    
    token_data = {
        "client_id": settings.strava_client_id,
        "client_secret": settings.strava_client_secret,
        "code": code,
        "grant_type": "authorization_code"
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(
            StravaConstants.TOKEN_URL,
            data=token_data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=30.0
        )
        
        if response.status_code != 200:
            logger.error(f"Token exchange failed: {response.status_code} - {response.text}")
            if response.status_code == 400:
                raise HTTPException(status_code=400, detail="Invalid authorization code")
            elif response.status_code == 401:
                raise HTTPException(status_code=401, detail="Invalid client credentials")
            else:
                raise HTTPException(status_code=500, detail="Token exchange failed")
        
        token_response = response.json()
        return StravaTokenResponse(**token_response)

async def store_strava_tokens(user_id: str, token_data: StravaTokenResponse):
    """Store Strava tokens in database"""
    supabase = get_supabase_admin_client()
    
    # Calculate expiration datetime
    expires_at = datetime.utcnow() + timedelta(seconds=token_data.expires_in)
    
    # Prepare athlete metadata
    athlete = token_data.athlete
    metadata = {
        "athlete_id": athlete.get("id"),
        "athlete_username": athlete.get("username"),
        "athlete_name": f"{athlete.get('firstname', '')} {athlete.get('lastname', '')}".strip(),
        "athlete_firstname": athlete.get("firstname"),
        "athlete_lastname": athlete.get("lastname"),
        "scope": "read,activity:read"  # Store granted scope
    }
    logger.info(athlete)
    # Upsert connection record
    connection_data = {
        "user_id": user_id,
        "provider": "strava",
        "provider_user_id": athlete.get("id"),
        "access_token": token_data.access_token,
        "refresh_token": token_data.refresh_token,
        "token_expires_at": expires_at.isoformat(),
        "metadata": metadata
    }
    
    # Use upsert to handle existing connections
    supabase.table("user_oauth_connections").upsert(
        connection_data,
        on_conflict="user_id,provider"
    ).execute()
    
    logger.info(f"Stored Strava tokens for user {user_id}, athlete {athlete.get('id')}")

async def revoke_strava_token(access_token: str):
    """Revoke Strava access token"""
    try:
        revoke_data = {
            "access_token": access_token
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://www.strava.com/oauth/deauthorize",
                data=revoke_data,
                timeout=10.0
            )
            
        if response.status_code == 200:
            logger.info("Successfully revoked Strava token")
        else:
            logger.warning(f"Token revocation returned status {response.status_code}")
            
    except Exception as e:
        logger.warning(f"Failed to revoke Strava token: {e}")

async def sync_initial_strava_data(user_id: str):
    """Background task to sync initial Strava data"""
    try:
        strava_service = StravaService()
        await strava_service.sync_recent_activities(user_id, limit=10)
        logger.info(f"Completed initial Strava data sync for user {user_id}")
    except Exception as e:
        logger.error(f"Initial Strava sync failed for user {user_id}: {e}")

# Cleanup task for expired OAuth states
async def cleanup_expired_states():
    """Remove expired OAuth states"""
    current_time = datetime.utcnow()
    expired_states = [
        state for state, data in oauth_states.items()
        if data.expires_at < current_time
    ]
    
    for state in expired_states:
        del oauth_states[state]
    
    if expired_states:
        logger.info(f"Cleaned up {len(expired_states)} expired OAuth states")