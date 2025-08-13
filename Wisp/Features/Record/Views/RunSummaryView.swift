import SwiftUI
import MapKit

/// Run Summary screen showing completed run results with modern design
struct RunSummaryView: View {
    
    // MARK: - Properties
    let selectedGhost: Ghost
    let runData: RunSummaryData
    let viewModel: ActiveRunViewModel
    let onSave: () -> Void
    let onDiscard: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var runTitle = "Evening Run"
    @State private var showingDiscardAlert = false
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Main stats section
                    mainStatsSection
                    
                    // Run title input
                    runTitleInput
                    
                    // Ghost comparison (if applicable)
                    if runData.time > 0 {
                        ghostComparisonSection
                    }
                    
                    // Map section
                    mapSection
                    
                    // Additional stats
                    additionalStatsSection
                    
                    // Weather section (if available)
                    if let weatherData = runData.weatherData {
                        weatherSection(weatherData)
                    }
                    
                    // Action buttons
                    actionButtons
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Run Summary")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationBarHidden(true)
        .alert("Discard Run", isPresented: $showingDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                logger.info("Run discarded")
                viewModel.stopGPSTracking()
                onDiscard()
            }
        } message: {
            Text("Are you sure you want to discard this run? This action cannot be undone.")
        }
        .onAppear {
            logger.info("RunSummaryView appeared")
        }
    }
    
    // MARK: - Private Methods
    private func handleRunSave() {
        logger.info("Save run tapped from toolbar")
        viewModel.stopGPSTracking()
        onSave()
    }
    
    // MARK: - Main Stats Section
    private var mainStatsSection: some View {
        VStack(spacing: 16) {
            // Primary stats row
            HStack(spacing: 0) {
                StatItem(
                    title: "Distance",
                    value: runData.formattedDistance,
                    unit: "km"
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    title: "Time",
                    value: formatMainTime(runData.time),
                    unit: ""
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    title: "Pace",
                    value: runData.formattedAveragePace,
                    unit: "/km"
                )
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private func formatMainTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Run Title Input
    private var runTitleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Name")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Evening Run", text: $runTitle)
                .font(.body)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                if !runData.route.isEmpty {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: runData.route.first ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoutePathOverlay(coordinates: runData.route)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                
                                Text("No route data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
        }
    }
    
    // MARK: - Additional Stats Section
    private var additionalStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 1) {
                if let heartRate = runData.currentHeartRate {
                    StatRow(title: "Heart Rate", value: "\(heartRate)", unit: "bpm")
                }
                
                if let cadence = runData.currentCadence {
                    StatRow(title: "Cadence", value: "\(cadence)", unit: "spm")
                }
                
                if !runData.laps.isEmpty {
                    StatRow(title: "Laps", value: "\(runData.laps.count)", unit: "")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Weather Section
    private func weatherSection(_ weatherData: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Weather icon and temperature
                HStack(spacing: 8) {
                    Image(systemName: weatherData.condition.systemIconName)
                        .font(.title2)
                        .foregroundColor(weatherData.condition.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weatherData.formattedTemperature)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(weatherData.condition.readableDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Additional weather info
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Feels like \(weatherData.formattedFeelsLike)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(weatherData.humidityPercentage + " humidity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Ghost Comparison Section
    private var ghostComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("vs \(selectedGhost.name)")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Your time
                VStack(alignment: .leading, spacing: 4) {
                    Text("You")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(runData.formattedTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Comparison result
                VStack(spacing: 4) {
                    if runData.time < selectedGhost.time {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Won")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Lost")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Ghost time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(selectedGhost.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(selectedGhost.formattedTime)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save button with loading state
            Button(action: {
                logger.info("Save run tapped")
                onSave()
            }) {
                HStack(spacing: 8) {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(viewModel.isSaving ? "Saving..." : "Save Activity")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.isSaving ? Color.blue.opacity(0.6) : Color.blue)
                )
            }
            .disabled(viewModel.isSaving)
            
            // Show error message if save failed
            if let error = viewModel.saveError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Discard button
            Button(action: {
                showingDiscardAlert = true
            }) {
                Text("Discard Activity")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }
            .disabled(viewModel.isSaving) // Disable during save
        }
    }
}

// MARK: - Supporting Views

// MARK: - Stat Item
private struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Row
private struct StatRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
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
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in rect: CGRect) -> CGPoint {
        // Simplified conversion for demo
        let x = (coordinate.longitude + 180) / 360 * rect.width
        let y = (90 - coordinate.latitude) / 180 * rect.height
        return CGPoint(x: x, y: y)
    }
}


// MARK: - Preview
#Preview {
    RunSummaryView(
        selectedGhost: Ghost.mockData[0],
        runData: RunSummaryData(
            distance: 5000,
            time: 1400,
            averagePace: 300,
            currentHeartRate: 165,
            currentCadence: 180,
            route: [],
            laps: [], weatherData: WeatherData.mockData[0]
        ),
        viewModel: ActiveRunViewModel(),
        onSave: {},
        onDiscard: {}
    )
}
