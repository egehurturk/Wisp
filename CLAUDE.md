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

#### 4. Mock Data System (`Stubs.swift`)
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
4. MapKit integration for route visualization

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