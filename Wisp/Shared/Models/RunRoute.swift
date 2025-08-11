import Foundation
import CoreLocation
import MapKit

struct CoordinatePoint: Codable, Equatable {
    let lat: Double
    let lon: Double
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // Custom decoder to handle both array [lat, lon] and object {"lat": x, "lon": y}
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let array = try? container.decode([Double].self) {
            // Handle array format: [lat, lon]
            guard array.count >= 2 else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Coordinate array must have at least 2 elements"
                ))
            }
            self.lat = array[0]
            self.lon = array[1]
        } else {
            // Handle object format: {"lat": x, "lon": y}
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.lat = try keyedContainer.decode(Double.self, forKey: .lat)
            self.lon = try keyedContainer.decode(Double.self, forKey: .lon)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case lat, lon
    }
}

struct RunRoute: Identifiable, Codable, Equatable {
    let id: UUID
    let runId: UUID
    let coordinates: [CoordinatePoint]
    let encodedPolyline: String?
    let totalPoints: Int
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case runId = "run_id"
        case coordinates
        case encodedPolyline = "encoded_polyline"
        case totalPoints = "total_points"
        case createdAt = "created_at"
    }
    
    static func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(encoded.count / 4)

        let bytes = Array(encoded.utf8)
        var index = 0
        var lat = 0
        var lon = 0

        while index < bytes.count {
            // Decode latitude
            var result = 0
            var shift = 0
            var byte: UInt8
            repeat {
                byte = bytes[index] &- 63
                index += 1
                result |= Int(byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lat &+= deltaLat

            // Decode longitude
            result = 0
            shift = 0
            repeat {
                byte = bytes[index] &- 63
                index += 1
                result |= Int(byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let deltaLon = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lon &+= deltaLon

            let coordinate = CLLocationCoordinate2D(
                latitude:  Double(lat) / 1e5,
                longitude: Double(lon) / 1e5
            )
            coords.append(coordinate)
        }

        return coords
    }

}

extension RunRoute {
    var clLocationCoordinates: [CLLocationCoordinate2D] {
        coordinates.map { $0.clLocationCoordinate2D }
    }
    
    var mkPolyline: MKPolyline {
        let coords = clLocationCoordinates
        return MKPolyline(coordinates: coords, count: coords.count)
    }
    
    var region: MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion()
        }
        
        let lats = coordinates.map { $0.lat }
        let lons = coordinates.map { $0.lon }
        
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.2, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.2, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}
