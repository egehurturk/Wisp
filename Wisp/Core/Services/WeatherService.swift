import Foundation
import CoreLocation
import Combine

// Service for fetching weather data for runs
@MainActor
final class WeatherService: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger.network
    private let session = URLSession.shared
    private let cache = WeatherCache()
    
    // API Configuration - You'll need to add your API key
    private struct APIConfig {
        static let openWeatherMapAPIKey = "YOUR_OPENWEATHERMAP_API_KEY_HERE"
        static let baseURL = "https://api.openweathermap.org/data/2.5"
        
        // Alternative: WeatherAPI (more generous free tier)
        static let weatherAPIKey = "YOUR_WEATHERAPI_KEY_HERE"
        static let weatherAPIBaseURL = "https://api.weatherapi.com/v1"
    }
    
    // MARK: - Public Methods
    
    // Fetch current weather data for a given location
    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        logger.info("Fetching current weather for coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Check cache first (valid for 20 minutes)
        if let cachedWeather = cache.getCachedWeather(for: coordinate, maxAge: 1200) {
            logger.info("Returning cached weather data")
            return cachedWeather
        }
        
        // Fetch from API
        let weatherData = try await fetchFromOpenWeatherMap(coordinate: coordinate)
        
        // Cache the result
        cache.cacheWeather(weatherData, for: coordinate)
        
        logger.info("Successfully fetched and cached weather data")
        return weatherData
    }
    
    // Fetch historical weather data for a specific date and location
    func fetchHistoricalWeather(for coordinate: CLLocationCoordinate2D, date: Date) async throws -> WeatherData {
        logger.info("Fetching historical weather for coordinate: \(coordinate.latitude), \(coordinate.longitude) at date: \(date)")
        
        // Check if date is within last 5 days (free tier limitation)
        let daysDifference = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if daysDifference > 5 {
            logger.warning("Historical weather request for date older than 5 days, falling back to mock data")
            return createMockWeatherData(for: coordinate, timestamp: date)
        }
        
        // For recent dates, we can use current weather as approximation
        // In production, you'd use a historical weather API endpoint
        let currentWeather = try await fetchFromOpenWeatherMap(coordinate: coordinate)
        
        // Adjust timestamp to the requested date
        return WeatherData(
            timestamp: date,
            location: currentWeather.location,
            temperature: currentWeather.temperature,
            condition: currentWeather.condition,
            humidity: currentWeather.humidity,
            windSpeed: currentWeather.windSpeed,
            windDirection: currentWeather.windDirection,
            visibility: currentWeather.visibility,
            uvIndex: currentWeather.uvIndex,
            pressure: currentWeather.pressure,
            feelsLike: currentWeather.feelsLike,
            source: .openWeatherMap
        )
    }
    
    // Fetch weather data for run completion (called when run ends)
    func fetchWeatherForRunCompletion(startLocation: CLLocationCoordinate2D, startTime: Date) async throws -> WeatherData {
        logger.info("Fetching weather for run completion")
        
        // If run started within the last hour, fetch current weather
        let timeInterval = Date().timeIntervalSince(startTime)
        if timeInterval < 3600 { // 1 hour
            return try await fetchCurrentWeather(for: startLocation)
        } else {
            // For older runs, fetch historical weather
            return try await fetchHistoricalWeather(for: startLocation, date: startTime)
        }
    }
    
    // MARK: - Private Methods
    
    // Fetch weather data from OpenWeatherMap API
    private func fetchFromOpenWeatherMap(coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        let urlString = "\(APIConfig.baseURL)/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(APIConfig.openWeatherMapAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                logger.error("Weather API returned status code: \(httpResponse.statusCode)")
                throw WeatherError.apiError(httpResponse.statusCode)
            }
            
            let openWeatherResponse = try JSONDecoder().decode(OpenWeatherMapResponse.self, from: data)
            return openWeatherResponse.toWeatherData()
            
        } catch let error as DecodingError {
            logger.error("Failed to decode weather response", error: error)
            throw WeatherError.decodingError(error)
        } catch {
            logger.error("Network request failed", error: error)
            throw WeatherError.networkError(error)
        }
    }
    
    // Create mock weather data when API is unavailable or for testing
    private func createMockWeatherData(for coordinate: CLLocationCoordinate2D, timestamp: Date = Date()) -> WeatherData {
        logger.info("Creating mock weather data")
        
        // Generate realistic weather based on location and season
        let temperature = generateRealisticTemperature(for: coordinate, date: timestamp)
        let condition = generateRealisticCondition(for: coordinate, date: timestamp)
        
        return WeatherData(
            timestamp: timestamp,
            location: WeatherLocation(
                coordinate: LocationCoordinate(coordinate),
                city: "Unknown City",
                country: "Unknown Country",
                timezone: TimeZone.current.identifier
            ),
            temperature: Temperature(celsius: temperature),
            condition: condition,
            humidity: Double.random(in: 0.3...0.9),
            windSpeed: Double.random(in: 0...10),
            windDirection: Double.random(in: 0...360),
            visibility: Double.random(in: 5000...15000),
            uvIndex: Int.random(in: 0...10),
            pressure: Double.random(in: 990...1030),
            feelsLike: Temperature(celsius: temperature + Double.random(in: -3...3)),
            source: .unknown
        )
    }
    
    private func generateRealisticTemperature(for coordinate: CLLocationCoordinate2D, date: Date) -> Double {
        // Basic temperature estimation based on latitude and season
        let latitude = abs(coordinate.latitude)
        let month = Calendar.current.component(.month, from: date)
        
        // Northern hemisphere seasons (reverse for southern)
        let isNorthern = coordinate.latitude >= 0
        let adjustedMonth = isNorthern ? month : (month + 6) % 12
        
        // Base temperature by latitude
        let baseTemp: Double
        if latitude < 30 {
            baseTemp = 25 // Tropical
        } else if latitude < 60 {
            baseTemp = 15 // Temperate
        } else {
            baseTemp = 5 // Polar
        }
        
        // Seasonal adjustment
        let seasonalAdjustment = sin(Double(adjustedMonth - 3) * .pi / 6) * 10
        
        return baseTemp + seasonalAdjustment + Double.random(in: -5...5)
    }
    
    private func generateRealisticCondition(for coordinate: CLLocationCoordinate2D, date: Date) -> WeatherCondition {
        let conditions = [
            ("Clear", "clear sky", "01d", 0.0),
            ("Clouds", "few clouds", "02d", 0.25),
            ("Clouds", "scattered clouds", "03d", 0.5),
            ("Clouds", "overcast clouds", "04d", 0.85),
            ("Rain", "light rain", "10d", 0.7),
            ("Drizzle", "light drizzle", "09d", 0.6)
        ]
        
        let randomCondition = conditions.randomElement()!
        
        return WeatherCondition(
            main: randomCondition.0,
            description: randomCondition.1,
            iconCode: randomCondition.2,
            cloudCoverage: randomCondition.3
        )
    }
}

