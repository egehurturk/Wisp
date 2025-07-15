import SwiftUI
import MapKit

/// Active Run screen with Strava-inspired design
struct ActiveRunView: View {
    
    // MARK: - Properties
    let selectedGhost: Ghost
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActiveRunViewModel()
    @State private var showingPauseMenu = false
    @State private var countdownNumber: Int? = nil
    @State private var showingCountdown = false
    @State private var showingRunSummary = false
    @State private var showingPausedOverlay = false
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Full screen map with overlay stats
                ZStack {
                    // Map section (full screen)
                    mapContentView
                        .frame(maxHeight: .infinity)
                        .ignoresSafeArea()
                    
                    // Top stats overlay
                    VStack {
                        topStatsOverlay
                            .padding(.top, 60)
                        
                        Spacer()
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Ghost comparison card
                ghostComparisonCard
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Bottom stats section
                bottomStatsSection
                    .padding(.horizontal, 16)
                
                // Control buttons
                controlButtonsSection
                    .padding(.bottom, 40)
            }
            
            // Countdown overlay
            if showingCountdown {
                countdownOverlay
            }
            
            // Paused overlay
            if showingPausedOverlay {
                pausedOverlay
            }
        }
        .fullScreenCover(isPresented: $showingRunSummary) {
            RunSummaryView(
                selectedGhost: selectedGhost,
                runData: viewModel.getRunSummaryData()
            ) {
                // On save
                dismiss()
            } onDiscard: {
                // On discard
                dismiss()
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            logger.info("ActiveRunView appeared with ghost: \(selectedGhost.name)")
            startCountdown()
        }
        .onDisappear {
            viewModel.pauseRun()
        }
    }
    
