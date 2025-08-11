#!/usr/bin/env python3
"""
Runs API router - handles run data retrieval and management
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional, Union
from datetime import datetime, timedelta
import uuid

from ..utils.supabase_client import get_supabase_client
from ..routers.auth import get_current_user

# Initialize router
router = APIRouter()

# Response models
from pydantic import BaseModel, Field
from typing import Dict, Any

class Coordinate(BaseModel):
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    altitude: Optional[float] = Field(None, description="Altitude in meters")
    timestamp: Optional[datetime] = Field(None, description="Timestamp of coordinate")
    accuracy: Optional[float] = Field(None, description="GPS accuracy in meters")

class PaceSplit(BaseModel):
    distance_meters: float = Field(..., description="Distance of split in meters")
    time_seconds: int = Field(..., description="Time for split in seconds")
    pace_seconds_per_meter: float = Field(..., description="Pace in seconds per meter")
    elevation_gain: Optional[float] = Field(None, description="Elevation gain in meters")

class HeartRatePoint(BaseModel):
    timestamp: datetime = Field(..., description="Timestamp of heart rate reading")
    heart_rate: int = Field(..., description="Heart rate in BPM")
    distance_meters: Optional[float] = Field(None, description="Distance at this point")

class Run(BaseModel):
    id: str = Field(..., description="Run UUID")
    user_id: str = Field(..., description="User UUID")
    external_id: Optional[str] = Field(None, description="External service ID (e.g., Strava)")
    data_source: str = Field(..., description="Source of run data (app/strava/imported)")
    title: Optional[str] = Field(None, description="Custom run title")
    description: Optional[str] = Field(None, description="Run description")
    distance: float = Field(..., description="Distance in meters")
    moving_time: int = Field(..., description="Moving time in seconds")
    elapsed_time: int = Field(..., description="Elapsed time in seconds")
    average_pace: Optional[float] = Field(None, description="Average pace in seconds per meter")
    average_speed: Optional[float] = Field(None, description="Average speed in m/s")
    average_cadence: Optional[float] = Field(None, description="Average cadence")
    average_heart_rate: Optional[float] = Field(None, description="Average heart rate")
    max_heart_rate: Optional[float] = Field(None, description="Maximum heart rate")
    calories_burned: Optional[float] = Field(None, description="Calories burned")
    start_latitude: Optional[float] = Field(None, description="Start latitude")
    start_longitude: Optional[float] = Field(None, description="Start longitude")
    end_latitude: Optional[float] = Field(None, description="End latitude")
    end_longitude: Optional[float] = Field(None, description="End longitude")
    elevation_gain: Optional[float] = Field(None, description="Total elevation gain")
    started_at: datetime = Field(..., description="Run start time")
    timezone: Optional[str] = Field(None, description="Timezone of run")
    pace_splits: Optional[List[PaceSplit]] = Field(None, description="Pace splits")
    heart_rate_data: Optional[List[HeartRatePoint]] = Field(None, description="Heart rate data")
    created_at: datetime = Field(..., description="Record creation time")
    updated_at: datetime = Field(..., description="Record update time")

class RunRoute(BaseModel):
    id: str = Field(..., description="Route UUID")
    run_id: str = Field(..., description="Run UUID")
    coordinates: List[Coordinate] = Field(..., description="GPS coordinates")
    encoded_polyline: Optional[str] = Field(None, description="Encoded polyline string")
    total_points: int = Field(..., description="Total number of coordinate points")
    created_at: datetime = Field(..., description="Record creation time")

class RunsResponse(BaseModel):
    runs: List[Run] = Field(..., description="List of runs")
    total_count: int = Field(..., description="Total number of runs")
    has_more: bool = Field(..., description="Whether there are more runs")
    next_cursor: Optional[str] = Field(None, description="Cursor for pagination")

class RunResponse(BaseModel):
    run: Run = Field(..., description="Single run data")

class RunRouteResponse(BaseModel):
    route: RunRoute = Field(..., description="Run route data")

# API Endpoints

@router.get("/runs", response_model=RunsResponse)
async def get_runs(
    current_user: str = Depends(get_current_user),
    limit: int = Query(20, ge=1, le=100, description="Number of runs to return"),
    offset: int = Query(0, ge=0, description="Number of runs to skip"),
    sort_by: str = Query("started_at", description="Field to sort by"),
    sort_order: str = Query("desc", regex="^(asc|desc)$", description="Sort order"),
    data_source: Optional[str] = Query(None, description="Filter by data source"),
    date_from: Optional[datetime] = Query(None, description="Filter runs from this date"),
    date_to: Optional[datetime] = Query(None, description="Filter runs until this date"),
    search: Optional[str] = Query(None, description="Search in title and description")
):
    """
    Get paginated list of user runs with optional filtering and sorting
    """
    try:
        supabase = get_supabase_client()
        
        # Build query
        query = supabase.table("runs").select("*", count="exact")
        
        # Apply user filter
        query = query.eq("user_id", current_user)
        
        # Apply filters
        if data_source:
            query = query.eq("data_source", data_source)
        
        if date_from:
            query = query.gte("started_at", date_from.isoformat())
        
        if date_to:
            query = query.lte("started_at", date_to.isoformat())
        
        if search:
            # Search in title and description
            query = query.or_(f"title.ilike.%{search}%,description.ilike.%{search}%")
        
        # Apply sorting
        if sort_order == "desc":
            query = query.order(sort_by, desc=True)
        else:
            query = query.order(sort_by, desc=False)
        
        # Apply pagination
        query = query.range(offset, offset + limit - 1)
        
        # Execute query
        result = query.execute()
        
        # Format response
        runs = [Run(**run) for run in result.data]
        total_count = result.count if result.count is not None else len(runs)
        has_more = len(result.data) == limit
        
        return RunsResponse(
            runs=runs,
            total_count=total_count,
            has_more=has_more,
            next_cursor=str(offset + limit) if has_more else None
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch runs: {str(e)}")

@router.get("/runs/latest", response_model=RunResponse)
async def get_latest_run(
    current_user: str = Depends(get_current_user)
):
    """
    Get the latest run for the user (for home page)
    """
    try:
        supabase = get_supabase_client()
        
        # Get the most recent run
        result = supabase.table("runs").select("*").eq("user_id", current_user).order("started_at", desc=True).limit(1).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="No runs found")
        
        run = Run(**result.data[0])
        return RunResponse(run=run)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch latest run: {str(e)}")

@router.get("/runs/{run_id}", response_model=RunResponse)
async def get_run(
    run_id: str,
    current_user: str = Depends(get_current_user)
):
    """
    Get a specific run by ID
    """
    try:
        # Validate UUID format
        uuid.UUID(run_id)
        
        supabase = get_supabase_client()
        
        # Get run with user verification
        result = supabase.table("runs").select("*").eq("id", run_id).eq("user_id", current_user).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Run not found")
        
        run = Run(**result.data[0])
        return RunResponse(run=run)
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid run ID format")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch run: {str(e)}")

@router.get("/runs/{run_id}/route", response_model=RunRouteResponse)
async def get_run_route(
    run_id: str,
    current_user: str = Depends(get_current_user),
    coordinates_only: bool = Query(False, description="Return only coordinates, not encoded polyline")
):
    """
    Get GPS route data for a specific run
    """
    try:
        # Validate UUID format
        uuid.UUID(run_id)
        
        supabase = get_supabase_client()
        
        # First verify the run belongs to the user
        run_result = supabase.table("runs").select("id").eq("id", run_id).eq("user_id", current_user).execute()
        
        if not run_result.data:
            raise HTTPException(status_code=404, detail="Run not found")
        
        # Get route data
        select_fields = "id, run_id, coordinates, total_points, created_at"
        if not coordinates_only:
            select_fields += ", encoded_polyline"
        
        result = supabase.table("run_routes").select(select_fields).eq("run_id", run_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Route not found for this run")
        
        route_data = result.data[0]
        
        # Convert coordinates from JSONB
        coordinates = []
        if route_data.get("coordinates"):
            for coord in route_data["coordinates"]:
                coordinates.append(Coordinate(**coord))
        
        route = RunRoute(
            id=route_data["id"],
            run_id=route_data["run_id"],
            coordinates=coordinates,
            encoded_polyline=route_data.get("encoded_polyline"),
            total_points=route_data["total_points"],
            created_at=route_data["created_at"]
        )
        
        return RunRouteResponse(route=route)
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid run ID format")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch run route: {str(e)}")

@router.get("/runs/{run_id}/route/polyline")
async def get_run_route_polyline(
    run_id: str,
    current_user: str = Depends(get_current_user),
    format: str = Query("geojson", regex="^(geojson|coordinates)$", description="Return format")
):
    """
    Get route polyline in different formats (optimized for map rendering)
    """
    try:
        # Validate UUID format
        uuid.UUID(run_id)
        
        supabase = get_supabase_client()
        
        # First verify the run belongs to the user
        run_result = supabase.table("runs").select("id").eq("id", run_id).eq("user_id", current_user).execute()
        
        if not run_result.data:
            raise HTTPException(status_code=404, detail="Run not found")
        
        # Get route data
        result = supabase.table("run_routes").select("coordinates, encoded_polyline").eq("run_id", run_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Route not found for this run")
        
        route_data = result.data[0]
        
        if format == "geojson":
            # Return GeoJSON LineString
            coordinates = []
            if route_data.get("coordinates"):
                for coord in route_data["coordinates"]:
                    coordinates.append([coord["longitude"], coord["latitude"]])
            
            return {
                "type": "Feature",
                "geometry": {
                    "type": "LineString",
                    "coordinates": coordinates
                },
                "properties": {
                    "run_id": run_id
                }
            }
        else:
            # Return simple coordinates array
            coordinates = []
            if route_data.get("coordinates"):
                for coord in route_data["coordinates"]:
                    coordinates.append({
                        "latitude": coord["latitude"],
                        "longitude": coord["longitude"],
                        "altitude": coord.get("altitude"),
                        "timestamp": coord.get("timestamp"),
                        "accuracy": coord.get("accuracy")
                    })
            
            return {
                "coordinates": coordinates,
                "encoded_polyline": route_data.get("encoded_polyline"),
                "total_points": len(coordinates)
            }
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid run ID format")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch run route: {str(e)}")

@router.get("/stats/summary")
async def get_run_stats_summary(
    current_user: str = Depends(get_current_user),
    period: str = Query("all_time", regex="^(this_week|this_month|this_year|all_time)$", description="Time period for stats")
):
    """
    Get summary statistics for user's runs
    """
    try:
        supabase = get_supabase_client()
        
        # Calculate date filter based on period
        now = datetime.utcnow()
        date_filter = None
        
        if period == "this_week":
            date_filter = (now - timedelta(weeks=1)).isoformat()
        elif period == "this_month":
            date_filter = (now - timedelta(days=30)).isoformat()
        elif period == "this_year":
            date_filter = (now - timedelta(days=365)).isoformat()
        
        # Build query
        query = supabase.table("runs").select("distance, moving_time, calories_burned, elevation_gain").eq("user_id", current_user)
        
        if date_filter:
            query = query.gte("started_at", date_filter)
        
        result = query.execute()
        
        if not result.data:
            return {
                "period": period,
                "total_runs": 0,
                "total_distance": 0,
                "total_time": 0,
                "total_calories": 0,
                "total_elevation_gain": 0,
                "average_distance": 0,
                "average_pace": 0
            }
        
        # Calculate statistics
        runs = result.data
        total_runs = len(runs)
        total_distance = sum(run.get("distance", 0) for run in runs)
        total_time = sum(run.get("moving_time", 0) for run in runs)
        total_calories = sum(run.get("calories_burned", 0) or 0 for run in runs)
        total_elevation_gain = sum(run.get("elevation_gain", 0) or 0 for run in runs)
        
        average_distance = total_distance / total_runs if total_runs > 0 else 0
        average_pace = (total_time / total_distance) if total_distance > 0 else 0
        
        return {
            "period": period,
            "total_runs": total_runs,
            "total_distance": total_distance,
            "total_time": total_time,
            "total_calories": total_calories,
            "total_elevation_gain": total_elevation_gain,
            "average_distance": average_distance,
            "average_pace": average_pace
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch run stats: {str(e)}")