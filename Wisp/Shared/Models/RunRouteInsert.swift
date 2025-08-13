import Foundation
import CoreLocation

struct RunRouteInsert: Codable {
    let runId: UUID
    let coordinates: [CoordinatePoint]
    let encodedPolyline: String?
    let totalPoints: Int
    
    enum CodingKeys: String, CodingKey {
        case runId = "run_id"
        case coordinates
        case encodedPolyline = "encoded_polyline"
        case totalPoints = "total_points"
    }
    
    init(runId: UUID, coordinates: [CoordinatePoint], encodedPolyline: String? = nil) {
        self.runId = runId
        self.coordinates = coordinates
        self.encodedPolyline = encodedPolyline
        self.totalPoints = coordinates.count
    }
    
    /// Create RunRouteInsert from CLLocationCoordinate2D array
    init(runId: UUID, coordinatesArray: [CLLocationCoordinate2D], encodedPolyline: String? = nil) {
        let coordinatePoints = coordinatesArray.map { coord in
            CoordinatePoint(lat: coord.latitude, lon: coord.longitude)
        }
        
        self.init(runId: runId, coordinates: coordinatePoints, encodedPolyline: encodedPolyline)
    }
}

extension RunRouteInsert {
    /// Validates the run route insert data according to database constraints
    func validate() throws {
        guard totalPoints == coordinates.count else {
            throw ValidationError.invalidPointCount("Total points (\(totalPoints)) must match coordinates count (\(coordinates.count))")
        }
        
        guard !coordinates.isEmpty else {
            throw ValidationError.emptyRoute("Route must contain at least one coordinate point")
        }
        
        // Validate each coordinate
        for (index, coord) in coordinates.enumerated() {
            guard coord.lat.isFinite && coord.lon.isFinite else {
                throw ValidationError.invalidCoordinate("Coordinate at index \(index) contains non-finite values")
            }
            
            guard coord.lat >= -90 && coord.lat <= 90 else {
                throw ValidationError.invalidCoordinate("Latitude at index \(index) must be between -90 and 90")
            }
            
            guard coord.lon >= -180 && coord.lon <= 180 else {
                throw ValidationError.invalidCoordinate("Longitude at index \(index) must be between -180 and 180")
            }
        }
    }
    
    /// Encode coordinates to Google polyline format
    static func encodePolyline(coordinates: [CLLocationCoordinate2D]) -> String {
        var encodedString = ""
        var previousLat = 0
        var previousLon = 0
        
        for coordinate in coordinates {
            let lat = Int(coordinate.latitude * 1e5)
            let lon = Int(coordinate.longitude * 1e5)
            
            let deltaLat = lat - previousLat
            let deltaLon = lon - previousLon
            
            previousLat = lat
            previousLon = lon
            
            encodedString += encodeSignedNumber(deltaLat)
            encodedString += encodeSignedNumber(deltaLon)
        }
        
        return encodedString
    }
    
    private static func encodeSignedNumber(_ num: Int) -> String {
        var signedNum = num << 1
        if num < 0 {
            signedNum = ~signedNum
        }
        return encodeUnsignedNumber(signedNum)
    }
    
    private static func encodeUnsignedNumber(_ num: Int) -> String {
        var encoded = ""
        var value = num
        
        while value >= 0x20 {
            let chunk = (value & 0x1F) | 0x20
            encoded += String(Character(UnicodeScalar(chunk + 63)!))
            value >>= 5
        }
        
        encoded += String(Character(UnicodeScalar(value + 63)!))
        return encoded
    }
}

extension CoordinatePoint {
    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

extension ValidationError {
    static func invalidPointCount(_ message: String) -> ValidationError {
        return .invalidDataSource(message)
    }
    
    static func emptyRoute(_ message: String) -> ValidationError {
        return .invalidDataSource(message)
    }
}