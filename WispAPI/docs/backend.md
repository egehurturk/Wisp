# Wisp Backend Service Documentation

## Architecture Overview

### Tech Stack
- **Backend Framework**: FastAPI (Python 3.11+)
- **Database**: Supabase PostgreSQL with existing schema
- **Authentication**: Supabase Auth with JWT tokens
- **Real-time**: WebSockets + Supabase Realtime subscriptions
- **External APIs**: Strava API, Weather APIs
- **ML/Analytics**: scikit-learn, pandas, numpy
- **Deployment**: Railway/Fly.io/Digital Ocean App Platform

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
1. **Complex Business Logic**
   - Ghost racing calculations and real-time comparisons
   - Route analysis and optimization

2. **External API Integrations**
   - Strava OAuth flow and data synchronization
   - Weather API integration for historical/real-time data
   - Future integrations (Apple Health, Google Fit, etc.)

3. **Background Processing**
   - Data import jobs (Strava activities)
   - Analytics calculations
   - Notification sending
   - Cache warming and optimization

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

## Database Integration

### Connection Pattern
```python
from supabase import create_client, Client
import os

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_ANON_KEY")
)

# For service role operations (admin access)
supabase_admin: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_ROLE_KEY")
)
```

### Authentication Integration
```python
# Validate JWT tokens from iOS app
def verify_token(token: str):
    try:
        user = supabase.auth.get_user(token)
        return user
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### Database Operations
```python
# Use existing schema and RLS policies
# All operations respect user permissions automatically
runs = supabase.table("runs").select("*").eq("user_id", user_id).execute()
```

## Key Features Implementation

### 3. Strava Integration
```python
class StravaService:
    """Complete Strava API integration"""
    
    async def sync_activities(self, user_id):
        # Bidirectional sync with Strava
        # Import new activities
        # Export app activities to Strava
        pass
    
    async def refresh_oauth_token(self, user_id):
        # Handle token refresh automatically
        # Update stored credentials
        pass

    ...
```

## Development Setup

### Environment Variables
```bash
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_anon_public_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# External APIs
STRAVA_CLIENT_ID=your_strava_client_id
STRAVA_CLIENT_SECRET=your_strava_client_secret
WEATHER_API_KEY=your_weather_api_key

# Application Settings
SECRET_KEY=your_jwt_secret_key
DEBUG=True
CORS_ORIGINS=http://localhost:3000,https://yourapp.com
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
│   │   ├── supabase_client.py
│   │   ├── auth_utils.py
│   │   └── ml_utils.py
│   └── websockets/            # WebSocket handlers
│       ├── racing.py
│       └── live_tracking.py
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
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "version": "1.0.0",
        "database": "connected" if supabase_health_check() else "disconnected"
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
- WebSocket connections for real-time features
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