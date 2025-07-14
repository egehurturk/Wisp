import Foundation
import Combine
import CoreLocation
import MapKit

/// View model for the Active Run screen
@MainActor
final class ActiveRunViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRunning: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0 // meters
    @Published var currentPace: Double = 0 // seconds per km
    @Published var averagePace: Double = 0 // seconds per km
    @Published var currentHeartRate: Int? = nil
    @Published var currentCadence: Int? = nil
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var routeAnnotations: [RouteAnnotation] = []
    @Published var userPath: [CLLocationCoordinate2D] = []
    @Published var ghostPath: [CLLocationCoordinate2D] = []
    @Published var isAheadOfGhost: Bool = false
    @Published var ghostTimeDifference: String? = nil
    
    // MARK: - Private Properties
    private var selectedGhost: Ghost?
    private var startTime: Date?
    private var timer: Timer?
    private var lastLocationUpdate: Date = Date()
    private var currentLocation: CLLocationCoordinate2D?
    private var ghostCurrentPosition: CLLocationCoordinate2D?
    private var laps: [LapData] = []
    private let logger = Logger.general
    
    // MARK: - Computed Properties
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        let kilometers = distance / 1000
        return String(format: "%.2f", kilometers)
    }
    
    var formattedAveragePace: String {
        guard averagePace > 0 else { return "--:--" }
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedCurrentPace: String {
        guard currentPace > 0 else { return "--:--" }
        let minutes = Int(currentPace) / 60
        let seconds = Int(currentPace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Public Methods
    func startRun(with ghost: Ghost) {
        logger.info("Starting run with ghost: \(ghost.name)")
        selectedGhost = ghost
        startTime = Date()
        isRunning = true
        
        // Initialize mock data
        initializeMockRun()
        
        // Start timer
        startTimer()
        
        // Start simulating ghost movement
        simulateGhostMovement()
    }
    
    func pauseRun() {
        logger.info("Run paused")
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resumeRun() {
        logger.info("Run resumed")
        isRunning = true
        startTimer()
    }
    
    func endRun() {
        logger.info("Run ended - Distance: \(formattedDistance)km, Time: \(formattedTime)")
        pauseRun()
        // TODO: Save run data
    }
    
    func addLap() {
        let lapData = LapData(
            number: laps.count + 1,
            time: elapsedTime,
            distance: distance,
            pace: currentPace
        )
        laps.append(lapData)
        logger.info("Lap \(lapData.number) added: \(lapData.formattedTime)")
    }
    
    func getRunSummaryData() -> RunSummaryData {
        return RunSummaryData(
            distance: distance,
            time: elapsedTime,
            averagePace: averagePace,
            currentHeartRate: currentHeartRate,
            currentCadence: currentCadence,
            route: userPath,
            laps: laps
        )
    }
    
    // MARK: - Private Methods
    private func initializeMockRun() {
        // Set initial location (Golden Gate Park)
        let startCoordinate = CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)
        currentLocation = startCoordinate
        
        // Initialize user path
        userPath = [startCoordinate]
        
        // Initialize ghost path from selected ghost route
        if let ghostRoute = selectedGhost?.route {
            ghostPath = ghostRoute.waypoints.map { $0.coordinate }
            ghostCurrentPosition = ghostRoute.waypoints.first?.coordinate
        }
        
        // Update region to show starting location
        region = MKCoordinateRegion(
            center: startCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        // Initialize route annotations
        updateRouteAnnotations()
        
        // Start with mock sensor data
        currentHeartRate = 120
        currentCadence = 180
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRunMetrics()
            }
        }
    }
    
    private func updateRunMetrics() {
        guard isRunning else { return }
        
        elapsedTime += 1.0
        
        // Simulate distance progression (assume 5:00/km pace for simplicity)
        let simulatedSpeed = 3.33 // m/s (5:00/km pace)
        distance += simulatedSpeed
        
        // Update current location (simulate movement)
        simulateLocationUpdate()
        
        // Calculate paces
        updatePaceMetrics()
        
        // Update sensor data
        updateSensorData()
        
        // Update ghost comparison
        updateGhostComparison()
        
        // Update map annotations
        updateRouteAnnotations()
    }
    
    private func simulateLocationUpdate() {
        guard let currentLoc = currentLocation else { return }
        
        // Simulate movement along a rough path (simplified)
        let bearing = Double.random(in: 0...360) * .pi / 180
        let distanceMoved = 3.33 // meters per second
        let deltaLat = distanceMoved * cos(bearing) / 111000 // rough conversion to degrees
        let deltaLon = distanceMoved * sin(bearing) / (111000 * cos(currentLoc.latitude * .pi / 180))
        
        let newLocation = CLLocationCoordinate2D(
            latitude: currentLoc.latitude + deltaLat,
            longitude: currentLoc.longitude + deltaLon
        )
        
        currentLocation = newLocation
        userPath.append(newLocation)
        
        // Update map region to follow user
        region = MKCoordinateRegion(
            center: newLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
    
    private func updatePaceMetrics() {
        if distance > 0 {
            averagePace = elapsedTime / (distance / 1000) // seconds per km
        }
        
        // Simulate current pace with some variation
        currentPace = averagePace + Double.random(in: -30...30)
        currentPace = max(180, currentPace) // Don't go below 3:00/km
    }
    
    private func updateSensorData() {
        // Simulate heart rate variation
        if let currentHR = currentHeartRate {
            let variation = Int.random(in: -5...5)
            currentHeartRate = max(100, min(200, currentHR + variation))
        }
        
        // Simulate cadence variation
        if let currentCad = currentCadence {
            let variation = Int.random(in: -10...10)
            currentCadence = max(150, min(200, currentCad + variation))
        }
    }
    
    private func simulateGhostMovement() {
        guard let ghost = selectedGhost else { return }
        
        // Calculate ghost's expected pace
        let ghostPacePerSecond = ghost.pace / 1000 // meters per second
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateGhostPosition(pacePerSecond: ghostPacePerSecond)
            }
        }
    }
    
    private func updateGhostPosition(pacePerSecond: Double) {
        guard isRunning, !ghostPath.isEmpty else { return }
        
        // Simulate ghost movement along the path
        let ghostDistanceTraveled = elapsedTime * pacePerSecond
        let totalPathLength = Double(ghostPath.count - 1) * 100 // simplified
        
        if ghostDistanceTraveled < totalPathLength {
            let progressRatio = ghostDistanceTraveled / totalPathLength
            let pathIndex = min(Int(progressRatio * Double(ghostPath.count - 1)), ghostPath.count - 1)
            ghostCurrentPosition = ghostPath[pathIndex]
        }
    }
    
    private func updateGhostComparison() {
        guard let ghost = selectedGhost else { return }
        
        // Calculate expected distance for ghost at current time
        let ghostExpectedDistance = elapsedTime * (1000 / ghost.pace) // meters
        
        // Compare with user's actual distance
        let distanceDifference = distance - ghostExpectedDistance
        isAheadOfGhost = distanceDifference > 0
        
        // Calculate time difference
        let timeDifference = abs(distanceDifference) / (1000 / ghost.pace)
        if timeDifference > 1 {
            let minutes = Int(timeDifference) / 60
            let seconds = Int(timeDifference) % 60
            ghostTimeDifference = String(format: "%d:%02d", minutes, seconds)
        } else {
            ghostTimeDifference = nil
        }
    }
    
    private func updateRouteAnnotations() {
        var annotations: [RouteAnnotation] = []
        
        // Add user position
        if let userPos = currentLocation {
            annotations.append(RouteAnnotation(coordinate: userPos, isGhost: false))
        }
        
        // Add ghost position
        if let ghostPos = ghostCurrentPosition {
            annotations.append(RouteAnnotation(coordinate: ghostPos, isGhost: true))
        }
        
        routeAnnotations = annotations
    }
}

// MARK: - Lap Data
struct LapData {
    let number: Int
    let time: TimeInterval
    let distance: Double
    let pace: Double
    
    var formattedTime: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Run Summary Data
struct RunSummaryData {
    let distance: Double
    let time: TimeInterval
    let averagePace: Double
    let currentHeartRate: Int?
    let currentCadence: Int?
    let route: [CLLocationCoordinate2D]
    let laps: [LapData]
    
    var formattedDistance: String {
        let kilometers = distance / 1000
        return String(format: "%.2f", kilometers)
    }
    
    var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedAveragePace: String {
        guard averagePace > 0 else { return "--:--" }
        let minutes = Int(averagePace) / 60
        let seconds = Int(averagePace) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}