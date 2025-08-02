#!/usr/bin/env python3
"""
Supabase client configuration and utilities
Provides authenticated Supabase clients for database operations.
"""

from supabase import create_client, Client
from functools import lru_cache
import logging

from ..config import get_settings

logger = logging.getLogger(__name__)

@lru_cache()
def get_supabase_client() -> Client:
    """Get Supabase client with anon key (for RLS-protected operations)"""
    settings = get_settings()
    
    if not settings.supabase_url or not settings.supabase_anon_key:
        raise ValueError("Supabase URL and anon key must be configured")
    
    try:
        client = create_client(settings.supabase_url, settings.supabase_anon_key)
        logger.info("Supabase client initialized successfully")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Supabase client: {e}")
        raise

@lru_cache()
def get_supabase_admin_client() -> Client:
    """Get Supabase client with service role key (for admin operations)"""
    settings = get_settings()
    
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise ValueError("Supabase URL and service role key must be configured")
    
    try:
        client = create_client(settings.supabase_url, settings.supabase_service_role_key)
        logger.info("Supabase admin client initialized successfully")
        return client
    except Exception as e:
        logger.error(f"Failed to initialize Supabase admin client: {e}")
        raise

def verify_user_token(token: str) -> dict:
    """Verify JWT token and return user information"""
    try:
        supabase = get_supabase_client()
        user = supabase.auth.get_user(token)
        return user.user
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise ValueError("Invalid or expired token")

def get_user_from_token(token: str) -> str:
    """Extract user ID from JWT token"""
    user_data = verify_user_token(token)
    return user_data.id