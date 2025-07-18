import SwiftUI
import MapKit
import CoreLocation

/// Enhanced MapView that displays GPS route with proper polyline rendering
struct GPSMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let userPath: [CLLocationCoordinate2D]
    let ghostPath: [CLLocationCoordinate2D]
    let annotations: [RouteAnnotation]
    @Binding var isOverviewMode: Bool
    
    // New properties for navigation features
    @State private var userHeading: CLLocationDirection = 0
    @State private var cameraMode: CameraMode = .trailing3D
    
    enum CameraMode {
        case trailing3D
        case topDown
        case overview
        
        var pitch: CGFloat {
            switch self {
            case .trailing3D: return 70
            case .topDown: return 0
            case .overview: return 45
            }
        }
        
        var altitude: CLLocationDistance {
            switch self {
            case .trailing3D: return 350
            case .topDown: return 800
            case .overview: return 1500
            }
        }
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.showsCompass = false
        mapView.showsScale = false
        
        // Configure for running app
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        
//        updateCamera(mapView, animated: false)
        context.coordinator.cameraMode = .trailing3D
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update camera mode based on overview state
        let newCameraMode: CameraMode = isOverviewMode ? .overview : .trailing3D
        if context.coordinator.cameraMode != newCameraMode {
            context.coordinator.cameraMode = newCameraMode
            context.coordinator.updateCameraMode(mapView)
        }

        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        
        let customAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(customAnnotations)
        
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
    
//    private func updateCamera(_ mapView: MKMapView, animated: Bool) {
//        // Get user heading from mapView
//        let heading = mapView.userLocation.heading?.trueHeading ?? 0
//        
//        // Create camera with trailing perspective
//        let camera = MKMapCamera(
//            lookingAtCenter: region.center,
//            fromDistance: cameraMode.altitude,
//            pitch: cameraMode.pitch,
//            heading: heading
//        )
//        
//        mapView.setCamera(camera, animated: animated)
//    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        let parent: GPSMapView
        private let locationManager = CLLocationManager()
        var cameraMode: CameraMode = .trailing3D
        private var lastCameraUpdate: Date = Date()
        private var currentHeading: CLLocationDirection = 0
        private var isInitialLocationSet = false
        
        init(parent: GPSMapView) {
           self.parent = parent
           super.init()
           
            // Setup location manager for heading updates
            locationManager.delegate = self
            locationManager.headingFilter = 5 // Only update when heading changes by 5 degrees
            locationManager.startUpdatingHeading()
       }
        
        func updateCameraMode(_ mapView: MKMapView) {
            switch cameraMode {
            case .overview:
                showRouteOverview(mapView)
                // Update user location annotation for overview mode
                updateUserLocationAnnotation(mapView, isOverview: true)
            case .trailing3D:
                followUserLocation(mapView)
                // Update user location annotation for 3D mode
                updateUserLocationAnnotation(mapView, isOverview: false)
            case .topDown:
                // Not implemented for this use case
                break
            }
        }
        
        private func updateUserLocationAnnotation(_ mapView: MKMapView, isOverview: Bool) {
            // Find the user location annotation view
            if let userLocationView = mapView.view(for: mapView.userLocation) as? UserLocationAnnotationView {
                userLocationView.setOverviewMode(isOverview)
            }
        }
        
        private func showRouteOverview(_ mapView: MKMapView) {
            let allCoordinates = parent.userPath + parent.ghostPath
            guard !allCoordinates.isEmpty else {
                // Fallback to current user location if no route exists
                if let userLocation = mapView.userLocation.location {
                    let camera = MKMapCamera(
                        lookingAtCenter: userLocation.coordinate,
                        fromDistance: 1000,
                        pitch: 0,
                        heading: 0
                    )
                    mapView.setCamera(camera, animated: true)
                }
                return
            }
            
            // Calculate route bounds
            let bounds = calculateRouteBounds(coordinates: allCoordinates)
            
            // Create camera positioned to show entire route
            let camera = MKMapCamera(
                lookingAtCenter: bounds.center,
                fromDistance: bounds.altitude,
                pitch: 0,
                heading: 0
            )
            
            mapView.setCamera(camera, animated: true)
        }
        
        private func followUserLocation(_ mapView: MKMapView) {
            guard let userLocation = mapView.userLocation.location else { return }
            
            let camera = MKMapCamera(
                lookingAtCenter: userLocation.coordinate,
                fromDistance: cameraMode.altitude,
                pitch: cameraMode.pitch,
                heading: currentHeading
            )
            
            mapView.setCamera(camera, animated: true)
        }
        
        private func calculateRouteBounds(coordinates: [CLLocationCoordinate2D]) -> (center: CLLocationCoordinate2D, altitude: CLLocationDistance) {
            guard !coordinates.isEmpty else {
                return (center: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: 1000)
            }
            
            let latitudes = coordinates.map { $0.latitude }
            let longitudes = coordinates.map { $0.longitude }
            
            let minLat = latitudes.min() ?? 0
            let maxLat = latitudes.max() ?? 0
            let minLon = longitudes.min() ?? 0
            let maxLon = longitudes.max() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            // Calculate approximate distance for zoom level
            let latDelta = maxLat - minLat
            let lonDelta = maxLon - minLon
            let maxDelta = max(latDelta, lonDelta)
            
            // Convert coordinate delta to approximate distance
            // This is a rough approximation - 1 degree ≈ 111 km
            let roughDistance = maxDelta * 111000 // meters
            
            // Add padding and ensure minimum/maximum zoom levels
            let altitude = max(500, min(10000, roughDistance * 2))
            
            return (center: center, altitude: altitude)
        }

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
            
            // Handle user location with custom 3D arrow
            if annotation is MKUserLocation {
                let identifier = "user_location_3d"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)  as? UserLocationAnnotationView
               
                if annotationView == nil {
                    annotationView = UserLocationAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
               
                // Update heading
                if let heading = mapView.userLocation.heading {
                    annotationView?.updateHeading(heading.trueHeading)
                }
               
                return annotationView
            }
            
            // Handle ghost annotation
            if annotation.title == "ghost" {
                let identifier = "ghost"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = false
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Ghost view setup
                let ghostView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                ghostView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.3)
                ghostView.layer.cornerRadius = 12
                
                let imageView = UIImageView(image: UIImage(systemName: "figure.run"))
                imageView.tintColor = .systemPurple
                imageView.frame = CGRect(x: 6, y: 6, width: 12, height: 12)
                ghostView.addSubview(imageView)
                
                annotationView?.addSubview(ghostView)
                annotationView?.frame = ghostView.frame
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard let location = userLocation.location else { return }
            
            // Update region binding
            parent.region.center = location.coordinate
            
            // Only update camera if we're in trailing3D mode
            guard cameraMode == .trailing3D else { return }
            
            // Throttle camera updates to prevent jittering
            let now = Date()
            if now.timeIntervalSince(lastCameraUpdate) < 0.5 && isInitialLocationSet {
                return
            }
            lastCameraUpdate = now
            
            // Update camera smoothly
            let camera = MKMapCamera(
                lookingAtCenter: location.coordinate,
                fromDistance: cameraMode.altitude,
                pitch: cameraMode.pitch,
                heading: currentHeading
            )
            
            if !isInitialLocationSet {
                // First time - set immediately without animation
                mapView.setCamera(camera, animated: false)
                isInitialLocationSet = true
            } else {
                // Subsequent updates - animate smoothly
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                    mapView.setCamera(camera, animated: false)
                })
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
             guard newHeading.headingAccuracy > 0 else { return }
            currentHeading = newHeading.trueHeading

        }
    }
}

