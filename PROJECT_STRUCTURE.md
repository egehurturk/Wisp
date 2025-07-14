# Wisp iOS App - Project Structure

## Overview
The Wisp iOS app is structured using a clean, enterprise-level architecture with clear separation of concerns. This document outlines the project structure and key components.

## Directory Structure

```
Wisp/
├── Core/                          # Core framework and utilities
│   ├── Logging/                   # Logging system
│   │   └── Logger.swift          # Enterprise logging framework
│   ├── Networking/               # Network layer (future)
│   ├── Persistence/              # Data persistence (future)
│   └── Extensions/               # Swift extensions (future)
│
├── Features/                      # Feature-based modules
│   ├── Home/                     # Home screen feature
│   │   ├── Views/
│   │   │   └── HomeView.swift    # Main home screen view
│   │   ├── ViewModels/
│   │   │   └── HomeViewModel.swift # Home screen view model
│   │   └── Models/               # Home-specific models (future)
│   │
│   ├── Runs/                     # Past runs feature (future)
│   ├── Statistics/               # Statistics feature (future)
│   ├── Ghosts/                   # Ghost racing feature (future)
│   ├── Groups/                   # Group running feature (future)
│   ├── Settings/                 # Settings feature (future)
│   └── Profile/                  # User profile feature (future)
│
├── Shared/                       # Shared components and utilities
│   ├── Components/               # Reusable UI components
│   │   ├── WispButton.swift      # Custom button component
│   │   ├── RunCard.swift         # Past run card component
│   │   ├── GoalGhostCard.swift   # Custom goal card component
│   │   └── MainTabView.swift     # Main tab bar controller
│   │
│   ├── Models/                   # Shared data models (future)
│   ├── ViewModels/               # Shared view models (future)
│   └── Services/                 # Shared services (future)
│
├── Resources/                    # App resources (future)
│   ├── Fonts/                    # Custom fonts
│   ├── Images/                   # Image assets
│   └── Localizations/            # Localization files
│
├── WispApp.swift                 # Main app entry point
└── Stubs.swift                   # Stub implementations for development
```

## Key Components

### 1. Logging System (`Core/Logging/Logger.swift`)
- Enterprise-level logging with multiple log levels (debug, info, warning, error, critical)
- Category-based logging for different app modules
- Integration with Apple's unified logging system
- Debug console output for development

### 2. Main Tab Bar (`Shared/Components/MainTabView.swift`)
- Custom tab bar implementation
- Prominent record button in center
- Tab items: Home, Runs, Record, Statistics, More
- Haptic feedback integration

### 3. Home Screen (`Features/Home/`)
- **HomeView**: Main home screen with past runs and training goals
- **HomeViewModel**: MVVM architecture with proper data management
- Displays past runs with ghost race results
- Shows custom goal ghosts (training plans)
- User profile integration

### 4. Reusable Components (`Shared/Components/`)
- **WispButton**: Custom button with multiple styles and states
- **RunCard**: Card displaying past run information with map preview
- **GoalGhostCard**: Card for custom training goals
- All components include proper logging and error handling

### 5. Stub Implementation (`Stubs.swift`)
- Mock data for development and testing
- Stub implementations for all data models
- Placeholder views for future features

## Architecture Patterns

### MVVM (Model-View-ViewModel)
- Clear separation between UI logic and business logic
- ObservableObject view models with @Published properties
- Proper error handling and loading states

### Defensive Programming
- Comprehensive error handling throughout the app
- Input validation and boundary checks
- Graceful degradation for network failures

### Enterprise Standards
- Structured logging for debugging and monitoring
- Proper file organization and naming conventions
- Comprehensive documentation and code comments
- SwiftUI best practices and modern iOS development patterns

## Next Steps

1. **Implement Core Services**: Add networking, persistence, and location services
2. **Complete Feature Modules**: Build out remaining features (Runs, Statistics, Ghosts, Groups, Settings)
3. **Add Real Data**: Replace stub implementations with actual API integration
4. **Testing**: Add unit tests and UI tests for all components
5. **Performance**: Optimize map rendering and data loading
6. **Accessibility**: Add VoiceOver support and accessibility features

## Development Notes

- All components are designed to be reusable and maintainable
- Proper dependency injection for testability
- Follows Swift and SwiftUI best practices
- Ready for integration with backend services
- Scalable architecture for future feature additions

## Code Quality Standards

- Clean, readable code with meaningful variable names
- Comprehensive error handling
- Proper use of Swift's type system
- Memory management best practices
- Performance-conscious implementation