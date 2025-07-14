import SwiftUI
import MapKit

/// Run Summary screen showing completed run results
struct RunSummaryView: View {
    
    // MARK: - Properties
    let selectedGhost: Ghost
    let runData: RunSummaryData
    let onSave: () -> Void
    let onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfetti = false
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Main stats
                    mainStatsSection
                    
                    // Ghost comparison
                    ghostComparisonSection
                    
                    // Route map
                    routeMapSection
                    
                    // Additional stats
                    additionalStatsSection
                    
                    // Action buttons
                    actionButtonsSection
                        .padding(.bottom, 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea()
            .navigationBarHidden(true)
        }
        .onAppear {
            logger.info("RunSummaryView appeared")
            
            // Check if user won and show confetti
            if runData.time < selectedGhost.time {
                showingConfetti = true
                
                // Hide confetti after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showingConfetti = false
                }
            }
        }
        .overlay(
            // Confetti overlay
            Group {
                if showingConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Run Complete!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Great job! Here's your run summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Main Stats Section
    private var mainStatsSection: some View {
        VStack(spacing: 20) {
            // Primary stats
            HStack(spacing: 30) {
                StatSummaryCard(
                    value: runData.formattedTime,
                    label: "Total Time",
                    icon: "clock"
                )
                
                StatSummaryCard(
                    value: runData.formattedDistance,
                    label: "Distance",
                    unit: "km",
                    icon: "location"
                )
                
                StatSummaryCard(
                    value: runData.formattedAveragePace,
                    label: "Avg Pace",
                    unit: "/km",
                    icon: "speedometer"
                )
            }
            
            // Secondary stats
            HStack(spacing: 30) {
                if let heartRate = runData.currentHeartRate {
                    StatSummaryCard(
                        value: "\(heartRate)",
                        label: "Avg Heart Rate",
                        unit: "bpm",
                        icon: "heart.fill"
                    )
                }
                
                StatSummaryCard(
                    value: "580",
                    label: "Calories",
                    unit: "kcal",
                    icon: "flame.fill"
                )
                
                if let cadence = runData.currentCadence {
                    StatSummaryCard(
                        value: "\(cadence)",
                        label: "Cadence",
                        unit: "spm",
                        icon: "figure.run"
                    )
                }
            }
        }
    }
    
    // MARK: - Ghost Comparison Section
    private var ghostComparisonSection: some View {
        VStack(spacing: 16) {
            Text("Ghost Race Results")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // User result
                VStack(spacing: 8) {
                    Text("You")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(runData.formattedTime)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Text("vs")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Ghost result
                VStack(spacing: 8) {
                    Text(selectedGhost.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(selectedGhost.formattedTime)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            // Result indicator
            HStack(spacing: 8) {
                Image(systemName: runData.time < selectedGhost.time ? "trophy.fill" : "flag.fill")
                    .foregroundColor(runData.time < selectedGhost.time ? .yellow : .orange)
                
                Text(runData.time < selectedGhost.time ? "You won!" : "Good effort!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Route Map Section
    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if !runData.route.isEmpty {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: runData.route.first ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))
                .frame(height: 200)
                .cornerRadius(16)
                .overlay(
                    RoutePathOverlay(coordinates: runData.route)
                )
            }
        }
    }
    
    // MARK: - Additional Stats Section
    private var additionalStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Laps")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if runData.laps.isEmpty {
                Text("No laps recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(runData.laps, id: \.number) { lap in
                        HStack {
                            Text("Lap \(lap.number)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(lap.formattedTime)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Save button
            Button(action: {
                logger.info("Save run tapped")
                dismiss()
                onSave()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    
                    Text("Save Run")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green)
                )
            }
            
            // Discard button
            Button(action: {
                logger.info("Discard run tapped")
                dismiss()
                onDiscard()
            }) {
                HStack {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                    
                    Text("Discard Run")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red)
                )
            }
        }
    }
}

// MARK: - Stat Summary Card
private struct StatSummaryCard: View {
    let value: String
    let label: String
    let unit: String?
    let icon: String
    
    init(value: String, label: String, unit: String? = nil, icon: String) {
        self.value = value
        self.label = label
        self.unit = unit
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Route Path Overlay
private struct RoutePathOverlay: View {
    let coordinates: [CLLocationCoordinate2D]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !coordinates.isEmpty else { return }
                
                let firstPoint = coordinateToPoint(coordinates[0], in: geometry.frame(in: .local))
                path.move(to: firstPoint)
                
                for coordinate in coordinates.dropFirst() {
                    let point = coordinateToPoint(coordinate, in: geometry.frame(in: .local))
                    path.addLine(to: point)
                }
            }
            .stroke(.red, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in rect: CGRect) -> CGPoint {
        // Simplified conversion for demo
        let x = (coordinate.longitude + 180) / 360 * rect.width
        let y = (90 - coordinate.latitude) / 180 * rect.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Confetti View
private struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces, id: \.id) { piece in
                    // Different shapes for more variety
                    Group {
                        switch piece.shape {
                        case .circle:
                            Circle()
                                .fill(piece.color)
                                .frame(width: piece.size, height: piece.size)
                        case .square:
                            RoundedRectangle(cornerRadius: 2)
                                .fill(piece.color)
                                .frame(width: piece.size, height: piece.size)
                        case .triangle:
                            Image(systemName: "triangle.fill")
                                .foregroundColor(piece.color)
                                .font(.system(size: piece.size))
                        }
                    }
                    .position(piece.position)
                    .rotationEffect(.degrees(piece.rotation))
                    .scaleEffect(piece.scale)
                    .opacity(piece.opacity)
                }
            }
        }
        .onAppear {
            startConfetti(in: UIScreen.main.bounds.size)
        }
    }
    
    private func startConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan, .mint]
        let shapes: [ConfettiShape] = [.circle, .square, .triangle]
        
        // Create confetti bursting from left and right sides
        for side in ["left", "right"] {
            for _ in 0..<30 {
                let startX = side == "left" ? -20.0 : size.width + 20
                let startY = Double.random(in: size.height * 0.3...size.height * 0.7)
                
                let piece = ConfettiPiece(
                    id: UUID(),
                    position: CGPoint(x: startX, y: startY),
                    color: colors.randomElement() ?? .blue,
                    rotation: Double.random(in: 0...360),
                    opacity: 1.0,
                    scale: 1.0,
                    size: Double.random(in: 6...12),
                    shape: shapes.randomElement() ?? .circle,
                    velocityX: side == "left" ? Double.random(in: 200...400) : Double.random(in: -400...(-200)),
                    velocityY: Double.random(in: -300...(-100))
                )
                confettiPieces.append(piece)
            }
        }
        
        // Animate confetti with physics-like motion
        for (index, piece) in confettiPieces.enumerated() {
            let delay = Double.random(in: 0...0.5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Calculate end position with gravity and air resistance
                let timeOfFlight = 3.0
                let gravity = 500.0 // pixels per second squared
                
                let endX = piece.position.x + piece.velocityX * timeOfFlight * 0.7 // air resistance
                let endY = piece.position.y + piece.velocityY * timeOfFlight + 0.5 * gravity * timeOfFlight * timeOfFlight
                
                withAnimation(.easeOut(duration: timeOfFlight)) {
                    confettiPieces[index].position = CGPoint(x: endX, y: endY)
                    confettiPieces[index].rotation += Double.random(in: 360...1080)
                    confettiPieces[index].scale = 0.3
                    confettiPieces[index].opacity = 0
                }
            }
        }
    }
}

private enum ConfettiShape {
    case circle, square, triangle
}

private struct ConfettiPiece {
    let id: UUID
    var position: CGPoint
    let color: Color
    var rotation: Double
    var opacity: Double
    var scale: Double
    let size: Double
    let shape: ConfettiShape
    let velocityX: Double
    let velocityY: Double
}

// MARK: - Preview
#Preview {
    RunSummaryView(
        selectedGhost: Ghost.mockData[0],
        runData: RunSummaryData(
            distance: 5000,
            time: 1500,
            averagePace: 300,
            currentHeartRate: 165,
            currentCadence: 180,
            route: [],
            laps: []
        ),
        onSave: {},
        onDiscard: {}
    )
}