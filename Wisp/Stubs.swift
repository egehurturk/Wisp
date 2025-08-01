import Foundation
import SwiftUI
import MapKit

// MARK: - Stub Data Models

/// Stub implementation for past run data
struct PastRun: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double // in meters
    let duration: TimeInterval // in seconds
    let averagePace: Double // in seconds per meter
    let averageHeartRate: Int?
    let route: RunRoute
    private(set) var customTitle: String?
    let location: String
    let weatherData: WeatherData?
    
    var generatedTitle: String {
        return customTitle ?? generateTitle()
    }
    
    mutating func updateTitle(_ newTitle: String) {
        customTitle = newTitle
    }
    
    private func generateTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let timeOfDay = getTimeOfDay()
        let distanceFormatted = formattedDistance
        
        return "\(timeOfDay) \(distanceFormatted) Run"
    }
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: date)
        
        switch hour {
        case 5..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        case 17..<20:
            return "Evening"
        default:
            return "Night"
        }
    }
    
    var formattedDistance: String {
        let kilometers = distance / 1000
        return String(format: "%.2f km", kilometers)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedPace: String {
        let minutesPerKm = (averagePace * 1000) / 60
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
    
    static let mockData: [PastRun] = [
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            distance: 5000,
            duration: 1800,
            averagePace: 6.0,
            averageHeartRate: 165,
            route: RunRoute.mockData[0],
            customTitle: nil,
            location: "Golden Gate Park",
            weatherData: WeatherData.mockData[0]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            distance: 10000,
            duration: 3600,
            averagePace: 6.5,
            averageHeartRate: 158,
            route: RunRoute.mockData[1],
            customTitle: nil,
            location: "Central Park",
            weatherData: WeatherData.mockData[1]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            distance: 3000,
            duration: 1200,
            averagePace: 5.8,
            averageHeartRate: 170,
            route: RunRoute.mockData[2],
            customTitle: nil,
            location: "Hyde Park",
            weatherData: WeatherData.mockData[2]
        )
    ]
    
    static let extendedMockData: [PastRun] = [
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            distance: 5000,
            duration: 1800,
            averagePace: 6.0,
            averageHeartRate: 165,
            route: RunRoute.mockData[0],
            customTitle: nil,
            location: "Golden Gate Park",
            weatherData: WeatherData.mockData[0]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            distance: 8000,
            duration: 2700,
            averagePace: 5.6,
            averageHeartRate: 172,
            route: RunRoute.mockData[1],
            customTitle: "Speed Training Session",
            location: "Presidio Park",
            weatherData: WeatherData.mockData[1]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            distance: 10000,
            duration: 3600,
            averagePace: 6.5,
            averageHeartRate: 158,
            route: RunRoute.mockData[2],
            customTitle: nil,
            location: "Central Park",
            weatherData: WeatherData.mockData[2]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            distance: 12000,
            duration: 4200,
            averagePace: 6.8,
            averageHeartRate: 162,
            route: RunRoute.mockData[3],
            customTitle: "Long Weekend Run",
            location: "Waterfront Trail",
            weatherData: WeatherData.mockData[0]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            distance: 3000,
            duration: 1200,
            averagePace: 5.8,
            averageHeartRate: 170,
            route: RunRoute.mockData[4],
            customTitle: nil,
            location: "Hyde Park",
            weatherData: WeatherData.mockData[2]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            distance: 6000,
            duration: 2100,
            averagePace: 6.2,
            averageHeartRate: 163,
            route: RunRoute.mockData[0],
            customTitle: "Recovery Run",
            location: "Stanley Park",
            weatherData: WeatherData.mockData[1]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            distance: 15000,
            duration: 5400,
            averagePace: 7.2,
            averageHeartRate: 155,
            route: RunRoute.mockData[1],
            customTitle: "Half Marathon Training",
            location: "Lakefront Path",
            weatherData: WeatherData.mockData[0]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -18, to: Date()) ?? Date(),
            distance: 4000,
            duration: 1680,
            averagePace: 5.9,
            averageHeartRate: 168,
            route: RunRoute.mockData[2],
            customTitle: "Tempo Tuesday",
            location: "Riverside Drive",
            weatherData: WeatherData.mockData[1]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date(),
            distance: 7500,
            duration: 2850,
            averagePace: 6.4,
            averageHeartRate: 160,
            route: RunRoute.mockData[3],
            customTitle: nil,
            location: "Mountain Trail",
            weatherData: WeatherData.mockData[2]
        ),
        PastRun(
            date: Calendar.current.date(byAdding: .day, value: -25, to: Date()) ?? Date(),
            distance: 5500,
            duration: 1980,
            averagePace: 6.1,
            averageHeartRate: 164,
            route: RunRoute.mockData[4],
            customTitle: "Birthday Run 🎂",
            location: "City Center",
            weatherData: WeatherData.mockData[0]
        )
    ]
}

