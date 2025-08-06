# Wisp - Running App

**Wisp** is an innovative iOS running application that transforms your running experience through **ghost racing** technology. Race against your past performances, Strava friends, or custom training goals while exploring routes with immersive 3D GPS tracking and real-time analytics.

## Features

### Ghost Racing System
- **Personal Records**: Race against your best times on familiar routes
- **Strava Friends**: Compete with friends' activities in real-time ghost races
- **Custom Goals**: Set target paces and train against customizable ghost opponents
- **Past Runs**: Re-run any previous route and beat your historical performance

### Advanced GPS Tracking
- **3D Immersive Mode**: Dynamic camera following with pitch and heading rotation
- **Route Overview Mode**: Top-down view showing complete route bounds
- **Real-time Polylines**: Live route tracking with ghost path visualization
- **Smooth Transitions**: Animated camera mode switching for seamless experience

### Comprehensive Analytics
- Real-time pace, distance, and elevation tracking
- Split-by-split ghost comparisons
- Weather-aware run logging
- Detailed performance insights and trends

### Social Integration
- **Strava Connect**: Import activities and race against Strava friends
- **Supabase Auth**: Secure user authentication with OAuth providers
- Following system for friend-based ghost racing
- Privacy controls (public/friends/private runs)

## Architecture

### iOS Application (Swift/SwiftUI)

**Wisp** is built with modern iOS development practices using **MVVM architecture**, **SwiftUI**, and **Combine** for reactive programming.

#### Core Framework
- **Enterprise Logging System** (`Core/Logging/`) - Multi-level logging with category-based loggers
- **Location Services** (`Core/Services/GPSManager.swift`) - Comprehensive GPS tracking with permissions
- **Configuration Management** (`Core/Configuration/`) - Centralized app configuration

#### Feature Modules
```
Features/
├── Home/              # Main dashboard with past runs and goals
├── Record/            # Active run tracking with GPS and ghost racing
├── Runs/              # Historical run data and analysis
├── Onboarding/        # User authentication and app introduction
├── Settings/          # App preferences and account management
├── Profile/           # User profile and statistics
└── Ghosts/            # Ghost creation and management
```


### Backend API (Python/FastAPI)

The **WispAPI** backend provides secure OAuth integration, activity synchronization, and user data management.

#### Key Features
- **Strava OAuth Flow** - Complete PKCE-secured authentication
- **Supabase Integration** - PostgreSQL database with Row Level Security
- **Token Management** - Automatic refresh and secure storage
- **Activity Sync** - Real-time Strava activity import

#### API Endpoints
```
Authentication:
- GET /auth/me - Current user information
- POST /auth/validate - JWT token validation

Strava Integration:
- POST /strava/initiate - Start OAuth flow
- GET /strava/callback - Handle OAuth callback
- GET /strava/status - Connection status
- DELETE /strava/disconnect - Revoke tokens

Health Monitoring:
- GET /health - Service health check
```

## 🗂️ Project Structure

```
Wisp/
├── Wisp/                          # iOS Application
│   ├── Core/                      # Core framework
│   │   ├── Logging/               # Enterprise logging system
│   │   ├── Services/              # Core services (GPS, Weather, Strava)
│   │   └── Configuration/         # App configuration
│   │
│   ├── Features/                  # Feature-based modules
│   │   ├── Home/                  # Dashboard and overview
│   │   ├── Record/                # Active run tracking
│   │   │   ├── Views/
│   │   │   │   ├── ActiveRunView.swift
│   │   │   │   ├── GPSMapView.swift
│   │   │   │   └── GhostSelectionView.swift
│   │   │   └── ViewModels/
│   │   ├── Onboarding/            # Authentication flow
│   │   ├── Runs/                  # Run history
│   │   └── Settings/              # App preferences
│   │
│   ├── Shared/                    # Reusable components
│   │   ├── Components/            # UI components
│   │   ├── Models/               # Data models
│   │   └── Extensions/           # Swift extensions
│   │
│   └── Resources/                # Assets and resources
│
├── WispAPI/                      # Backend API
│   ├── app/
│   │   ├── main.py               # FastAPI application
│   │   ├── routers/              # API route handlers
│   │   ├── services/             # Business logic
│   │   ├── models/               # Data models
│   │   └── utils/                # Utilities
│   │
│   └── docs/                     # API documentation
│
├── SQL/                          # Database schema
│   ├── tables.sql                # Table definitions
│   └── policies.sql              # Row Level Security
│
└── Tests/                        # Test suites
    ├── WispTests/                # Unit tests
    └── WispUITests/             # UI tests
```

