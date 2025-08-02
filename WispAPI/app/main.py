#!/usr/bin/env python3
"""
Wisp Backend Service - FastAPI Application
Handles Strava OAuth, ghost racing calculations, and complex business logic.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
from datetime import datetime

from .config import get_settings
from .routers import auth, strava
from .utils.supabase_client import get_supabase_client

# Initialize FastAPI app
app = FastAPI(
    title="Wisp Backend API",
    description="Backend service for Wisp running app - handles OAuth, analytics, and external integrations",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Get settings
settings = get_settings()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["authentication"])
app.include_router(strava.router, prefix="/strava", tags=["strava"])

@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "service": "Wisp Backend API",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat(),
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for deployment monitoring"""
    try:
        # Test Supabase connection
        supabase = get_supabase_client()
        # Simple query to test connection
        result = supabase.table("profiles").select("id").limit(1).execute()
        database_status = "connected"
    except Exception as e:
        database_status = f"disconnected: {str(e)}"
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0",
        "database": database_status,
        "environment": settings.environment
    }

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Global HTTP exception handler"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": True,
            "message": exc.detail,
            "status_code": exc.status_code,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unexpected errors"""
    return JSONResponse(
        status_code=500,
        content={
            "error": True,
            "message": "Internal server error",
            "status_code": 500,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", 8000)),
        reload=settings.debug
    )