/// Stub implementation for run routes
struct RunRoute: Identifiable, Hashable {
    let id = UUID()
    let waypoints: [MapWaypoint]
    let region: MKCoordinateRegion
    
    static func == (lhs: RunRoute, rhs: RunRoute) -> Bool {
        return lhs.id == rhs.id &&
               lhs.waypoints == rhs.waypoints &&
               lhs.region.center.latitude == rhs.region.center.latitude &&
               lhs.region.center.longitude == rhs.region.center.longitude &&
               lhs.region.span.latitudeDelta == rhs.region.span.latitudeDelta &&
               lhs.region.span.longitudeDelta == rhs.region.span.longitudeDelta
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(waypoints)
        hasher.combine(region.center.latitude)
        hasher.combine(region.center.longitude)
        hasher.combine(region.span.latitudeDelta)
        hasher.combine(region.span.longitudeDelta)
    }
    
    static let mockData: [RunRoute] = [
        // Golden Gate Park Loop - San Francisco
        RunRoute(
            waypoints: [
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)), // Start: JFK Drive
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7705, longitude: -122.4833)), // Conservatory
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7717, longitude: -122.4794)), // Rose Garden
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7736, longitude: -122.4750)), // Japanese Tea Garden
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7745, longitude: -122.4705)), // De Young Museum
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7758, longitude: -122.4668)), // Stow Lake
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7766, longitude: -122.4638)), // Strawberry Hill
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7771, longitude: -122.4598)), // Spreckels Lake
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7785, longitude: -122.4555)), // Buffalo Paddock
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7794, longitude: -122.4515)), // Windmill
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7789, longitude: -122.4472)), // Ocean Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7776, longitude: -122.4508)), // Great Highway
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4575)), // Chain of Lakes
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7720, longitude: -122.4640)), // Polo Fields
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7705, longitude: -122.4720)), // Panhandle
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862))  // End: JFK Drive
            ],
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7745, longitude: -122.4665),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        ),
        
        // Central Park Loop - New York City
        RunRoute(
            waypoints: [
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7681, longitude: -73.9812)), // Start: 72nd Street
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7711, longitude: -73.9778)), // Bethesda Fountain
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7734, longitude: -73.9722)), // Conservatory Lake
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7764, longitude: -73.9689)), // Reservoir South
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7823, longitude: -73.9654)), // Reservoir North
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7880, longitude: -73.9581)), // North Woods
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7934, longitude: -73.9558)), // Harlem Meer
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7956, longitude: -73.9527)), // Conservatory Garden
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7945, longitude: -73.9485)), // East Meadow
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7912, longitude: -73.9502)), // Great Lawn
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7864, longitude: -73.9545)), // Turtle Pond
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7802, longitude: -73.9612)), // Reservoir West
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7756, longitude: -73.9655)), // Sheep Meadow
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7694, longitude: -73.9738)), // Tavern on the Green
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 40.7681, longitude: -73.9812))  // End: 72nd Street
            ],
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.025)
            )
        ),
        
        // Hyde Park Circuit - London
        RunRoute(
            waypoints: [
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1655)), // Start: Hyde Park Corner
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5096, longitude: -0.1623)), // Wellington Arch
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5123, longitude: -0.1589)), // Apsley House
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5158, longitude: -0.1567)), // Serpentine Lake
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5186, longitude: -0.1534)), // Diana Memorial
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5212, longitude: -0.1498)), // Kensington Gardens
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5245, longitude: -0.1467)), // Kensington Palace
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5278, longitude: -0.1523)), // Round Pond
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5298, longitude: -0.1578)), // Physical Energy Statue
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5312, longitude: -0.1634)), // Marble Arch
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5289, longitude: -0.1689)), // Speakers' Corner
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5254, longitude: -0.1721)), // The Pavilion
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5198, longitude: -0.1756)), // Serpentine Gallery
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5156, longitude: -0.1698)), // Albert Memorial
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5112, longitude: -0.1689)), // Royal Albert Hall
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1655))  // End: Hyde Park Corner
            ],
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.5193, longitude: -0.1606),
                span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.030)
            )
        ),
        
        // Waterfront Trail - Chicago
        RunRoute(
            waypoints: [
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298)), // Start: Navy Pier
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8827, longitude: -87.6186)), // Lake Point Tower
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8889, longitude: -87.6123)), // North Avenue Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8953, longitude: -87.6089)), // Lincoln Park Zoo
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9023, longitude: -87.6057)), // Diversey Harbor
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9089, longitude: -87.6024)), // Belmont Harbor
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9145, longitude: -87.5998)), // Montrose Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9156, longitude: -87.6012)), // Montrose Point
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9134, longitude: -87.6045)), // Cricket Hill
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9089, longitude: -87.6078)), // Belmont Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.9023, longitude: -87.6112)), // Diversey Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8953, longitude: -87.6145)), // Fullerton Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8889, longitude: -87.6178)), // North Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8827, longitude: -87.6241)), // Oak Street Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298))  // End: Navy Pier
            ],
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.8963, longitude: -87.6148),
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.03)
            )
        ),
        
        // Stanley Park Seawall - Vancouver
        RunRoute(
            waypoints: [
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)), // Start: Coal Harbour
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2854, longitude: -123.1289)), // Harbour Green Park
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2889, longitude: -123.1367)), // Devonian Harbour Park
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2934, longitude: -123.1423)), // Brockton Point
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2976, longitude: -123.1456)), // Totem Poles
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3012, longitude: -123.1489)), // Lumberman's Arch
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3045, longitude: -123.1523)), // Girl in a Wetsuit
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3089, longitude: -123.1567)), // Lions Gate Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3123, longitude: -123.1598)), // Prospect Point
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3156, longitude: -123.1634)), // Siwash Rock
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3189, longitude: -123.1678)), // Third Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3223, longitude: -123.1712)), // Ferguson Point
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3245, longitude: -123.1756)), // Teahouse Restaurant
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3267, longitude: -123.1789)), // Second Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3289, longitude: -123.1823)), // English Bay
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3234, longitude: -123.1834)), // Sunset Beach
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3178, longitude: -123.1823)), // Aquatic Centre
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3123, longitude: -123.1789)), // Burrard Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3089, longitude: -123.1756)), // Granville Island
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.3045, longitude: -123.1712)), // False Creek
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2989, longitude: -123.1634)), // Science World
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2934, longitude: -123.1567)), // Olympic Village
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2889, longitude: -123.1489)), // Cambie Bridge
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2854, longitude: -123.1345)), // Yaletown
                MapWaypoint(coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207))  // End: Coal Harbour
            ],
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.3036, longitude: -123.1516),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.065)
            )
        )
    ]
}

