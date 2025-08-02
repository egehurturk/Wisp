#!/usr/bin/env python3
"""
Authentication router
Handles user authentication and token validation.
"""

from fastapi import APIRouter, Depends, HTTPException, Header
from typing import Optional
import logging

from ..utils.supabase_client import verify_user_token, get_user_from_token

router = APIRouter()
logger = logging.getLogger(__name__)

async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """Dependency to get current authenticated user from JWT token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    
    try:
        # Extract token from "Bearer <token>"
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        
        token = authorization.split(" ")[1]
        user_id = get_user_from_token(token)
        return user_id
        
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")

@router.get("/me")
async def get_current_user_info(current_user: str = Depends(get_current_user)):
    """Get current user information"""
    return {
        "user_id": current_user,
        "authenticated": True
    }

@router.post("/validate")
async def validate_token(authorization: Optional[str] = Header(None)):
    """Validate JWT token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        
        token = authorization.split(" ")[1]
        user_data = verify_user_token(token)
        
        return {
            "valid": True,
            "user_id": user_data.id,
            "email": user_data.email
        }
        
    except Exception as e:
        return {
            "valid": False,
            "error": str(e)
        }