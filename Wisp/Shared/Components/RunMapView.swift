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
                Map(coordinateRegion: .constant(route.region), 
                    interactionModes: [], // Disable interaction for card view
                    showsUserLocation: showsUserLocation,
                    annotationItems: routeAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        if annotation.isStart {
                            StartMarker()
                        } else {
                            EndMarker()
                        }
                    }
                }
                .overlay(
                    // Simple route path overlay
                    RoutePathView(coordinates: route.clLocationCoordinates, region: route.region)
                        .allowsHitTesting(false)
                )
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
    
    // Computed property for route annotations
    private var routeAnnotations: [MapRouteMarker] {
        guard let route = route, !route.coordinates.isEmpty else { return [] }
        
        var annotations: [MapRouteMarker] = []
        
        // Add start annotation
        if let startCoord = route.coordinates.first {
            annotations.append(MapRouteMarker(
                coordinate: startCoord.clLocationCoordinate2D,
                isStart: true
            ))
        }
        
        // Add end annotation if different from start
        if let endCoord = route.coordinates.last, route.coordinates.count > 1 {
            annotations.append(MapRouteMarker(
                coordinate: endCoord.clLocationCoordinate2D,
                isStart: false
            ))
        }
        
        return annotations
    }
}

/// Map route marker model for MapKit (renamed to avoid conflict with ActiveRunView.RouteAnnotation)
private struct MapRouteMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let isStart: Bool
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

/// Simplified route path visualization
private struct RoutePathView: View {
    let coordinates: [CLLocationCoordinate2D]
    let region: MKCoordinateRegion
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard coordinates.count > 1 else { return }
                
                // Convert first coordinate to view point
                if let firstPoint = coordinateToPoint(coordinates[0], in: geometry.size, for: region) {
                    path.move(to: firstPoint)
                    
                    // Add lines to subsequent coordinates
                    for coordinate in coordinates.dropFirst() {
                        if let point = coordinateToPoint(coordinate, in: geometry.size, for: region) {
                            path.addLine(to: point)
                        }
                    }
                }
            }
            .stroke(.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .opacity(0.7)
        }
    }
    
    // Convert geographic coordinate to view point
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in size: CGSize, for region: MKCoordinateRegion) -> CGPoint? {
        let deltaLat = region.span.latitudeDelta
        let deltaLon = region.span.longitudeDelta
        
        guard deltaLat > 0 && deltaLon > 0 else { return nil }
        
        let x = (coordinate.longitude - (region.center.longitude - deltaLon/2)) / deltaLon * size.width
        let y = ((region.center.latitude + deltaLat/2) - coordinate.latitude) / deltaLat * size.height
        
        return CGPoint(x: x, y: y)
    }
}