    // MARK: - Top Stats Overlay
    private var topStatsOverlay: some View {
        HStack {
            // Time
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.formattedTime)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text("TIME")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            // Distance
            VStack(alignment: .center, spacing: 2) {
                Text(viewModel.formattedDistance)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text("DISTANCE")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            // Pace
            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedAveragePace)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text("PACE")
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Map Content View
    private var mapContentView: some View {
        Map(coordinateRegion: $viewModel.region, 
            annotationItems: viewModel.routeAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                if annotation.isGhost {
                    // Ghost runner indicator
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.3))
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.purple)
                    }
                } else {
                    // User location indicator
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 16, height: 16)
                        
                        Circle()
                            .stroke(.white, lineWidth: 3)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .overlay(
            // Route path
            RouteOverlay(
                userPath: viewModel.userPath,
                ghostPath: viewModel.ghostPath
            )
        )
        .scenePadding(.bottom)
        .disabled(true)
    }
    
    // MARK: - Ghost Comparison Card
    private var ghostComparisonCard: some View {
        HStack(spacing: 16) {
            // Ghost avatar
            ZStack {
                Circle()
                    .fill(.purple.opacity(0.8))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(selectedGhost.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(viewModel.isAheadOfGhost ? "+" : "-")
                        .foregroundColor(viewModel.isAheadOfGhost ? .green : .red)
                    + Text("1:14")
                        .foregroundColor(viewModel.isAheadOfGhost ? .green : .red)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(viewModel.isAheadOfGhost ? "AHEAD" : "BEHIND")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            
            Spacer()
            
            // Split indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("5:32")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("SPLIT")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Bottom Stats Section
    private var bottomStatsSection: some View {
        HStack(spacing: 0) {
            // AVG Pace
            VStack(spacing: 4) {
                Text("AVG Pace")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(viewModel.formattedAveragePace)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("km")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 50)
            
            // Elevation
            VStack(spacing: 4) {
                Text("Elevation")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("12")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("m")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 50)
            
            // BPM
            VStack(spacing: 4) {
                Text("BPM")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("120")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("bpm")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
    }
    
    
    // MARK: - Control Buttons Section
    private var controlButtonsSection: some View {
        HStack(spacing: 40) {
            // Lap button
            StravaControlButton(
                icon: "arrow.clockwise",
                color: .white.opacity(0.2),
                size: .medium
            ) {
                addLap()
            }
            
            // Pause/Resume button
            StravaControlButton(
                icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                color: .red,
                size: .large
            ) {
                toggleRunning()
            }
            
            // Finish button
            StravaControlButton(
                icon: "stop.fill",
                color: .white.opacity(0.2),
                size: .medium
            ) {
                finishRun()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Countdown Overlay
    private var countdownOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Get Ready!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let number = countdownNumber {
                    Text("\(number)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(showingCountdown ? 1.2 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: countdownNumber)
                } else {
                    Text("GO!")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .scaleEffect(1.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: countdownNumber)
                }
                
                Text("vs \(selectedGhost.name)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Paused Overlay
    private var pausedOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingPausedOverlay)
                
                Text("PAUSED")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tap play to resume")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Private Methods
    private func startCountdown() {
        showingCountdown = true
        countdownNumber = 3
        
        // Haptic feedback for countdown start
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Countdown sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            countdownNumber = 2
            impactFeedback.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            countdownNumber = 1
            impactFeedback.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            countdownNumber = nil // Shows "GO!"
            let successFeedback = UIImpactFeedbackGenerator(style: .heavy)
            successFeedback.impactOccurred()
            
            // Start the actual run
            viewModel.startRun(with: selectedGhost)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showingCountdown = false
            }
        }
    }
    
    private func toggleRunning() {
        if viewModel.isRunning {
            viewModel.pauseRun()
            showPausedOverlay()
        } else {
            viewModel.resumeRun()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func showPausedOverlay() {
        showingPausedOverlay = true
        
        // Hide overlay after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showingPausedOverlay = false
            }
        }
    }
    
    private func addLap() {
        viewModel.addLap()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func finishRun() {
        logger.info("Finish run tapped")
        viewModel.endRun()
        showingRunSummary = true
    }
}

// MARK: - Strava Stat Card
private struct StravaStatCard: View {
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Strava Control Button
private struct StravaControlButton: View {
    let icon: String
    let color: Color
    let size: ButtonSize
    let action: () -> Void
    
    enum ButtonSize {
        case medium, large
        
        var dimension: CGFloat {
            switch self {
            case .medium: return 60
            case .large: return 80
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .medium: return 24
            case .large: return 32
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .scaleEffect(0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: color)
    }
}

// MARK: - Route Overlay
private struct RouteOverlay: View {
    let userPath: [CLLocationCoordinate2D]
    let ghostPath: [CLLocationCoordinate2D]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ghost path (purple line)
                Path { path in
                    guard !ghostPath.isEmpty else { return }
                    
                    let firstPoint = coordinateToPoint(ghostPath[0], in: geometry.frame(in: .local))
                    path.move(to: firstPoint)
                    
                    for coordinate in ghostPath.dropFirst() {
                        let point = coordinateToPoint(coordinate, in: geometry.frame(in: .local))
                        path.addLine(to: point)
                    }
                }
                .stroke(.purple.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                
                // User path (red line)
                Path { path in
                    guard !userPath.isEmpty else { return }
                    
                    let firstPoint = coordinateToPoint(userPath[0], in: geometry.frame(in: .local))
                    path.move(to: firstPoint)
                    
                    for coordinate in userPath.dropFirst() {
                        let point = coordinateToPoint(coordinate, in: geometry.frame(in: .local))
                        path.addLine(to: point)
                    }
                }
                .stroke(.red, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in rect: CGRect) -> CGPoint {
        // This is a simplified conversion - in a real app, you'd use the map's projection
        let x = (coordinate.longitude + 180) / 360 * rect.width
        let y = (90 - coordinate.latitude) / 180 * rect.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Route Annotation
struct RouteAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let isGhost: Bool
}

// MARK: - Preview
#Preview {
    ActiveRunView(selectedGhost: Ghost.mockData[0])
}
