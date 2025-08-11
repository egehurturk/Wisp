import Foundation
import CoreLocation
import MapKit

struct CoordinatePoint: Codable, Equatable {
    let lat: Double
    let lon: Double
    
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
