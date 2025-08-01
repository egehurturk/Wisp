# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run the app in simulator
open -a Simulator
xcodebuild -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' run
```

### Location Services Setup
The app requires location permissions for GPS tracking. The project is configured with:
- Location usage descriptions in Info.plist (automatically configured)
- Background location updates capability (for continuous tracking during runs)
- GPSManager handles all location permissions and tracking automatically

### Testing
```bash
# Run all tests
xcodebuild test -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run unit tests only
xcodebuild test -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WispTests

# Run UI tests only
xcodebuild test -project Wisp.xcodeproj -scheme Wisp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WispUITests
```

### Project Information
```bash
# List available schemes and targets
xcodebuild -list

# Show build settings
xcodebuild -showBuildSettings -project Wisp.xcodeproj -scheme Wisp
```

## Architecture Overview

### Core Architecture Pattern
- **MVVM Architecture**: Views are backed by ObservableObject ViewModels using @StateObject and @Published properties
- **SwiftUI + Combine**: Modern reactive UI framework with publishers and subscribers
- **Defensive Programming**: Comprehensive error handling, input validation, and graceful degradation

### Key Architectural Components

#### 1. Enterprise Logging System (`Core/Logging/Logger.swift`)
- Centralized logging with multiple levels (debug, info, warning, error, critical)
- Category-based loggers for different app modules (UI, network, persistence, location, etc.)
- Integrates with Apple's unified logging system (OSLog)
- Usage: `private let logger = Logger.ui` then `logger.info("Message")`

#### 2. Feature-Based Module Structure
Each feature follows consistent MVVM pattern:
- **Views/**: SwiftUI views with minimal business logic
- **ViewModels/**: @MainActor ObservableObject classes handling business logic
- **Models/**: Data structures and business entities

#### 3. Shared Components (`Shared/Components/`)
- **MainTabView**: Custom floating tab bar with haptic feedback
- **WispButton**: Reusable button component with multiple styles
- **RunCard**: Displays past runs with ghost race results
- **GoalGhostCard**: Shows training goals/custom ghosts

#### 4. GPS & Map Components (`Features/Record/Views/`)
- **GPSMapView**: Enhanced MapKit integration with dynamic camera modes
  - **3D Tracking Mode**: Pitched perspective following user with heading rotation
  - **Route Overview Mode**: Top-down view showing entire route bounds
  - **Smooth Transitions**: Animated camera mode switching
  - **Polyline Rendering**: User path (red) and ghost path (purple, dashed)
- **UserLocationAnnotationView**: Custom 3D user location indicator
  - **Ripple Effect**: Animated expanding circles for location tracking
  - **Dual Modes**: Large 3D annotation vs small flat overview annotation
  - **Fade Transitions**: Smooth vanish/reappear animations between modes
  - **Heading Rotation**: Real-time compass direction in 3D mode

#### 5. Mock Data System (`Stubs.swift`)
- Comprehensive mock implementations for development
- Realistic data for all models (PastRun, Ghost, Challenge, etc.)
- Uses real geographic coordinates for route data

### Data Flow Architecture

#### Home Screen Flow
1. `HomeView` creates `@StateObject private var viewModel = HomeViewModel()`
2. `HomeViewModel` manages `@Published` properties for UI state
3. Async data loading with proper error handling and loading states
4. Logger integration for debugging and monitoring

#### Active Run Flow
1. `ActiveRunView` receives `selectedGhost: Ghost` parameter
2. `ActiveRunViewModel` handles real-time run tracking simulation
3. Timer-based updates for metrics, location, and ghost comparison
4. MapKit integration for route visualization with dynamic camera modes
5. **Route Overview Mode**: Pause button triggers overview of entire route
6. **3D Tracking Mode**: Resume button returns to immersive following camera

#### Error Handling Pattern
- ViewModels have dedicated error handling methods
- User-friendly error messages with appropriate logging
- Graceful degradation when services are unavailable
- Recovery mechanisms built into data loading

### Testing Framework
- **Unit Tests**: Uses Swift Testing framework (`@Test` functions)
- **UI Tests**: Uses XCTest framework for end-to-end testing
- Test targets: `WispTests` (unit) and `WispUITests` (UI)

### Key Development Principles
1. **@MainActor**: All ViewModels are marked with @MainActor for thread safety
2. **Async/Await**: Modern concurrency patterns throughout
3. **Structured Logging**: Every significant operation is logged with context
4. **Defensive Coding**: Input validation, nil checking, and error boundaries
5. **SwiftUI Best Practices**: Proper use of state management and lifecycle methods

### Current Implementation Status
-  Home screen with past runs and goals
-  Main tab navigation with custom floating tab bar
-  Active run screen with real-time ghost comparison
-  Ghost system with multiple types (PR, Strava, custom goals)
-  Enterprise logging system
- =� Core services (networking, persistence, location) - stub implementations
- =� Complete feature modules (Settings, Statistics, Groups) - basic stubs

### Integration Points
- **MapKit**: Used for route visualization and location tracking
- **Core Location**: For GPS tracking during runs (simulated currently)
- **Combine**: For reactive data binding between ViewModels and Views
- **SwiftUI**: Modern declarative UI framework

### Project Configuration
- **Target**: iOS 18.5+
- **Swift Version**: 5.0
- **Bundle ID**: com.Wisp
- **Schemes**: Wisp (main), WispTests, WispUITests

## Backend Database Design

### Database Architecture Overview
The backend uses a PostgreSQL database with UUID primary keys and comprehensive foreign key relationships. The schema supports:
- User management with OAuth integrations (Strava, Google)
- Run tracking with GPS routes and weather data
- Ghost racing system for performance comparisons
- Social features (following, challenges, groups)
- Analytics and achievement systems

### Core Database Tables

#### User Management
- **`users`**: Core user profiles with authentication data
- **`user_oauth_connections`**: OAuth tokens and connections (Strava, Google)
- **`user_preferences`**: App settings and user preferences
- **`notification_settings`**: Notification preferences per user

#### Run Data Storage
- **`runs`**: Core run data (distance, duration, pace, calories, elevation)
  - Supports both app-recorded and imported runs (Strava)
  - Includes `external_id` for Strava activity mapping
  - `data_source` field tracks origin ('app', 'strava', etc.)
- **`run_routes`**: GPS coordinate data stored as JSONB arrays
  - Includes encoded polylines for efficient transmission
  - Start/end coordinates for quick location queries
- **`run_weather`**: Weather conditions during runs
  - Temperature, humidity, wind, conditions, pressure

#### Ghost Racing System
- **`ghost_types`**: Defines ghost categories (personal_record, strava_friend, custom_goal)
- **`ghosts`**: Ghost configurations with target times and pacing
  - References to base runs for personal records
  - References to Strava friends for competition
  - JSONB custom splits for training plans
- **`ghost_race_results`**: Results from racing against ghosts
  - Time differences, completion percentages
  - Detailed split-by-split comparisons in JSONB

#### Social Features
- **`user_relationships`**: Following/friend connections
  - Supports multiple relationship types including Strava friends
- **`challenges`**: Group challenges and competitions
  - Flexible challenge types (distance, time, pace)
  - Public/private visibility settings
- **`challenge_participants`**: User participation in challenges
  - Rankings and completion status
- **`challenge_runs`**: Runs that count toward challenges

#### System Features
- **`notifications`**: In-app notification system
- **`user_statistics`**: Aggregated performance metrics
- **`achievements`**: Achievement system with badges
- **`training_plans`**: Structured training schedules

### Key Database Design Decisions

1. **UUID Primary Keys**: Better security and distributed system support
2. **JSONB Storage**: Flexible storage for GPS coordinates, splits, and metadata
3. **Separate Route Tables**: Large GPS data separated from main runs table for performance
4. **OAuth Integration**: Dedicated table supporting multiple providers per user
5. **Flexible Ghost System**: Supports personal records, Strava friends, and custom goals
6. **Social Features**: Generic relationship system supporting various connection types

### Data Relationships
- Users have many runs, ghosts, and challenge participations
- Runs have one-to-one relationships with routes and weather
- Ghosts can reference specific runs (personal records) or users (Strava friends)
- Many-to-many relationships through junction tables for challenges and social connections

### Performance Optimizations
- Strategic indexes on frequently queried columns (user_id, timestamps, locations)
- JSONB indexes for GPS coordinate queries
- Separate tables for large/optional data to keep main tables lean
- Aggregated statistics tables for dashboard performance