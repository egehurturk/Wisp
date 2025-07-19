import Foundation
import CoreLocation
import SwiftUI

/// Weather data model for storing run weather conditions
struct WeatherData: Codable, Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let location: WeatherLocation
    let temperature: Temperature
    let condition: WeatherCondition
    let humidity: Double // 0.0 to 1.0
    let windSpeed: Double // meters per second
    let windDirection: Double // degrees (0-360)
    let visibility: Double // meters
    let uvIndex: Int // 0-11+
    let pressure: Double // hPa
    let feelsLike: Temperature
    let source: WeatherSource
    
    enum CodingKeys: String, CodingKey {
        case timestamp, location, temperature, condition, humidity
        case windSpeed = "wind_speed", windDirection = "wind_direction"
        case visibility, uvIndex = "uv_index", pressure, feelsLike = "feels_like"
        case source
    }
    
    /// Formatted temperature string for UI display
    var formattedTemperature: String {
        return temperature.formatted
    }
    
    /// Formatted feels like temperature for UI
    var formattedFeelsLike: String {
        return feelsLike.formatted
    }
    
    /// Wind description for UI
    var windDescription: String {
        let speedKmh = windSpeed * 3.6 // Convert m/s to km/h
        let direction = windDirectionString
        return String(format: "%.0f km/h %@", speedKmh, direction)
    }
    
    /// Convert wind direction degrees to compass direction
    private var windDirectionString: String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((windDirection + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    /// Humidity as percentage string
    var humidityPercentage: String {
        return String(format: "%.0f%%", humidity * 100)
    }
    
    /// Visibility description
    var visibilityDescription: String {
        let km = visibility / 1000
        if km >= 10 {
            return "Excellent (>10 km)"
        } else if km >= 5 {
            return String(format: "Good (%.1f km)", km)
        } else if km >= 2 {
            return String(format: "Moderate (%.1f km)", km)
        } else {
            return String(format: "Poor (%.1f km)", km)
        }
    }
    
    /// UV Index description with color
    var uvIndexDescription: (text: String, color: Color) {
        switch uvIndex {
        case 0...2:
            return ("Low (\(uvIndex))", .green)
        case 3...5:
            return ("Moderate (\(uvIndex))", .yellow)
        case 6...7:
            return ("High (\(uvIndex))", .orange)
        case 8...10:
            return ("Very High (\(uvIndex))", .red)
        default:
            return ("Extreme (\(uvIndex))", .purple)
        }
    }
}

/// Temperature structure supporting both Celsius and Fahrenheit
struct Temperature: Codable, Hashable {
    let celsius: Double
    
    var fahrenheit: Double {
        return celsius * 9/5 + 32
    }
    
    var kelvin: Double {
        return celsius + 273.15
    }
    
    /// Formatted temperature string based on user locale
    var formatted: String {
        let locale = Locale.current
        let usesMetric = locale.usesMetricSystem
        
        if usesMetric {
            return String(format: "%.0f°C", celsius)
        } else {
            return String(format: "%.0f°F", fahrenheit)
        }
    }
    
    init(celsius: Double) {
        self.celsius = celsius
    }
    
    init(fahrenheit: Double) {
        self.celsius = (fahrenheit - 32) * 5/9
    }
}

/// Weather condition with icon and description
struct WeatherCondition: Codable, Hashable {
    let main: String
    let description: String
    let iconCode: String
    let cloudCoverage: Double // 0.0 to 1.0
    
    /// SF Symbol name for the weather condition
    var systemIconName: String {
        switch main.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            if cloudCoverage < 0.25 {
                return "cloud.sun.fill"
            } else if cloudCoverage < 0.75 {
                return "cloud.fill"
            } else {
                return "smoke.fill"
            }
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        case "haze":
            return "sun.haze.fill"
        case "dust", "sand":
            return "sun.dust.fill"
        case "tornado":
            return "tornado"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    /// Color associated with the weather condition
    var color: Color {
        switch main.lowercased() {
        case "clear":
            return .yellow
        case "clouds":
            return .gray
        case "rain", "drizzle":
            return .blue
        case "thunderstorm":
            return .purple
        case "snow":
            return .white
        case "mist", "fog":
            return .gray.opacity(0.7)
        case "haze":
            return .orange.opacity(0.7)
        default:
            return .secondary
        }
    }
    
    /// Readable description with proper capitalization
    var readableDescription: String {
        return description.capitalized
    }
}

/// Location information for weather data
struct WeatherLocation: Codable, Hashable {
    let coordinate: LocationCoordinate
    let city: String?
    let country: String?
    let timezone: String?
    
    /// Formatted location string for display
    var displayName: String {
        if let city = city, let country = country {
            return "\(city), \(country)"
        } else if let city = city {
            return city
        } else {
            return "Unknown Location"
        }
    }
}

/// Codable wrapper for CLLocationCoordinate2D
struct LocationCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

/// Weather data source for attribution
enum WeatherSource: String, Codable, CaseIterable {
    case openWeatherMap = "OpenWeatherMap"
    case weatherAPI = "WeatherAPI"
    case appleWeather = "Apple Weather"
    case cached = "Cached"
    case unknown = "Unknown"
    
    var attribution: String {
        switch self {
        case .openWeatherMap:
            return "Weather data provided by OpenWeatherMap"
        case .weatherAPI:
            return "Weather data provided by WeatherAPI"
        case .appleWeather:
            return "Weather data provided by Apple Weather"
        case .cached:
            return "Cached weather data"
        case .unknown:
            return "Weather data source unknown"
        }
    }
}

// MARK: - Mock Data Extensions
extension WeatherData {
    /// Mock weather data for development and testing
    static let mockData: [WeatherData] = [
        WeatherData(
            timestamp: Date(),
            location: WeatherLocation(
                coordinate: LocationCoordinate(latitude: 37.7749, longitude: -122.4194),
                city: "San Francisco",
                country: "US",
                timezone: "America/Los_Angeles"
            ),
            temperature: Temperature(celsius: 18.0),
            condition: WeatherCondition(
                main: "Clear",
                description: "clear sky",
                iconCode: "01d",
                cloudCoverage: 0.1
            ),
            humidity: 0.65,
            windSpeed: 3.2,
            windDirection: 245.0,
            visibility: 10000,
            uvIndex: 6,
            pressure: 1013.25,
            feelsLike: Temperature(celsius: 17.0),
            source: .openWeatherMap
        ),
        WeatherData(
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            location: WeatherLocation(
                coordinate: LocationCoordinate(latitude: 40.7128, longitude: -74.0060),
                city: "New York",
                country: "US",
                timezone: "America/New_York"
            ),
            temperature: Temperature(celsius: 22.0),
            condition: WeatherCondition(
                main: "Clouds",
                description: "scattered clouds",
                iconCode: "03d",
                cloudCoverage: 0.4
            ),
            humidity: 0.58,
            windSpeed: 2.1,
            windDirection: 180.0,
            visibility: 8000,
            uvIndex: 4,
            pressure: 1016.8,
            feelsLike: Temperature(celsius: 23.0),
            source: .weatherAPI
        ),
        WeatherData(
            timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
            location: WeatherLocation(
                coordinate: LocationCoordinate(latitude: 51.5074, longitude: -0.1278),
                city: "London",
                country: "GB",
                timezone: "Europe/London"
            ),
            temperature: Temperature(celsius: 15.0),
            condition: WeatherCondition(
                main: "Rain",
                description: "light rain",
                iconCode: "10d",
                cloudCoverage: 0.8
            ),
            humidity: 0.82,
            windSpeed: 4.5,
            windDirection: 290.0,
            visibility: 5000,
            uvIndex: 2,
            pressure: 1008.3,
            feelsLike: Temperature(celsius: 13.0),
            source: .appleWeather
        )
    ]
}