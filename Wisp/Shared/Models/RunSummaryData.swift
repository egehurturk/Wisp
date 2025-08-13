import Foundation
import CoreLocation
import MapKit

struct RunSummaryData {
    let distance: Double
    let movingTime: TimeInterval // Active running time (excludes pauses)
    let elapsedTime: TimeInterval // Total time since start (includes pauses)
    let averagePace: Double
    let currentHeartRate: Int?
    let currentCadence: Int?
    let route: [CLLocationCoordinate2D]
    let laps: [LapData]
    let weatherData: WeatherData?
    
    var mapPolyline: MKPolyline {
        MKPolyline(coordinates: route, count: route.count)
    }
    
    // For backward compatibility with existing time usage
    var time: TimeInterval {
        return movingTime // Use moving time for all time statistics
    }
    
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
    
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        
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
