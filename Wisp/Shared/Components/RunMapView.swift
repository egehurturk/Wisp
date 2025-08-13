import SwiftUI
import MapKit

/// MapView component that displays GPS route from RunRoute data
struct RunMapView: View {
    let route: RunRoute?
    let showsUserLocation: Bool
    
    init(route: RunRoute?, showsUserLocation: Bool = false) {
        self.route = route
        self.showsUserLocation = showsUserLocation
    }
    
    var body: some View {
        Group {
            if let route = route, !route.coordinates.isEmpty {
                RouteMapPolyline(coordinates: RunRoute.decodePolyline(route.encodedPolyline!))
            } else {
                // Fallback when no route data
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.1), .blue.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            
                            Text("No Route Data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
    
//    // Computed property for route annotations
//    private var routeAnnotations: [MapRouteMarker] {
//        guard let route = route, !route.coordinates.isEmpty else { return [] }
//        
//        var annotations: [MapRouteMarker] = []
//        
//        // Add start annotation
//        if let startCoord = route.coordinates.first {
//            annotations.append(MapRouteMarker(
//                coordinate: startCoord.clLocationCoordinate2D,
//                isStart: true
//            ))
//        }
//        
//        // Add end annotation if different from start
//        if let endCoord = route.coordinates.last, route.coordinates.count > 1 {
//            annotations.append(MapRouteMarker(
//                coordinate: endCoord.clLocationCoordinate2D,
//                isStart: false
//            ))
//        }
//        
//        return annotations
//    }
}

struct RouteMapPolyline: View {
    let coordinates: [CLLocationCoordinate2D]
    var interaction: MapInteractionModes = []       // like your old code
    var lineWidth: CGFloat = 4

    @State private var camera: MapCameraPosition = .automatic

    init(coordinates: [CLLocationCoordinate2D],
         interaction: MapInteractionModes = .all,
         lineWidth: CGFloat = 4) {
        self.coordinates = coordinates
        self.interaction = interaction
        self.lineWidth = lineWidth
        // Seed the camera to fit the route
        _camera = State(initialValue: .region(regionToFit(coordinates)))
    }

    
    private func regionToFit(_ coords: [CLLocationCoordinate2D], pad: CLLocationDegrees = 0.01) -> MKCoordinateRegion {
        guard let first = coords.first else {
            return MKCoordinateRegion(center: .init(latitude: 0, longitude: 0),
                                      span: .init(latitudeDelta: 180, longitudeDelta: 360))
        }
        var minLat = first.latitude,  maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat+maxLat)/2, longitude: (minLon+maxLon)/2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat-minLat)+pad, longitudeDelta: (maxLon-minLon)+pad)
        return MKCoordinateRegion(center: center, span: span)
    }

    
    var body: some View {
        Map(position: $camera, interactionModes: interaction) {
            Annotation("Start", coordinate: coordinates.first!) {
                StartMarker()
            }
            Annotation("End", coordinate: coordinates.last!) {
                EndMarker()
            }
            MapPolyline(coordinates: coordinates)
                .stroke(.blue, lineWidth: lineWidth)
        }
        .allowsHitTesting(true) // same behavior as your overlay
    }
}


/// Start marker for route visualization
private struct StartMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.green)
                .frame(width: 16, height: 16)
            
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 16, height: 16)
            
            Text("S")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

/// End marker for route visualization  
private struct EndMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.red)
                .frame(width: 16, height: 16)
            
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 16, height: 16)
            
            Text("E")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
