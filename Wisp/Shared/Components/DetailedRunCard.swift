import SwiftUI
import MapKit

/// Detailed run card component for the Runs screen, similar to Strava's activities
struct DetailedRunCard: View {
    
    // MARK: - Properties
    let run: PastRun
    let ghostResult: GhostRaceResult?
    let onTitleEdit: (String) -> Void
    
    @State private var isEditingTitle = false
    @State private var editingTitle = ""
    @State private var showingTrophyAnimation = false
    @State private var showingReplaySheet = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and date
            headerSection
            
            // Map view
            mapSection
            
            // Statistics section
            statsSection
            
            // Ghost result section
            if let ghostResult = ghostResult {
                ghostResultSection(ghostResult)
            }
            
            // Footer with actions
            footerSection
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            // Handle card tap - could navigate to detailed view
        }
        .sheet(isPresented: $showingReplaySheet) {
            RunReplaySheet(run: run, ghostResult: ghostResult)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // Title (editable)
                if isEditingTitle {
                    TextField("Run title", text: $editingTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            saveTitle()
                        }
                } else {
                    Text(run.generatedTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .onTapGesture {
                            startEditingTitle()
                        }
                }
                
                // Date and location
                HStack(spacing: 8) {
                    Label(formatDate(run.date), systemImage: "calendar")
                    
                    Label(run.location, systemImage: "location")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Weather info
                if let weather = run.weather, let temperature = run.temperature {
                    HStack(spacing: 8) {
                        Label(weather, systemImage: weatherIcon(for: weather))
                        Label(temperature, systemImage: "thermometer")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: {
                if isEditingTitle {
                    saveTitle()
                } else {
                    startEditingTitle()
                }
            }) {
                Image(systemName: isEditingTitle ? "checkmark.circle.fill" : "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        ZStack {
            // Map background
            Map(coordinateRegion: .constant(run.route.region))
                .frame(height: 200)
                .allowsHitTesting(false)
            
            // Route overlay would go here in a real implementation
            // For now, we'll show a simple overlay
            RouteOverlayView(route: run.route)
        }
        .clipped()
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItem(
                title: "Distance",
                value: run.formattedDistance,
                icon: "location"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Time",
                value: run.formattedDuration,
                icon: "clock"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Pace",
                value: run.formattedPace,
                icon: "speedometer"
            )
            
            if let heartRate = run.averageHeartRate {
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    title: "Avg HR",
                    value: "\(heartRate)",
                    icon: "heart"
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Ghost Result Section
    private func ghostResultSection(_ ghostResult: GhostRaceResult) -> some View {
        VStack(spacing: 12) {
            Divider()
            
            if showingTrophyAnimation {
                TrophyAnimation(
                    didWin: ghostResult.didWin,
                    isUserWinner: ghostResult.didWin,
                    ghostName: ghostResult.ghostName,
                    timeDifference: ghostResult.timeDifference
                )
            } else {
                // Static ghost result display
                HStack(spacing: 12) {
                    // Ghost icon
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("vs \(ghostResult.ghostName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 4) {
                            Text(ghostResult.didWin ? "Won" : "Lost")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(ghostResult.didWin ? .green : .red)
                            
                            if let timeDiff = ghostResult.timeDifference {
                                Text("by \(timeDiff)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Result icon
                    Image(systemName: ghostResult.didWin ? "trophy.fill" : "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(ghostResult.didWin ? .yellow : .red)
                }
                .padding(.horizontal, 16)
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingTrophyAnimation = true
                    }
                    
                    // Hide animation after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showingTrophyAnimation = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        HStack {
            Button(action: {
                showingReplaySheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle")
                    Text("Replay")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: {
                // Share functionality
                shareRun()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func weatherIcon(for weather: String) -> String {
        switch weather.lowercased() {
        case "sunny":
            return "sun.max"
        case "cloudy", "partly cloudy":
            return "cloud"
        case "light rain", "rain":
            return "cloud.rain"
        case "overcast":
            return "cloud.fill"
        case "foggy":
            return "cloud.fog"
        case "windy":
            return "wind"
        default:
            return "cloud"
        }
    }
    
    private func startEditingTitle() {
        editingTitle = run.generatedTitle
        isEditingTitle = true
    }
    
    private func saveTitle() {
        if !editingTitle.isEmpty {
            onTitleEdit(editingTitle)
        }
        isEditingTitle = false
    }
    
    private func shareRun() {
        // TODO: Implement share functionality
        print("Sharing run: \(run.generatedTitle)")
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Route Overlay View
private struct RouteOverlayView: View {
    let route: RunRoute
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !route.waypoints.isEmpty else { return }
                
                let firstPoint = coordinateToPoint(
                    route.waypoints[0].coordinate,
                    in: geometry.frame(in: .local),
                    region: route.region
                )
                path.move(to: firstPoint)
                
                for waypoint in route.waypoints.dropFirst() {
                    let point = coordinateToPoint(
                        waypoint.coordinate,
                        in: geometry.frame(in: .local),
                        region: route.region
                    )
                    path.addLine(to: point)
                }
            }
            .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D, in rect: CGRect, region: MKCoordinateRegion) -> CGPoint {
        let x = (coordinate.longitude - region.center.longitude + region.span.longitudeDelta / 2) / region.span.longitudeDelta * rect.width
        let y = (region.center.latitude - coordinate.latitude + region.span.latitudeDelta / 2) / region.span.latitudeDelta * rect.height
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Run Replay Sheet
private struct RunReplaySheet: View {
    let run: PastRun
    let ghostResult: GhostRaceResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Run Replay")
                    .font(.title)
                    .padding()
                
                Text("Replay functionality will show the race between you and \(ghostResult?.ghostName ?? "your ghost") on this route.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                Text("Coming Soon!")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Replay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            DetailedRunCard(
                run: PastRun.extendedMockData[0],
                ghostResult: GhostRaceResult.extendedMockData[0],
                onTitleEdit: { _ in }
            )
            
            DetailedRunCard(
                run: PastRun.extendedMockData[1],
                ghostResult: GhostRaceResult.extendedMockData[1],
                onTitleEdit: { _ in }
            )
        }
        .padding()
    }
}