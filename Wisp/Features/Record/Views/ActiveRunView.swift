import SwiftUI
import MapKit

/// Active Run screen with Strava/Nike-style design
struct ActiveRunView: View {
    
    // MARK: - Properties
    let selectedGhost: Ghost
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActiveRunViewModel()
    @State private var showingPauseMenu = false
    @State private var countdownNumber: Int? = nil
    @State private var showingCountdown = false
    @State private var showingRunSummary = false
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // New layout based on screenshot
            VStack(spacing: 0) {
                // Map section at top (or stats when paused)
                if viewModel.isRunning {
                    mapContentView
                        .frame(maxHeight: .infinity)
                } else {
                    pausedStatsView
                        .frame(maxHeight: .infinity)
                }
                
                // Stats section at bottom
                bottomStatsSection
                
                // Control buttons below stats
                controlButtonsSection
                    .padding(.bottom, 40)
            }
            
            // Countdown overlay
            if showingCountdown {
                countdownOverlay
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
    
    // MARK: - Map Content View
    private var mapContentView: some View {
        ZStack {
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
            .disabled(true)
            
            // Clean map without overlay
        }
    }
    
    // MARK: - Paused Stats View
    private var pausedStatsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Run Paused")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Tap play to continue your run")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Bottom Stats Section
    private var bottomStatsSection: some View {
        VStack(spacing: 20) {
            // Primary stats row
            HStack(spacing: 30) {
                StatDisplay(
                    value: viewModel.formattedAveragePace,
                    label: "AVG PACE",
                    isLarge: true
                )
                
                StatDisplay(
                    value: viewModel.formattedDistance,
                    label: "DISTANCE", 
                    isLarge: true
                )
                
                StatDisplay(
                    value: "580",
                    label: "CALORIES",
                    unit: "kcal",
                    isLarge: true
                )
            }
            
            // Secondary stats row
            HStack(spacing: 30) {
                StatDisplay(
                    value: viewModel.formattedTime,
                    label: "TIME",
                    isLarge: true
                )
                
                StatDisplay(
                    value: "12",
                    label: "ELEVATION",
                    unit: "m",
                    isLarge: true
                )
                
                if let heartRate = viewModel.currentHeartRate {
                    StatDisplay(
                        value: "\(heartRate)",
                        label: "BPM",
                        unit: "bpm",
                        isLarge: true
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .foregroundColor(.primary)
    }
    
    // MARK: - Ghost Comparison Card
    private var ghostComparisonCard: some View {
        HStack(spacing: 12) {
            // Ghost avatar
            ZStack {
                Circle()
                    .fill(.pink)
                    .frame(width: 40, height: 40)
                
                Text("APT.")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedGhost.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(viewModel.isAheadOfGhost ? "+1:14" : "-1:14")
                        .font(.subheadline)
                        .foregroundColor(viewModel.isAheadOfGhost ? .green : .red)
                    
                    // Control icons
                    HStack(spacing: 12) {
                        Image(systemName: "backward.fill")
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                        Image(systemName: "forward.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Control Buttons Section
    private var controlButtonsSection: some View {
        HStack(spacing: 60) {
            // Lap button
            ControlButton(
                icon: "arrow.clockwise",
                color: .gray,
                size: .medium
            ) {
                addLap()
            }
            
            // Pause/Resume button
            ControlButton(
                icon: viewModel.isRunning ? "pause.fill" : "play.fill",
                color: .orange,
                size: .large
            ) {
                toggleRunning()
            }
            
            // Finish button
            ControlButton(
                icon: "stop.fill",
                color: .gray,
                size: .medium
            ) {
                finishRun()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
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
        } else {
            viewModel.resumeRun()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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

// MARK: - Stat Display
private struct StatDisplay: View {
    let value: String
    let label: String
    let unit: String?
    let isLarge: Bool
    
    init(value: String, label: String, unit: String? = nil, isLarge: Bool = false) {
        self.value = value
        self.label = label
        self.unit = unit
        self.isLarge = isLarge
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(isLarge ? .largeTitle : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Control Button
private struct ControlButton: View {
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
                )
        }
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
