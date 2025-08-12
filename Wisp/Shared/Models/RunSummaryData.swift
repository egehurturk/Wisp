import Foundation
import CoreLocation

struct RunSummaryData {
    let distance: Double
    let time: TimeInterval
    let averagePace: Double
    let currentHeartRate: Int?
    let currentCadence: Int?
    let route: [CLLocationCoordinate2D]
    let laps: [LapData]
    let weatherData: WeatherData?
    
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