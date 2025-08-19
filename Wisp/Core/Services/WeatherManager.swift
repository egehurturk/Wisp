import Foundation
import CoreLocation
import Combine
import WeatherKit

// Service for fetching weather data for runs
@MainActor
final class WeatherManager: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger.network
    private let service = WeatherService()
    // MARK: - Public Methods
    
    // Fetch current weather data for a given location
    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather? {
        logger.info("Fetching current weather for coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        
        Task {
            do {
                let result = try await service.weather(for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                let current = result.currentWeather
                logger.info("Successfully fetched and cached weather data")
                return current
            }
        }
        logger.error("Error happened while fetching weather data")
        return nil
    }
    
    static func formattedTemperature(temperature: Double) -> String {
        let measurement = Measurement(value: temperature, unit: UnitTemperature.celsius)
        
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitOptions = .providedUnit // or .providedUnit if you want °C/°F shown
        formatter.numberFormatter.maximumFractionDigits = 1
        
        return formatter.string(from: measurement)
    }
    
    static func weatherDescriptionFromIcon(weatherIcon: String) -> String {
        switch weatherIcon {
        case "sun.max.fill":
            return "Bright sunny skies with warmth all throughout the day."
        case "cloud.sun.fill":
            return "Partly cloudy skies with occasional sunshine breaking through often."
        case "cloud.fill":
            return "Overcast skies covering the horizon, minimal sunshine peeking through."
        case "cloud.rain.fill":
            return "Steady rainfall with gray clouds dominating the entire day."
        case "cloud.heavyrain.fill":
            return "Heavy downpour expected, dark clouds filling the entire sky."
        case "cloud.snow.fill":
            return "Cold snowy conditions with fluffy snowflakes drifting from above."
        case "cloud.bolt.fill":
            return "Thunderstorms arriving quickly, lightning flashing across the dark sky."
        case "wind":
            return "Strong winds blowing fiercely, sweeping across the open landscapes."
        case "cloud.fog.fill":
            return "Dense fog blankets the surroundings, reducing visibility all around."
        default:
            return "Stable weather conditions all around, expect a bit of wind."
        }
    }
    
    static func weatherDescriptionFromIconShort(weatherIcon: String) -> String {
        switch weatherIcon {
        case "sun.max.fill":
            return "Bright & Sunny"
        case "cloud.sun.fill":
            return "Partly Cloudy"
        case "cloud.fill":
            return "Cloudy"
        case "cloud.rain.fill":
            return "Rainy"
        case "cloud.heavyrain.fill":
            return "Heavy Rainfall"
        case "cloud.snow.fill":
            return "Cold & Snowy"
        case "cloud.bolt.fill":
            return "Thunderstorms"
        case "wind":
            return "Strong Winds"
        case "cloud.fog.fill":
            return "Dense Fog"
        default:
            return "Stable Weather Conditions"
        }
    }
}

// MARK: - Weather Errors
enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(DecodingError)
    case apiError(Int)
    case locationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid weather API URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse weather data"
        case .apiError(let code):
            return "Weather API error (code: \(code))"
        case .locationNotAvailable:
            return "Location not available for weather data"
        }
    }
}
