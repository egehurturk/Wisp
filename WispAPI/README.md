# Wisp Backend API

FastAPI backend service for the Wisp running app, handling Strava OAuth, analytics, and external integrations.

## Features

- **Strava OAuth Integration**: Complete OAuth flow with PKCE security
- **Token Management**: Automatic token refresh and secure storage
- **Supabase Integration**: Database operations with Row Level Security
- **Activity Sync**: Automatic Strava activity synchronization
- **JWT Authentication**: Supabase JWT token validation

## Quick Start

### Prerequisites

- Python 3.11+
- Supabase project with configured schema
- Strava OAuth application

### Installation

1. **Clone and navigate to backend directory**:
   ```bash
   cd WispAPI
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

4. **Run the development server**:
   ```bash
   python -m app.main
   # Or using uvicorn directly:
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

5. **Visit API documentation**:
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

## API Endpoints

### Authentication
- `GET /auth/me` - Get current user info
- `POST /auth/validate` - Validate JWT token

### Strava Integration
- `POST /strava/initiate` - Start OAuth flow
- `POST /strava/callback` - Handle OAuth callback
- `GET /strava/status` - Get connection status
- `DELETE /strava/disconnect` - Disconnect account

### Health Check
- `GET /health` - Service health status
- `GET /` - API information

## OAuth Flow

### 1. Initiate Authentication
```http
POST /strava/initiate
Authorization: Bearer <supabase-jwt-token>
```

Response:
```json
{
  "auth_url": "https://www.strava.com/oauth/mobile/authorize?...",
  "state": "secure-state-token",
  "expires_at": "2025-01-01T12:00:00Z"
}
```

### 2. User Authorization
User visits `auth_url` and authorizes your app.

### 3. Handle Callback
```http
POST /strava/callback
Content-Type: application/json

{
  "code": "authorization-code-from-strava",
  "state": "secure-state-token",
  "scope": "read,activity:read"
}
```

### 4. Check Status
```http
GET /strava/status
Authorization: Bearer <supabase-jwt-token>
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Yes |
| `STRAVA_CLIENT_ID` | Strava application client ID | Yes |
| `STRAVA_CLIENT_SECRET` | Strava application client secret | Yes |
| `STRAVA_REDIRECT_URI` | OAuth callback URL | Yes |
| `SECRET_KEY` | Application secret key | Yes |
| `ENVIRONMENT` | Environment (development/production) | No |
| `DEBUG` | Enable debug mode | No |

## Security Features

- **PKCE OAuth Flow**: Secure OAuth with proof key for code exchange
- **State Validation**: CSRF protection for OAuth flow
- **JWT Verification**: Supabase token validation
- **Token Refresh**: Automatic access token refresh
- **Secure Storage**: Encrypted token storage in database

## Database Integration

The backend integrates with your existing Supabase schema:

- **`user_oauth_connections`**: Stores OAuth tokens and metadata
- **`runs`**: Syncs Strava activities as runs
- **`run_routes`**: Stores GPS polyline data

All operations respect your existing Row Level Security policies.

## Deployment

### Railway Deployment

1. **Connect your repository to Railway**
2. **Set environment variables in Railway dashboard**
3. **Deploy automatically on push to main**

### Manual Deployment

```bash
# Build and run with Docker
docker build -t wisp-backend .
docker run -p 8000:8000 wisp-backend

# Or deploy to any Python hosting service
# (Railway, Fly.io, Digital Ocean App Platform, etc.)
```

## Development

### Project Structure

```
WispAPI/
├── app/
│   ├── main.py              # FastAPI application
│   ├── config.py            # Configuration management
│   ├── models/              # Pydantic models
│   │   └── strava.py        # Strava data models
│   ├── routers/             # API route handlers
│   │   ├── auth.py          # Authentication routes
│   │   └── strava.py        # Strava OAuth routes
│   ├── services/            # Business logic
│   │   └── strava_service.py # Strava API service
│   └── utils/               # Utilities
│       └── supabase_client.py # Database client
├── requirements.txt         # Python dependencies
└── .env.example            # Environment template
```

### Adding New Features

1. **Create new router** in `routers/`
2. **Add data models** in `models/`
3. **Implement business logic** in `services/`
4. **Register router** in `main.py`

## Logging

The backend uses Python's standard logging:

```python
import logging
logger = logging.getLogger(__name__)

logger.info("Info message")
logger.error("Error message")
```

## Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run tests
pytest

# Run with coverage
pytest --cov=app
```

## Troubleshooting

### Common Issues

1. **Supabase Connection Failed**
   - Check `SUPABASE_URL` and keys
   - Verify network connectivity

2. **Strava OAuth Errors**
   - Verify client ID and secret
   - Check redirect URI configuration

3. **Token Refresh Failed**
   - User may need to re-authenticate
   - Check Strava API rate limits

### Debug Mode

Set `DEBUG=True` in environment for detailed error messages and automatic reloading.

## API Documentation

- **Swagger UI**: `/docs` - Interactive API documentation
- **ReDoc**: `/redoc` - Alternative API documentation
- **OpenAPI Spec**: `/openapi.json` - Machine-readable API specification

## Contributing

1. Follow existing code style
2. Add tests for new features
3. Update documentation
4. Use type hints throughout