/// Stub implementation for map waypoints
struct MapWaypoint: Identifiable, Hashable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: MapWaypoint, rhs: MapWaypoint) -> Bool {
        return lhs.id == rhs.id && 
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}

/// Stub implementation for ghost race results
struct GhostRaceResult: Identifiable {
    let id = UUID()
    let runId: UUID
    let ghostName: String
    let didWin: Bool
    let timeDifference: String?
    
    var resultText: String {
        didWin ? "Won" : "Lost"
    }
    
    static let mockData: [GhostRaceResult] = [
        GhostRaceResult(runId: UUID(), ghostName: "Personal Best", didWin: true, timeDifference: "2:30"),
        GhostRaceResult(runId: UUID(), ghostName: "John's Run", didWin: false, timeDifference: "1:45"),
        GhostRaceResult(runId: UUID(), ghostName: "5K Goal", didWin: true, timeDifference: "0:15")
    ]
    
    static var extendedMockData: [GhostRaceResult] {
        let runs = PastRun.extendedMockData
        let ghostNames = ["Personal Best", "Sarah Chen", "Alex Rodriguez", "Sub-20 5K Goal", "Marathon Goal Pace", "Yesterday's Run", "Mike Thompson", "Elite Runner", "Personal Best", "Last Week's Tempo"]
        let winResults = [true, false, true, true, false, true, false, false, true, false]
        let timeDifferences = ["2:30", "1:45", "0:15", "0:45", "3:20", "1:10", "2:05", "5:30", "0:35", "0:55"]
        
        return runs.enumerated().map { index, run in
            GhostRaceResult(
                runId: run.id,
                ghostName: ghostNames[index % ghostNames.count],
                didWin: winResults[index % winResults.count],
                timeDifference: timeDifferences[index % timeDifferences.count]
            )
        }
    }
}