// MARK: - Weather Cache
private class WeatherCache {
    private var cache: [String: CachedWeatherData] = [:]
    private let cacheQueue = DispatchQueue(label: "weather.cache", attributes: .concurrent)
    
    private struct CachedWeatherData {
        let weather: WeatherData
        let timestamp: Date
    }
    
    func getCachedWeather(for coordinate: CLLocationCoordinate2D, maxAge: TimeInterval) -> WeatherData? {
        return cacheQueue.sync {
            let key = cacheKey(for: coordinate)
            guard let cached = cache[key] else { return nil }
            
            let age = Date().timeIntervalSince(cached.timestamp)
            if age <= maxAge {
                return cached.weather
            } else {
                cache.removeValue(forKey: key)
                return nil
            }
        }
    }
    
    func cacheWeather(_ weather: WeatherData, for coordinate: CLLocationCoordinate2D) {
        cacheQueue.async(flags: .barrier) {
            let key = self.cacheKey(for: coordinate)
            self.cache[key] = CachedWeatherData(weather: weather, timestamp: Date())
        }
    }
    
    private func cacheKey(for coordinate: CLLocationCoordinate2D) -> String {
        // Round to ~1km precision to enable cache sharing for nearby locations
        let lat = round(coordinate.latitude * 100) / 100
        let lon = round(coordinate.longitude * 100) / 100
        return "\(lat),\(lon)"
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

// MARK: - OpenWeatherMap API Response Models
private struct OpenWeatherMapResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let main: Main
    let visibility: Int
    let wind: Wind?
    let clouds: Clouds?
    let dt: Int
    let sys: Sys
    let timezone: Int
    let name: String
    
    struct Coord: Codable {
        let lat: Double
        let lon: Double
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
        let icon: String
    }
    
    struct Main: Codable {
        let temp: Double
        let feelsLike: Double
        let pressure: Double
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp, pressure, humidity
            case feelsLike = "feels_like"
        }
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Double?
    }
    
    struct Clouds: Codable {
        let all: Int
    }
    
    struct Sys: Codable {
        let country: String?
    }
    
    func toWeatherData() -> WeatherData {
        let primaryWeather = weather.first!
        
        return WeatherData(
            timestamp: Date(timeIntervalSince1970: TimeInterval(dt)),
            location: WeatherLocation(
                coordinate: LocationCoordinate(latitude: coord.lat, longitude: coord.lon),
                city: name,
                country: sys.country,
                timezone: TimeZone(secondsFromGMT: timezone)?.identifier
            ),
            temperature: Temperature(celsius: main.temp),
            condition: WeatherCondition(
                main: primaryWeather.main,
                description: primaryWeather.description,
                iconCode: primaryWeather.icon,
                cloudCoverage: Double(clouds?.all ?? 0) / 100.0
            ),
            humidity: Double(main.humidity) / 100.0,
            windSpeed: wind?.speed ?? 0,
            windDirection: wind?.deg ?? 0,
            visibility: Double(visibility),
            uvIndex: 0, // Not provided in basic API
            pressure: main.pressure,
            feelsLike: Temperature(celsius: main.feelsLike),
            source: .openWeatherMap
        )
    }
}
