import Foundation
import CoreLocation
import MapKit
import Combine

/// GPSManager provides comprehensive location tracking services for Wisp running app
/// Handles permissions, location updates, and provides data for MapPolyLine rendering
@MainActor
final class GPSManager: NSObject, ObservableObject {
    
    // MARK: - Logger
    private let logger = Logger.location
    
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isTracking = false
    @Published var trackingError: LocationError?
    
    // MARK: - Location Data
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var routeLocations: [CLLocation] = []
    
    // MARK: - Computed Properties
    var mapPolyline: MKPolyline {
        MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
    }
    
    var totalDistance: CLLocationDistance {
        guard routeLocations.count > 1 else { return 0 }
        
        var distance: CLLocationDistance = 0
        for i in 1..<routeLocations.count {
            distance += routeLocations[i-1].distance(from: routeLocations[i])
        }
        return distance
    }
    
    var averageSpeed: CLLocationSpeed {
        guard let firstLocation = routeLocations.first,
              let lastLocation = routeLocations.last,
              routeLocations.count > 1 else { return 0 }
        
        let timeInterval = lastLocation.timestamp.timeIntervalSince(firstLocation.timestamp)
        guard timeInterval > 0 else { return 0 }
        
        return totalDistance / timeInterval
    }
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var trackingStartTime: Date?
    private let minimumDistance: CLLocationDistance = 5.0 // meters
    private let minimumTimeInterval: TimeInterval = 2.0 // seconds
    
    // MARK: - Configuration
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    private let distanceFilter: CLLocationDistance = 3.0 // meters
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        logger.info("GPSManager initialized")
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Configure for background updates if needed
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        authorizationStatus = locationManager.authorizationStatus
        logger.debug("Location manager configured with accuracy: \(desiredAccuracy), filter: \(distanceFilter)")
    }
    
    // MARK: - Permission Management
    
    /// Request appropriate location permissions for the app
    func requestLocationPermission() {
        logger.info("Requesting location permission, current status: \(authorizationStatus.description)")
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            logger.warning("Location permission denied or restricted")
            trackingError = .permissionDenied
        case .authorizedWhenInUse:
            // Request always authorization for better tracking
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            logger.info("Location permission already granted (always)")
        @unknown default:
            logger.warning("Unknown location authorization status")
        }
    }
    
    // MARK: - Tracking Control
    
    /// Start GPS tracking for a run
    func startTracking() {
        logger.info("Starting GPS tracking")
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            logger.error("Cannot start tracking: insufficient permissions")
            trackingError = .permissionDenied
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            logger.error("Location services are disabled")
            trackingError = .locationServicesDisabled
            return
        }
        
        // Clear previous tracking data
        clearTrackingData()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        isTracking = true
        trackingStartTime = Date()
        trackingError = nil
        
        logger.info("GPS tracking started successfully")
    }
    
    /// Stop GPS tracking
    func stopTracking() {
        logger.info("Stopping GPS tracking")
        
        locationManager.stopUpdatingLocation()
        isTracking = false
        trackingStartTime = nil
        
        logger.info("GPS tracking stopped. Total coordinates collected: \(routeCoordinates.count)")
    }
    
    /// Pause GPS tracking (keeps data, stops updates)
    func pauseTracking() {
        logger.info("Pausing GPS tracking")
        
        locationManager.stopUpdatingLocation()
        isTracking = false
        
        logger.info("GPS tracking paused")
    }
    
    /// Resume GPS tracking after pause
    func resumeTracking() {
        logger.info("Resuming GPS tracking")
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            logger.error("Cannot resume tracking: insufficient permissions")
            trackingError = .permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
        isTracking = true
        trackingError = nil
        
        logger.info("GPS tracking resumed")
    }
    
    // MARK: - Data Management
    
    /// Clear all tracking data
    func clearTrackingData() {
        logger.debug("Clearing GPS tracking data")
        
        routeCoordinates.removeAll()
        routeLocations.removeAll()
        currentLocation = nil
        trackingError = nil
        
        logger.debug("GPS tracking data cleared")
    }
    
    /// Get route summary for completed run
    func getRouteSummary() -> RouteSummary {
        let summary = RouteSummary(
            coordinates: routeCoordinates,
            locations: routeLocations,
            totalDistance: totalDistance,
            averageSpeed: averageSpeed,
            duration: trackingStartTime?.timeIntervalSinceNow.magnitude ?? 0,
            startTime: trackingStartTime ?? Date()
        )
        
        logger.info("Generated route summary: \(summary.totalDistance)m distance, \(summary.duration)s duration")
        return summary
    }
    
    // MARK: - Private Methods
    
    private func processLocationUpdate(_ location: CLLocation) {
        logger.debug("Processing location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Validate location accuracy
        guard location.horizontalAccuracy < 50 else {
            logger.warning("Location accuracy too low: \(location.horizontalAccuracy)m")
            return
        }
        
        // Check if we should add this location
        if shouldAddLocation(location) {
            routeLocations.append(location)
            routeCoordinates.append(location.coordinate)
            currentLocation = location
            
            logger.debug("Added location to route. Total points: \(routeCoordinates.count)")
        }
    }
    
    private func shouldAddLocation(_ location: CLLocation) -> Bool {
        guard let lastLocation = routeLocations.last else {
            return true // First location
        }
        
        // Check minimum distance
        let distance = location.distance(from: lastLocation)
        guard distance >= minimumDistance else {
            return false
        }
        
        // Check minimum time interval
        let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
        guard timeInterval >= minimumTimeInterval else {
            return false
        }
        
        return true
    }
}

// MARK: - CLLocationManagerDelegate
extension GPSManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        processLocationUpdate(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logger.info("Location authorization changed to: \(status.description)")
        
        authorizationStatus = status
        
        switch status {
        case .denied, .restricted:
            trackingError = .permissionDenied
            if isTracking {
                stopTracking()
            }
        case .authorizedWhenInUse, .authorizedAlways:
            trackingError = nil
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location manager failed with error", error: error)
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                trackingError = .permissionDenied
            case .locationUnknown:
                trackingError = .locationUnavailable
            case .network:
                trackingError = .networkError
            default:
                trackingError = .unknown(clError.localizedDescription)
            }
        } else {
            trackingError = .unknown(error.localizedDescription)
        }
        
        if isTracking {
            stopTracking()
        }
    }
}

// MARK: - Supporting Types

/// Errors that can occur during GPS tracking
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationServicesDisabled
    case locationUnavailable
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission is required to track your run."
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .locationUnavailable:
            return "Unable to determine your location. Please try again."
        case .networkError:
            return "Network error occurred while getting location."
        case .unknown(let message):
            return "Location error: \(message)"
        }
    }
}

/// Summary of a completed route
struct RouteSummary {
    let coordinates: [CLLocationCoordinate2D]
    let locations: [CLLocation]
    let totalDistance: CLLocationDistance
    let averageSpeed: CLLocationSpeed
    let duration: TimeInterval
    let startTime: Date
    
    var polyline: MKPolyline {
        MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

// MARK: - CLAuthorizationStatus Extension
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        @unknown default: return "unknown"
        }
    }
}