/// Stub implementation for custom goal ghosts
struct CustomGoalGhost: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let distance: Double // in meters
    let targetTime: TimeInterval // in seconds
    let difficulty: Difficulty
    let category: Category
    let progress: Double? // 0.0 to 1.0, nil if not attempted
    
    enum Difficulty: Int, CaseIterable {
        case beginner = 1
        case intermediate = 2
        case advanced = 3
        case expert = 4
        case elite = 5
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            case .elite: return .purple
            }
        }
    }
    
    enum Category: String, CaseIterable {
        case speed = "Speed"
        case endurance = "Endurance"
        case interval = "Interval"
        case recovery = "Recovery"
        
        var displayName: String {
            rawValue
        }
        
        var color: Color {
            switch self {
            case .speed: return .red
            case .endurance: return .blue
            case .interval: return .orange
            case .recovery: return .green
            }
        }
    }
    
    var formattedDistance: String {
        let kilometers = distance / 1000
        return String(format: "%.1f km", kilometers)
    }
    
    var formattedTargetTime: String {
        let minutes = Int(targetTime) / 60
        let seconds = Int(targetTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedTargetPace: String {
        let pacePerKm = (targetTime / (distance / 1000)) / 60
        let minutes = Int(pacePerKm)
        let seconds = Int((pacePerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d/km", minutes, seconds)
    }
    
    static let mockData: [CustomGoalGhost] = [
        CustomGoalGhost(
            name: "5K Sub-20",
            description: "Break the 20-minute barrier for 5K",
            distance: 5000,
            targetTime: 1200,
            difficulty: .advanced,
            category: .speed,
            progress: 0.75
        ),
        CustomGoalGhost(
            name: "10K Endurance",
            description: "Complete 10K at steady pace",
            distance: 10000,
            targetTime: 3000,
            difficulty: .intermediate,
            category: .endurance,
            progress: 0.4
        ),
        CustomGoalGhost(
            name: "Half Marathon",
            description: "Complete your first half marathon",
            distance: 21097,
            targetTime: 7200,
            difficulty: .expert,
            category: .endurance,
            progress: nil
        )
    ]
}

/// Stub implementation for challenges
struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: ChallengeType
    let progress: Double // 0.0 to 1.0
    let endDate: Date
    let participantCount: Int
    let isJoined: Bool
    
    enum ChallengeType: String, CaseIterable {
        case distance = "Distance"
        case time = "Time"
        case streak = "Streak"
        case speed = "Speed"
        case community = "Community"
        
        var icon: String {
            switch self {
            case .distance: return "location"
            case .time: return "clock"
            case .streak: return "flame"
            case .speed: return "speedometer"
            case .community: return "person.3"
            }
        }
        
        var color: Color {
            switch self {
            case .distance: return .blue
            case .time: return .green
            case .streak: return .orange
            case .speed: return .red
            case .community: return .purple
            }
        }
    }
    
    var progressText: String {
        switch type {
        case .distance:
            let current = Int(progress * 100) // Mock current distance
            return "\(current) / 100 km"
        case .time:
            let current = Int(progress * 60) // Mock current time
            return "\(current) / 60 minutes"
        case .streak:
            let current = Int(progress * 30) // Mock current streak
            return "\(current) / 30 days"
        case .speed:
            let current = Int(progress * 10) // Mock current speed goals
            return "\(current) / 10 runs"
        case .community:
            let current = Int(progress * 500) // Mock current community points
            return "\(current) / 500 points"
        }
    }
    
    var timeRemainingText: String {
        let now = Date()
        let timeInterval = endDate.timeIntervalSince(now)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) days left"
        } else if timeInterval > 0 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hours left"
        } else {
            return "Ended"
        }
    }
    
    static let mockData: [Challenge] = [
        Challenge(
            title: "Summer Distance Challenge",
            description: "Run 100km this month and earn exclusive badges",
            type: .distance,
            progress: 0.65,
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            participantCount: 2847,
            isJoined: true
        ),
        Challenge(
            title: "Daily Runner",
            description: "Run every day for 30 days straight",
            type: .streak,
            progress: 0.43,
            endDate: Calendar.current.date(byAdding: .day, value: 17, to: Date()) ?? Date(),
            participantCount: 1205,
            isJoined: true
        ),
        Challenge(
            title: "Speed Demon",
            description: "Complete 10 runs faster than 5:00/km pace",
            type: .speed,
            progress: 0.8,
            endDate: Calendar.current.date(byAdding: .day, value: 8, to: Date()) ?? Date(),
            participantCount: 589,
            isJoined: false
        ),
        Challenge(
            title: "Community Champion",
            description: "Earn 500 points by encouraging other runners",
            type: .community,
            progress: 0.32,
            endDate: Calendar.current.date(byAdding: .day, value: 22, to: Date()) ?? Date(),
            participantCount: 3421,
            isJoined: false
        ),
        Challenge(
            title: "Weekend Warrior",
            description: "Run for 60 minutes every weekend",
            type: .time,
            progress: 0.75,
            endDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
            participantCount: 967,
            isJoined: true
        )
    ]
}

// MARK: - Stub View Controllers

/// Stub implementations for other views
// RunsView implementation is now in Features/Runs/Views/RunsView.swift

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            Text("Statistics View - Coming Soon")
                .navigationTitle("Statistics")
        }
    }
}

struct GhostsView: View {
    var body: some View {
        NavigationView {
            Text("Ghosts View - Coming Soon")
                .navigationTitle("Ghosts")
        }
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationView {
            Text("Groups View - Coming Soon")
                .navigationTitle("Groups")
        }
    }
}
