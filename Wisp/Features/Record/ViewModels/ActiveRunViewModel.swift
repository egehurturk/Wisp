import Foundation
import Combine
import CoreLocation
import MapKit

/// View model for the Active Run screen
@MainActor
final class ActiveRunViewModel: ObservableObject {
    
    // Run state management
    @Published var isRunning: Bool = false
    
    // Run metrics
    @Published var elapsedTime: TimeInterval = 0 // Total time since start (includes pauses)
    @Published var movingTime: TimeInterval = 0 // Active running time (excludes pauses)
    @Published var distance: Double = 0 // meters
    @Published var currentPace: Double = 0 // seconds per km
    @Published var averagePace: Double = 0 // seconds per km
    @Published var currentHeartRate: Int? = nil
    @Published var currentCadence: Int? = nil
    private var startTime: Date?
    private var lastPauseTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var timer: Timer?
    private var lastLocationUpdate: Date = Date()
    private var laps: [LapData] = []
    
    // Save state management
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var saveSuccess = false
    
    // User routes
    @Published var routeAnnotations: [RouteAnnotation] = []
    @Published var userPath: [CLLocationCoordinate2D] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Location errors
    @Published var locationPermissionDenied: Bool = false
    @Published var locationError: LocationError?
    
    // Ghost
    private var selectedGhost: Ghost?
    @Published var ghostPath: [CLLocationCoordinate2D] = []
    @Published var isAheadOfGhost: Bool = false
    @Published var ghostTimeDifference: String? = nil
    private var ghostCurrentPosition: CLLocationCoordinate2D?
    
    // Services
    private let logger = Logger.general
    private let gpsManager = GPSManager()
    private let weatherService = WeatherService()
    private let supabaseManager = SupabaseManager.shared
    
    private var startWeatherData: WeatherData?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var formattedTime: String {
        let hours = Int(movingTime) / 3600
        let minutes = Int(movingTime) % 3600 / 60
        let seconds = Int(movingTime) % 60
        
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
    
    // MARK: - Computed Properties for GPS
    var routePolyline: MKPolyline? {
        gpsManager.mapPolyline
    }
    
    // MARK: - Initialization
    init() {
        setupGPSManager()
        requestLocationPermission()
    }
    
    // MARK: - GPS Setup
    private func setupGPSManager() {
        // Bind GPS manager location updates to our user path
        gpsManager.$routeCoordinates
            .receive(on: DispatchQueue.main)
            .assign(to: \.userPath, on: self)
            .store(in: &cancellables)
        
        // Bind GPS manager current location to update map region
        gpsManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.updateMapRegion(for: location)
            }
            .store(in: &cancellables)
        
        // Bind GPS manager distance to our distance property
        gpsManager.$routeLocations
            .receive(on: DispatchQueue.main)
            .map { locations in
                guard locations.count > 1 else { return 0.0 }
                var totalDistance: CLLocationDistance = 0
                for i in 1..<locations.count {
                    totalDistance += locations[i-1].distance(from: locations[i])
                }
                return totalDistance
            }
            .assign(to: \.distance, on: self)
            .store(in: &cancellables)
        
        // Bind GPS manager tracking status
        gpsManager.$isTracking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTracking in
                if !isTracking && self?.isRunning == true {
                    // GPS stopped unexpectedly while running
                    self?.logger.warning("GPS tracking stopped unexpectedly")
                }
            }
            .store(in: &cancellables)
        
        // Bind GPS manager errors
        gpsManager.$trackingError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.locationError = error
                if let error = error {
                    self?.logger.error("GPS tracking error: \(error.localizedDescription)")
                    switch error {
                    case .permissionDenied:
                        self?.locationPermissionDenied = true
                    case .locationServicesDisabled:
                        self?.pauseRun()
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
        
        // Bind GPS manager authorization status
        gpsManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.locationPermissionDenied = (status == .denied || status == .restricted)
                self?.logger.info("Location authorization status: \(status.description)")
            }
            .store(in: &cancellables)
    }
    
    private func requestLocationPermission() {
        gpsManager.requestLocationPermission()
    }
    
    private func updateMapRegion(for location: CLLocation) {
        let newRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        region = newRegion
    }
    
    // MARK: - Public Methods
    func startRun(with ghost: Ghost) {
        logger.info("Starting run with ghost: \(ghost.name)")
        selectedGhost = ghost
        startTime = Date()
        isRunning = true
        
        // Start GPS tracking
        gpsManager.startTracking()
        
        // Fetch weather data for run start location (once)
        fetchStartWeatherData()
        
        // Initialize ghost data
        initializeGhostData()
        
        // Start timer for run metrics
        startTimer()
        
        // Start simulating ghost movement
        simulateGhostMovement()
    }
    
