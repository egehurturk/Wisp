import Foundation
import CoreLocation

struct Run: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let externalId: String?
    let dataSource: String?        
    let title: String?
    let description: String?
    let distance: Double           
    let movingTime: Int            
    let elapsedTime: Int           
    let averagePace: Double?       
    let averageSpeed: Double?      
    let averageCadence: Double?
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let caloriesBurned: Double?
    let startLatitude: Double?
    let startLongitude: Double?
    let endLatitude: Double?
    let endLongitude: Double?
    let elevationGain: Double?
    let startedAt: Date
    let timezone: String?
    let paceSplits: [Double]?      
    let heartRateData: [Int]?
    let weatherTemperature: Double?
    let weatherDescription: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case externalId = "external_id"
        case dataSource = "data_source"
        case title
        case description
        case distance
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case averagePace = "average_pace"
        case averageSpeed = "average_speed"
        case averageCadence = "average_cadence"
        case averageHeartRate = "average_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case caloriesBurned = "calories_burned"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case endLatitude = "end_latitude"
        case endLongitude = "end_longitude"
        case elevationGain = "elevation_gain"
        case startedAt = "started_at"
        case timezone
        case paceSplits = "pace_splits"
        case heartRateData = "heart_rate_data"
        case weatherTemperature = "weather_temperature"
        case weatherDescription = "weather_description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle problematic fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        dataSource = try container.decodeIfPresent(String.self, forKey: .dataSource)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        distance = try container.decode(Double.self, forKey: .distance)
        movingTime = try container.decode(Int.self, forKey: .movingTime)
        elapsedTime = try container.decode(Int.self, forKey: .elapsedTime)
        averagePace = try container.decodeIfPresent(Double.self, forKey: .averagePace)
        averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed)
        averageCadence = try container.decodeIfPresent(Double.self, forKey: .averageCadence)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        maxHeartRate = try container.decodeIfPresent(Double.self, forKey: .maxHeartRate)
        caloriesBurned = try container.decodeIfPresent(Double.self, forKey: .caloriesBurned)
        startLatitude = try container.decodeIfPresent(Double.self, forKey: .startLatitude)
        startLongitude = try container.decodeIfPresent(Double.self, forKey: .startLongitude)
        endLatitude = try container.decodeIfPresent(Double.self, forKey: .endLatitude)
        endLongitude = try container.decodeIfPresent(Double.self, forKey: .endLongitude)
        elevationGain = try container.decodeIfPresent(Double.self, forKey: .elevationGain)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        paceSplits = try container.decodeIfPresent([Double].self, forKey: .paceSplits)
        
        // Handle heart rate data gracefully - ignore if decode fails
        heartRateData = try? container.decodeIfPresent([Int].self, forKey: .heartRateData)
        
        weatherTemperature = try container.decodeIfPresent(Double.self, forKey: .weatherTemperature)
        weatherDescription = try container.decodeIfPresent(String.self, forKey: .weatherDescription)
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

extension Run {
    
    // Synchronous fallback - returns coordinate string or placeholder
    var locationString: String {
        guard let lat = startLatitude, let lon = startLongitude else {
            return "Unknown Location"
        }
        
        // For now, return a simple coordinate-based location or placeholder
        // This will be replaced with proper async geocoding in the UI layer
        return "Run Location"
    }
    
    // Async method for proper location resolution
    func resolveLocationString() async -> String {
        guard let lat = startLatitude, let lon = startLongitude else {
            return "Unknown Location"
        }
        
        let location = CLLocation(latitude: lat, longitude: lon)
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? ""
                let country = placemark.country ?? ""
                
                if !city.isEmpty && !country.isEmpty {
                    return "\(city), \(country)"
                } else if !city.isEmpty {
                    return city
                } else if let administrativeArea = placemark.administrativeArea {
                    return administrativeArea
                } else if !country.isEmpty {
                    return country
                }
            }
        } catch {
            // Silent failure, return coordinate-based fallback
            return String(format: "%.4f, %.4f", lat, lon)
        }
        
        return "Run Location"
    }
    
    var distanceInKilometers: Double {
        distance / 1000.0
    }
    
    var formattedDistance: String {
        String(format: "%.1f km", distanceInKilometers)
    }
    
    var formattedDuration: String {
        let hours = movingTime / 3600
        let minutes = (movingTime % 3600) / 60
        let seconds = movingTime % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedPace: String {
        guard let pace = averagePace, pace > 0 else { return "--:--" }
        
        let paceInMinutesPerKm = pace / 60.0
        let minutes = Int(paceInMinutesPerKm)
        let seconds = Int((paceInMinutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var hasLocation: Bool {
        startLatitude != nil && startLongitude != nil
    }
}
