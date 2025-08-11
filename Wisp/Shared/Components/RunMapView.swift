import SwiftUI
import MapKit

/// MapView component that displays GPS route from RunRoute data
struct RunMapView: View {
    let route: RunRoute?
    let showsUserLocation: Bool
    
    @State private var region = MKCoordinateRegion()
    
    init(route: RunRoute?, showsUserLocation: Bool = false) {
        self.route = route
        self.showsUserLocation = showsUserLocation
    }
    
    var body: some View {
        Group {
            if let route = route, !route.coordinates.isEmpty {
                Map(coordinateRegion: .constant(route.region)) {
                    // Route polyline
                    MapPolyline(coordinates: route.clLocationCoordinates)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Start marker
                    if let startCoord = route.coordinates.first {
                        MapAnnotation(coordinate: startCoord.clLocationCoordinate2D) {
                            StartMarker()
                        }
                    }
                    
                    // End marker
                    if let endCoord = route.coordinates.last, route.coordinates.count > 1 {
                        MapAnnotation(coordinate: endCoord.clLocationCoordinate2D) {
                            EndMarker()
                        }
                    }
                }
                .disabled(true) // Disable interaction for card view
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