import Foundation

struct RunInsert: Codable {
    let userId: UUID
    let externalId: String?
    let dataSource: String
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
    
    enum CodingKeys: String, CodingKey {
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
    }
    
    init(
        userId: UUID,
        externalId: String? = nil,
        dataSource: String = "app",
        title: String? = nil,
        description: String? = nil,
        distance: Double,
        movingTime: Int,
        elapsedTime: Int,
        averagePace: Double? = nil,
        averageSpeed: Double? = nil,
        averageCadence: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        caloriesBurned: Double? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        endLatitude: Double? = nil,
        endLongitude: Double? = nil,
        elevationGain: Double? = nil,
        startedAt: Date,
        timezone: String? = nil,
        paceSplits: [Double]? = nil,
        heartRateData: [Int]? = nil,
        weatherTemperature: Double? = nil,
        weatherDescription: String? = nil
    ) {
        self.userId = userId
        self.externalId = externalId
        self.dataSource = dataSource
        self.title = title
        self.description = description
        self.distance = distance
        self.movingTime = movingTime
        self.elapsedTime = elapsedTime
        self.averagePace = averagePace
        self.averageSpeed = averageSpeed
        self.averageCadence = averageCadence
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.caloriesBurned = caloriesBurned
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.elevationGain = elevationGain
        self.startedAt = startedAt
        self.timezone = timezone
        self.paceSplits = paceSplits
        self.heartRateData = heartRateData
        self.weatherDescription = weatherDescription
        self.weatherTemperature = weatherTemperature
    }
}

extension RunInsert {
    /// Validates the run insert data according to database constraints
    func validate() throws {
        guard distance > 0 else {
            throw ValidationError.invalidDistance("Distance must be greater than 0")
        }
        
        guard movingTime > 0 else {
            throw ValidationError.invalidTime("Moving time must be greater than 0")
        }
        
        guard elapsedTime >= movingTime else {
            throw ValidationError.invalidTime("Elapsed time must be greater than or equal to moving time")
        }
        
        // Validate coordinates if provided
        if let lat = startLatitude {
            guard lat >= -90 && lat <= 90 else {
                throw ValidationError.invalidCoordinate("Start latitude must be between -90 and 90")
            }
        }
        
        if let lon = startLongitude {
            guard lon >= -180 && lon <= 180 else {
                throw ValidationError.invalidCoordinate("Start longitude must be between -180 and 180")
            }
        }
        
        if let lat = endLatitude {
            guard lat >= -90 && lat <= 90 else {
                throw ValidationError.invalidCoordinate("End latitude must be between -90 and 90")
            }
        }
        
        if let lon = endLongitude {
            guard lon >= -180 && lon <= 180 else {
                throw ValidationError.invalidCoordinate("End longitude must be between -180 and 180")
            }
        }
        
        // Validate data source for app-recorded runs
        if dataSource == "app" {
            guard externalId == nil else {
                throw ValidationError.invalidDataSource("App-recorded runs should not have external_id")
            }
        }
    }
}

enum ValidationError: LocalizedError {
    case invalidDistance(String)
    case invalidTime(String)
    case invalidCoordinate(String)
    case invalidDataSource(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDistance(let message),
             .invalidTime(let message),
             .invalidCoordinate(let message),
             .invalidDataSource(let message):
            return message
        }
    }
}