    func pauseRun() {
        logger.info("Run paused")
        isRunning = false
        lastPauseTime = Date()
        timer?.invalidate()
        timer = nil
        
        // Pause GPS tracking
        gpsManager.pauseTracking()
    }
    
    func resumeRun() {
        logger.info("Run resumed")
        
        // Calculate paused duration and add to total
        if let pauseTime = lastPauseTime {
            let pauseDuration = Date().timeIntervalSince(pauseTime)
            totalPausedTime += pauseDuration
            lastPauseTime = nil
        }
        
        isRunning = true
        startTimer()
        
        // Resume GPS tracking
        gpsManager.resumeTracking()
    }
    
    func endRun() {
        logger.info("Run ended - Distance: \(formattedDistance)km, Time: \(formattedTime)")
        pauseRun()
        
        // Stop GPS tracking
        gpsManager.stopTracking()
    }
    
    func addLap() {
        let lapData = LapData(
            number: laps.count + 1,
            time: movingTime, // Use moving time for laps
            distance: distance,
            pace: currentPace
        )
        laps.append(lapData)
        logger.info("Lap \(lapData.number) added: \(lapData.formattedTime)")
    }
    
    func getRunSummaryData() -> RunSummaryData {
        // Final update of moving time in case run just ended
        if let startTime = startTime {
            let currentElapsedTime = Date().timeIntervalSince(startTime)
            let currentMovingTime = currentElapsedTime - totalPausedTime
            
            return RunSummaryData(
                distance: distance,
                time: currentMovingTime, // Use moving time for display
                averagePace: averagePace,
                currentHeartRate: currentHeartRate,
                currentCadence: currentCadence,
                route: userPath,
                laps: laps,
                weatherData: startWeatherData
            )
        }
        
        return RunSummaryData(
            distance: distance,
            time: movingTime,
            averagePace: averagePace,
            currentHeartRate: currentHeartRate,
            currentCadence: currentCadence,
            route: userPath,
            laps: laps,
            weatherData: startWeatherData
        )
    }
    
    func stopGPSTracking() {
        logger.info("Stopping GPS tracking from ActiveRunViewModel")
        gpsManager.stopTracking()
    }
    
    // MARK: - Save Functionality
    
