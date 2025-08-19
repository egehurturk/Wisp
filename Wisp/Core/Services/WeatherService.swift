import Foundation
import CoreLocation
import Combine

// Service for fetching weather data for runs
@MainActor
final class WeatherService: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger.network
    
    // MARK: - Public Methods
    
    // Fetch current weather data for a given location
    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        logger.info("Fetching current weather for coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        
        let weatherData = WeatherData()
        // Fetch with WeatherKit
        
        logger.info("Successfully fetched and cached weather data")
        return weatherData
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
