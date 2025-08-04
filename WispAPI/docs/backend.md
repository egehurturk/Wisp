# Wisp Backend Service Documentation

## Architecture Overview

### Tech Stack
- **Backend Framework**: FastAPI (Python 3.11+)
- **Database**: Supabase PostgreSQL with existing schema
- **Authentication**: Supabase Auth with JWT tokens
- **External APIs**: Strava API, Weather APIs
- **Deployment**: Railway/Fly.io/Digital Ocean App Platform (?)

### Architecture Pattern
```
iOS App (SwiftUI) 
    ↓ HTTP
FastAPI Python Service 
    ↓ SQL/REST
Supabase (Database + Auth + Storage)
    ↓ API calls
External Services (Strava, Weather APIs)
```

## Core Responsibilities

### Backend Service Handles
1. **External API Integrations**
   - Strava OAuth flow and data synchronization
   - Weather API integration for historical/real-time data
   - Future integrations (Apple Health, Google Fit, etc.)

2. **Background Processing**
   - Data import jobs (Strava activities)
   - Analytics calculations (for future implementation)
   - Notification sending (for future webhooks implementation)

### Supabase Handles
1. **Data Persistence**
   - All CRUD operations via existing database schema
   - Row Level Security (RLS) for data privacy
   - Real-time database subscriptions

2. **User Management**
   - Authentication and JWT token management
   - OAuth provider integration (Strava, Google)
   - User session management

3. **File Storage**
   - Run photos and videos
   - Profile images
   - Route thumbnails and media


## Key Features Implementation

### 3. Strava Integration
```python
class StravaService:
    """Complete Strava API integration"""
    ...
```

See `app/services/strava_service.py` and `app/routers/strava.py` for integrating Strava with python.

## Development Setup

### Environment Variables
```bash
# Environment Configuration for Wisp Backend

# Application Settings
ENVIRONMENT=development
DEBUG=True
SECRET_KEY=wisp-backend-secret-key-2025

# Supabase Configuration
SUPABASE_URL=https://tcpvmldytbxoyslrobot.supabase.co
SUPABASE_ANON_KEY=e...
SUPABASE_SERVICE_ROLE_KEY=...

# Strava OAuth Configuration
STRAVA_CLIENT_ID=...
STRAVA_CLIENT_SECRET=...
STRAVA_REDIRECT_URI=http://localhost:8000/strava/callback

# External APIs
WEATHER_API_KEY=your-weather-api-key

# CORS Origins (comma-separated)
CORS_ORIGINS=http://localhost:3000,http://localhost:8000,wisp://
```

### Project Structure
```
wisp-backend/
├── app/
│   ├── main.py                 # FastAPI application
│   ├── config.py              # Configuration management
│   ├── dependencies.py        # Auth and common dependencies
│   ├── routers/               # API route handlers
│   │   ├── auth.py
│   │   ├── runs.py
│   │   ├── ghosts.py
│   │   ├── social.py
│   │   └── strava.py
│   ├── services/              # Business logic
│   │   ├── ghost_racing.py
│   │   ├── analytics.py
│   │   ├── strava_service.py
│   │   └── weather_service.py
│   ├── models/                # Pydantic models
│   │   ├── user.py
│   │   ├── run.py
│   │   ├── ghost.py
│   │   └── responses.py
│   ├── utils/                 # Utilities
│       ├── supabase_client.py
│       ├── auth_utils.py
│       └── ml_utils.py
│  
├── tests/                     # Test suite
├── requirements.txt           # Python dependencies
├── Dockerfile                # Container configuration
└── README.md                 # Setup instructions
```



## Deployment Considerations

### Railway Deployment
```toml
# railway.toml
[build]
builder = "NIXPACKS"

[deploy]
healthcheckPath = "/health"
restartPolicyType = "ON_FAILURE"

[env]
PORT = { default = "8000" }
```

### Health Checks
```python
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
```

### Performance Optimizations
1. **Caching Strategy**
   - Redis for frequently accessed data
   - Cache ghost calculations and analytics
   - Cache external API responses

2. **Database Optimization**
   - Use connection pooling
   - Implement database query optimization
   - Leverage Supabase's built-in caching

3. **API Rate Limiting**
   - Implement rate limiting for external APIs
   - Respect Strava API limits
   - Cache weather data appropriately

## Security Implementation

### Authentication Flow
1. iOS app authenticates with Supabase
2. Supabase returns JWT token
3. iOS app includes JWT in API requests
4. Backend validates JWT with Supabase
5. RLS policies automatically enforce data access

### Data Privacy
- All database operations respect existing RLS policies
- User data isolation maintained automatically
- OAuth tokens encrypted at rest
- Sensitive operations require additional validation

## Integration with iOS App

### API Communication
- iOS app makes HTTP requests to FastAPI endpoints
- JWT tokens for authentication
- JSON responses matching existing model structures

### Data Synchronization
- Offline-first approach with sync when online
- Conflict resolution for concurrent updates
- Progressive data loading for large datasets
- Background sync for non-critical updates

## Monitoring and Observability

### Logging Strategy
- Structured logging with JSON format
- Request/response logging for debugging
- Performance metrics tracking
- Error tracking and alerting

### Analytics
- API usage metrics
- Performance bottleneck identification
- User behavior analytics
- System health monitoring

## Future Scalability

### Horizontal Scaling
- Stateless service design
- Load balancer compatibility
- Database connection pooling
- Microservices migration path

### Performance Enhancements
- Background job processing with Celery
- Caching layer with Redis
- CDN for static assets
- Database read replicas for analytics

This backend service is designed to complement your existing iOS app and Supabase setup, providing the computational power and integration capabilities needed for Wisp's advanced running features.