    // Saves the current run and its route to the database
    func saveRun() async {
        await MainActor.run {
            isSaving = true
            saveError = nil
            saveSuccess = false
        }
        
        logger.info("Starting run save process")
        
        do {
            // Validate we have a logged-in user
            guard let userId = supabaseManager.currentUser?.id else {
                throw SaveError.userNotAuthenticated
            }
            
            // Build insert models
            let runInsert = try buildRunInsert(userId: userId)
            let routeInsert = try buildRunRouteInsert()
            
            // Save to database
            let (savedRun, savedRoute) = try await supabaseManager.saveRunWithRoute(runInsert, routeInsert)
            
            await MainActor.run {
                self.isSaving = false
                self.saveSuccess = true
                self.logger.info("Successfully saved run: \(savedRun.id) with \(savedRoute.totalPoints) route points")
            }
            
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.saveError = self.transformSaveError(error)
                self.logger.error("Failed to save run", error: error)
            }
        }
    }
    
    /// Builds a RunInsert from current session data
    private func buildRunInsert(userId: UUID) throws -> RunInsert {
        guard let startTime = startTime else {
            throw SaveError.missingData("Run start time not found")
        }
        
        guard distance > 0 else {
            throw SaveError.invalidData("No distance recorded for this run")
        }
        
        // Calculate final elapsed and moving times
        let finalElapsedTime = Date().timeIntervalSince(startTime)
        let finalMovingTime = finalElapsedTime - totalPausedTime
        
        guard finalMovingTime > 0 else {
            throw SaveError.invalidData("No moving time recorded for this run")
        }
        
        // Get start and end coordinates from GPS data
        let startCoord = gpsManager.routeLocations.first?.coordinate
        let endCoord = gpsManager.routeLocations.last?.coordinate
        
        // Build heart rate data array if available
        let heartRateArray = currentHeartRate != nil ? [currentHeartRate!] : nil
        
        return RunInsert(
            userId: userId,
            externalId: nil,
            dataSource: "app",
            title: nil, // Will be set in RunSummaryView
            description: nil,
            distance: distance,
            movingTime: Int(finalMovingTime),
            elapsedTime: Int(finalElapsedTime),
            averagePace: averagePace > 0 ? averagePace : nil,
            averageSpeed: averagePace > 0 ? (1000 / averagePace) : nil, // m/s
            averageCadence: currentCadence != nil ? Double(currentCadence!) : nil,
            averageHeartRate: currentHeartRate != nil ? Double(currentHeartRate!) : nil,
            maxHeartRate: currentHeartRate != nil ? Double(currentHeartRate!) : nil,
            caloriesBurned: nil, // Could be calculated based on heart rate/duration
            startLatitude: startCoord?.latitude,
            startLongitude: startCoord?.longitude,
            endLatitude: endCoord?.latitude,
            endLongitude: endCoord?.longitude,
            elevationGain: nil, // Could be calculated from GPS altitude data
            startedAt: startTime,
            timezone: TimeZone.current.identifier,
            paceSplits: nil, // Could be implemented with lap data
            heartRateData: heartRateArray
        )
    }
    
    /// Builds a RunRouteInsert from current GPS data
    private func buildRunRouteInsert() throws -> RunRouteInsert {
        guard !userPath.isEmpty else {
            throw SaveError.missingData("No route data recorded")
        }
        
        // Create encoded polyline for efficient storage
        let encodedPolyline = RunRouteInsert.encodePolyline(coordinates: userPath)
        logger.info("User polyline encoded: \(encodedPolyline)")
        logger.info("User run path: \(userPath)")
        return RunRouteInsert(
            runId: UUID(), // Will be updated by SupabaseManager with actual run ID
            coordinatesArray: userPath,
            encodedPolyline: encodedPolyline
        )
    }
    
    /// Transforms save errors into user-friendly messages
    private func transformSaveError(_ error: Error) -> String {
        if let saveError = error as? SaveError {
            return saveError.userMessage
        }
        
        if let dbError = error as? DatabaseError {
            return dbError.localizedDescription
        }
        
        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }
        
        // Generic error
        return "Unable to save run: \(error.localizedDescription)"
    }
    
    // MARK: - Private Methods
    private func fetchStartWeatherData() {
        Task {
            do {
                // Use current region center as start location
                let startLocation = region.center
                let weather = try await weatherService.fetchCurrentWeather(for: startLocation)
                
                await MainActor.run {
                    self.startWeatherData = weather
                    self.logger.info("Weather data fetched for run start: \(weather.formattedTemperature), \(weather.condition.readableDescription)")
                }
            } catch {
                logger.error("Failed to fetch start weather data", error: error)
                // Continue without weather data
            }
        }
    }
    
    private func initializeGhostData() {
        // Initialize ghost path from selected ghost route
//        if let ghostRoute = selectedGhost?.route {
//            ghostPath = ghostRoute.waypoints.map { $0.coordinate }
//            ghostCurrentPosition = ghostRoute.waypoints.first?.coordinate
//        }
        
        // Initialize route annotations
        updateRouteAnnotations()
        
        // Start with mock sensor data (can be replaced with real sensor integration)
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
        guard isRunning, let startTime = startTime else { return }
        
        // Calculate total elapsed time (including pauses)
        elapsedTime = Date().timeIntervalSince(startTime)
        
        // Calculate moving time (excluding pauses)
        movingTime = elapsedTime - totalPausedTime
        
        // Distance is automatically updated from GPS manager binding
        // No need to simulate distance progression
        
        // Calculate paces based on actual GPS data
        updatePaceMetrics()
        
        // Update sensor data
        updateSensorData()
        
        // Update ghost comparison
        updateGhostComparison()
        
        // Update map annotations
        updateRouteAnnotations()
    }
    
    private func updatePaceMetrics() {
        if distance > 0 && movingTime > 0 {
            averagePace = movingTime / (distance / 1000) // seconds per km based on moving time
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
        
        // Add user position from GPS manager
        if let userPos = gpsManager.currentLocation {
            annotations.append(RouteAnnotation(coordinate: userPos.coordinate, isGhost: false))
        }
        
        // Add ghost position
        if let ghostPos = ghostCurrentPosition {
            annotations.append(RouteAnnotation(coordinate: ghostPos, isGhost: true))
        }
        
        routeAnnotations = annotations
    }
}

// MARK: - Save Error Types
enum SaveError: LocalizedError {
    case userNotAuthenticated
    case missingData(String)
    case invalidData(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .missingData(let message), .invalidData(let message), .networkError(let message):
            return message
        }
    }
    
    var userMessage: String {
        switch self {
        case .userNotAuthenticated:
            return "Please sign in to save your run"
        case .missingData(let message):
            return "Missing run data: \(message)"
        case .invalidData(let message):
            return "Invalid run data: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

