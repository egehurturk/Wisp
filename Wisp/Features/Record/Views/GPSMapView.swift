import SwiftUI
import MapKit

/// Enhanced MapView that displays GPS route with proper polyline rendering
struct GPSMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let userPath: [CLLocationCoordinate2D]
    let ghostPath: [CLLocationCoordinate2D]
    let annotations: [RouteAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        mapView.showsCompass = false
        mapView.showsScale = false
        
        // Configure for running app
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region to follow user
        if !region.center.latitude.isZero && !region.center.longitude.isZero {
            mapView.setRegion(region, animated: true)
        }
        
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add user path polyline
        if userPath.count > 1 {
            let userPolyline = MKPolyline(coordinates: userPath, count: userPath.count)
            userPolyline.title = "user_path"
            mapView.addOverlay(userPolyline)
        }
        
        // Add ghost path polyline
        if ghostPath.count > 1 {
            let ghostPolyline = MKPolyline(coordinates: ghostPath, count: ghostPath.count)
            ghostPolyline.title = "ghost_path"
            mapView.addOverlay(ghostPolyline)
        }
        
        // Add annotations for current positions
        for annotation in annotations {
            let mapAnnotation = MKPointAnnotation()
            mapAnnotation.coordinate = annotation.coordinate
            mapAnnotation.title = annotation.isGhost ? "ghost" : "user"
            mapView.addAnnotation(mapAnnotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Style based on polyline type
                switch polyline.title {
                case "user_path":
                    renderer.strokeColor = .systemRed
                    renderer.lineWidth = 4.0
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                case "ghost_path":
                    renderer.strokeColor = .systemPurple.withAlphaComponent(0.6)
                    renderer.lineWidth = 4.0
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                    renderer.lineDashPattern = [5, 5] // Dashed line for ghost
                default:
                    renderer.strokeColor = .systemBlue
                    renderer.lineWidth = 3.0
                }
                
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = annotation.title ?? "default"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier!)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            // Custom view for different annotation types
            switch annotation.title {
            case "user":
                // User location indicator
                let userView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
                userView.backgroundColor = .systemBlue
                userView.layer.cornerRadius = 8
                userView.layer.borderWidth = 3
                userView.layer.borderColor = UIColor.white.cgColor
                userView.layer.shadowColor = UIColor.black.cgColor
                userView.layer.shadowOffset = CGSize(width: 0, height: 2)
                userView.layer.shadowOpacity = 0.3
                userView.layer.shadowRadius = 2
                
                annotationView?.addSubview(userView)
                annotationView?.frame = userView.frame
                
            case "ghost":
                // Ghost location indicator
                let ghostView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                ghostView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.3)
                ghostView.layer.cornerRadius = 10
                
                // Add ghost icon
                let imageView = UIImageView(image: UIImage(systemName: "figure.run"))
                imageView.tintColor = .systemPurple
                imageView.frame = CGRect(x: 4, y: 4, width: 12, height: 12)
                ghostView.addSubview(imageView)
                
                annotationView?.addSubview(ghostView)
                annotationView?.frame = ghostView.frame
                
            default:
                break
            }
            
            return annotationView
        }
    }
}

// MARK: - Preview
#Preview {
    GPSMapView(
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )),
        userPath: [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196)
        ],
        ghostPath: [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4193),
            CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4192)
        ],
        annotations: [
            RouteAnnotation(coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196), isGhost: false),
            RouteAnnotation(coordinate: CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4192), isGhost: true)
        ]
    )
}
