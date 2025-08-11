import Foundation

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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Run {
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