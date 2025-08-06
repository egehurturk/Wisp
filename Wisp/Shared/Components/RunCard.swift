import SwiftUI
import MapKit

/// Card component displaying past run information with ghost race results
struct RunCard: View {
    
    // MARK: - Properties
    let run: PastRun
    let ghostResult: GhostRaceResult?
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Map View
            MapView(route: run.route)
                .frame(height: 120)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Run Information
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and distance
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(run.generatedTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(run.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(run.formattedDistance)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Replay button
                    WispButton(
                        title: "",
                        style: .icon,
                        icon: "play.fill"
                    ) {
                        handleReplayTap()
                    }
                }
                
                // Run stats
                HStack(spacing: 16) {
                    StatView(
                        title: "Pace",
                        value: run.formattedPace,
                        icon: "timer"
                    )
                    
                    StatView(
                        title: "Time",
                        value: run.formattedDuration,
                        icon: "clock"
                    )
                    
                    if let heartRate = run.averageHeartRate {
                        StatView(
                            title: "HR",
                            value: "\(heartRate) bpm",
                            icon: "heart.fill"
                        )
                    }
                }
                
                // Ghost race result (if available)
                if let ghostResult = ghostResult {
                    GhostResultView(result: ghostResult)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Private Methods
    private func handleReplayTap() {
        logger.info("Replay button tapped for run: \(run.id)")
        // TODO: Navigate to replay screen
    }
}

// MARK: - Supporting Views

/// Individual stat display component
private struct StatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
}

/// Ghost race result display component with entertaining visuals
private struct GhostResultView: View {
    let result: GhostRaceResult
    @State private var showConfetti = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                // Ghost icon
                Image(systemName: "figure.run")
                    .foregroundColor(.purple)
                
                Text("vs \(result.ghostName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Result with entertaining visuals
                HStack(spacing: 4) {
                    if result.didWin {
                        // Trophy for wins
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .scaleEffect(showConfetti ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3).repeatCount(3), value: showConfetti)
                    } else {
                        // Sad face for losses
                        Image(systemName: "face.smiling.inverse")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Text(result.resultText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(result.didWin ? .green : .red)
                }
                .overlay(
                    // Confetti effect for wins
                    result.didWin ? ConfettiView(isActive: $showConfetti) : nil
                )
            }
            
            if let timeDifference = result.timeDifference {
                HStack {
                    Text("by \(timeDifference)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if result.didWin {
                        // Additional celebration for big wins
                        if let time = parseTimeDifference(timeDifference), time > 120 { // 2+ minutes
                            Text("🔥 Crushing it!")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        } else if let time = parseTimeDifference(timeDifference), time > 60 { // 1+ minute
                            Text("💪 Strong finish!")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .onAppear {
            if result.didWin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }
    
    private func parseTimeDifference(_ timeDiff: String) -> Double? {
        let components = timeDiff.split(separator: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]) else {
            return nil
        }
        return minutes * 60 + seconds
    }
}

/// Confetti effect for celebrating wins
private struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(confettiColors[index % confettiColors.count])
                    .frame(width: 3, height: 3)
                    .offset(
                        x: CGFloat.random(in: -20...20),
                        y: confettiOffset
                    )
                    .opacity(isActive ? 1 : 0)
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(Double(index) * 0.1),
                        value: isActive
                    )
            }
        }
        .onChange(of: isActive) { active in
            if active {
                confettiOffset = 30
                
                // Auto-hide confetti after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isActive = false
                }
            } else {
                confettiOffset = 0
            }
        }
    }
    
    private let confettiColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink
    ]
}

/// Map view component for displaying run route with path lines
private struct MapView: View {
    let route: RunRoute
    
    var body: some View {
        Map(coordinateRegion: .constant(route.region), 
            annotationItems: route.waypoints.prefix(2).map { $0 }) { waypoint in
            MapAnnotation(coordinate: waypoint.coordinate) {
                if waypoint.id == route.waypoints.first?.id {
                    // Start point marker
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                } else {
                    // End point marker
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .disabled(true)
        .overlay(
            // Route path overlay
            RoutePathOverlay(route: route)
        )
        .overlay(
            // Gradient overlay for visual appeal
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
                    .black.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }
}

/// Route path overlay for drawing the running route
private struct RoutePathOverlay: View {
    let route: RunRoute
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let coordinates = route.waypoints.map { $0.coordinate }
                guard !coordinates.isEmpty else { return }
                
                let region = route.region
                let mapRect = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                
                // Convert first coordinate to CGPoint
                let firstPoint = coordinateToPoint(coordinates[0], in: mapRect, region: region)
                path.move(to: firstPoint)
                
                // Draw lines to subsequent coordinates
                for coordinate in coordinates.dropFirst() {
                    let point = coordinateToPoint(coordinate, in: mapRect, region: region)
                    path.addLine(to: point)
                }
            }
            .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in rect: CGRect, region: MKCoordinateRegion) -> CGPoint {
        let x = (coordinate.longitude - (region.center.longitude - region.span.longitudeDelta / 2)) / region.span.longitudeDelta * rect.width
        let y = ((region.center.latitude + region.span.latitudeDelta / 2) - coordinate.latitude) / region.span.latitudeDelta * rect.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        LazyVStack(spacing: 16) {
            ForEach(0..<3) { index in
                RunCard(
                    run: PastRun.mockData[index],
                    ghostResult: GhostRaceResult.mockData[index]
                )
            }
        }
        .padding()
    }
}