## 🚀 Getting Started

### Prerequisites

#### iOS Development
- **Xcode 15.0+** with iOS 18.5+ SDK
- **macOS Sonoma 14.0+**
- Apple Developer account for device testing

#### Backend Development
- **Python 3.11+**
- **Supabase** project with configured schema
- **Strava** OAuth application credentials

### iOS App Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Wisp
   ```

2. **Open in Xcode**:
   ```bash
   open Wisp.xcodeproj
   ```

3. **Build and run**:
   ```bash
   # Build for simulator
   xcodebuild -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   
   # Run in simulator
   open -a Simulator
   xcodebuild -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' run
   ```

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd WispAPI
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv .venv
   source ./.venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase and Strava credentials
   ```

5. **Run development server**:
   ```bash
   python3 -m app.main
   # Server will start at http://localhost:8000
   ```

6. **Access API documentation**:
   - **Swagger UI**: http://localhost:8000/docs
   - **ReDoc**: http://localhost:8000/redoc

## Testing

### iOS Tests
```bash
# Run all tests
xcodebuild test -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Unit tests only
xcodebuild test -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WispTests

# UI tests only
xcodebuild test -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WispUITests
```

### Backend Tests
```bash
cd WispAPI
pip install pytest pytest-asyncio
pytest
pytest --cov=app  # With coverage
```

## Database Architecture

### Supabase Integration
The application uses **Supabase** as the backend database with **PostgreSQL** and built-in authentication:

#### Core Tables
- **`profiles`** - User profiles extending Supabase auth
- **`runs`** - Core run data with GPS routes and metrics
- **`ghosts`** - Ghost configurations (PR, Strava friends, custom goals)
- **`user_oauth_connections`** - OAuth token storage
- **`user_relationships`** - Social following system

#### Security Features
- **Row Level Security (RLS)** - Automatic data protection
- **OAuth Integration** - Strava and Google authentication
- **Privacy Controls** - User-configurable visibility settings

## Security

### Mobile App Security
- **Secure OAuth Flow** - No client secrets in mobile app
- **JWT Authentication** - Supabase token-based auth
- **Biometric Authentication** - Touch ID/Face ID support
- **Secure Storage** - Keychain integration for sensitive data

### Backend Security
- **PKCE OAuth** - Proof Key for Code Exchange
- **State Validation** - CSRF protection
- **Token Encryption** - Secure database storage
- **Rate Limiting** - API abuse protection

## 📖 Development

### Key Development Commands

```bash
# iOS Development
xcodebuild -list                    # List schemes and targets
xcodebuild -showBuildSettings      # Show build configuration

# Backend Development
uvicorn app.main:app --reload      # Run with auto-reload
python -m pytest --cov=app        # Run tests with coverage
```

### Architecture Guidelines

1. **MVVM Pattern** - Clear separation of concerns with ObservableObject ViewModels
2. **Defensive Programming** - Comprehensive error handling and input validation
3. **Reactive UI** - SwiftUI + Combine for responsive user interfaces
4. **Enterprise Logging** - Structured logging throughout the application
5. **Testability** - Dependency injection and mock-friendly architecture

### Contributing Guidelines

1. **Code Style** - Follow Swift and Python community standards
2. **Testing** - Add tests for new features and bug fixes
3. **Documentation** - Update relevant documentation for changes
4. **Security** - Never commit secrets or sensitive configuration
5. **Performance** - Consider memory usage and battery impact

## 📚 Documentation

- **[Backend API Documentation](WispAPI/docs/)** - Comprehensive backend guides
- **[Database Schema](SQL/)** - Complete database structure
- **[Project Structure](PROJECT_STRUCTURE.md)** - Detailed architecture overview
- **[Development Guide](CLAUDE.md)** - Development setup and guidelines