class UserLocationAnnotationView: MKAnnotationView {
    private let containerView = UIView()
    private let backgroundCircle = UIView()
    private let rippleLayer = CAShapeLayer()
    private let arrowImageView = UIImageView()
    private var heading: CLLocationDirection = 0
    private var isOverviewMode: Bool = false
    private var rippleAnimation: CAAnimationGroup?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        frame = CGRect(x: -25, y: -25, width: 50, height: 50)
        
        // Setup container
        containerView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        addSubview(containerView)
        
        // Setup ripple layer
        setupRippleLayer()
        
        // Setup arrow image
        let configuration = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        arrowImageView.image = UIImage(systemName: "location.north.fill", withConfiguration: configuration)
        arrowImageView.tintColor = UIColor.systemBlue.withAlphaComponent(0.6)
        arrowImageView.frame = CGRect(x: 5, y: 5, width: 40, height: 40)
        containerView.addSubview(arrowImageView)
        
        // Apply initial 3D transform
        apply3DTransform()
        
        // Start ripple animation
        startRippleAnimation()
    }
    
    private func setupRippleLayer() {
        rippleLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        rippleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 50, height: 50)).cgPath
        rippleLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        rippleLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.4).cgColor
        rippleLayer.lineWidth = 2
        rippleLayer.opacity = 0
        containerView.layer.insertSublayer(rippleLayer, below: backgroundCircle.layer)
    }
    
    private func startRippleAnimation() {
        // Create scale animation
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 2.0
        scaleAnimation.duration = 2.0
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Create opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.7
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 2.0
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Create group animation
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 2.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        rippleAnimation = groupAnimation
        rippleLayer.add(groupAnimation, forKey: "rippleAnimation")
    }
    
    private func stopRippleAnimation() {
        rippleLayer.removeAnimation(forKey: "rippleAnimation")
        rippleAnimation = nil
    }
    
    func setOverviewMode(_ isOverview: Bool) {
        guard isOverviewMode != isOverview else { return }
        isOverviewMode = isOverview
        
        // Vanish and reappear animation
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0
        }) { _ in
            if isOverview {
                self.applyOverviewTransform()
                self.stopRippleAnimation()
            } else {
                self.apply3DTransform()
                self.startRippleAnimation()
            }
            
            UIView.animate(withDuration: 0.15) {
                self.alpha = 1
            }
        }
    }
    
    private func apply3DTransform() {
        // Reset scale and size for 3D mode
        containerView.transform = CGAffineTransform.identity
        frame = CGRect(x: -25, y: -25, width: 50, height: 50)
        backgroundCircle.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        backgroundCircle.layer.cornerRadius = 25
        arrowImageView.frame = CGRect(x: 5, y: 5, width: 40, height: 40)
        
        // Update ripple layer for 3D mode
        rippleLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        rippleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 50, height: 50)).cgPath
        
        // Apply 3D transform with proper perspective
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500.0 // Perspective
        transform = CATransform3DRotate(transform, .pi / 3, 1, 0, 0) // 60 degrees rotation on X axis
        
        // Apply current heading rotation if we have one
        if heading != 0 {
            transform = CATransform3DRotate(transform, CGFloat(heading * .pi / 180), 0, 0, 1)
        }
        
        containerView.layer.transform = transform
    }
    
    private func applyOverviewTransform() {
        // Remove 3D transform for flat overview mode
        containerView.layer.transform = CATransform3DIdentity
        
        // Make smaller and flatter for overview mode
        let scale: CGFloat = 0.6
        containerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        // Adjust size for overview mode
        frame = CGRect(x: -15, y: -15, width: 30, height: 30)
        backgroundCircle.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        backgroundCircle.layer.cornerRadius = 25
        arrowImageView.frame = CGRect(x: 5, y: 5, width: 40, height: 40)
        
        // Update ripple layer for overview mode (smaller)
        rippleLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        rippleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 50, height: 50)).cgPath
    }
    
    func updateHeading(_ newHeading: CLLocationDirection) {
        heading = newHeading
        
        // Only animate rotation if not in overview mode
        guard !isOverviewMode else { return }
        
        // Animate rotation
        UIView.animate(withDuration: 0.2) {
            // Apply rotation while maintaining 3D effect
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 500.0
            transform = CATransform3DRotate(transform, .pi / 3, 1, 0, 0) // X-axis rotation (3D effect)
            transform = CATransform3DRotate(transform, CGFloat(newHeading * .pi / 180), 0, 0, 1) // Z-axis rotation (heading)
            self.containerView.layer.transform = transform
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
        ],
        isOverviewMode: .constant(false)
    )
}
