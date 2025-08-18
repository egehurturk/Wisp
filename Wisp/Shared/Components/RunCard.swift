import SwiftUI
import MapKit

/// Card component displaying run information
struct RunCard: View {
    
    // MARK: - Properties
    let run: Run
    @State private var route: RunRoute?
    @State private var isLoadingRoute = false
    @State private var showingDeleteConfirmation = false
    @State private var isPerformingAction = false
    private let logger = Logger.ui
    private let supabaseManager = SupabaseManager.shared
    
    // Callback for deletion
    var onDelete: ((Run) async -> Void)?
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Map area showing GPS route
            RunMapView(route: route)
                .frame(height: 200)
                .clipped()
                .overlay(
                    Group {
                        if isLoadingRoute {
                            ZStack {
                                Color.black.opacity(0.3)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                )
            
            // Run Information
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and distance
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(run.title ?? "Run")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        if let desc = run.description {
                            Text(desc)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text(run.startedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(run.formattedDistance)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Replay button
                        WispButton(
                            title: "",
                            style: .icon,
                            icon: "play.fill"
                        ) {
                            handleReplayTap()
                        }
                        .disabled(isPerformingAction)
                        
                        // Three-dots menu
                        Menu {
                            Button(action: {
                                handleChangeVisibility()
                            }) {
                                Label("Change visibility", systemImage: "eye")
                            }
                             
                            
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Delete run", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .disabled(isPerformingAction)
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
                            value: "\(Int(heartRate)) bpm",
                            icon: "heart.fill"
                        )
                    }
                }
                
                // Analysis text or other info can go here in the future
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            loadRouteData()
        }
        .overlay(
            // Progress overlay when performing actions
            Group {
                if isPerformingAction {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        )
        .confirmationDialog("Delete Run", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                handleDeleteRun()
            }
            Button("Cancel", role: .cancel) {
                // Dialog dismisses automatically
            }
        } message: {
            Text("Are you sure you want to delete this run? This action cannot be undone.")
        }
    }
    
    // MARK: - Private Methods
    private func handleReplayTap() {
        logger.info("Replay button tapped for run: \(run.id)")
        // TODO: Navigate to replay screen
    }
    
    private func handleChangeVisibility() {
        logger.info("Change visibility tapped for run: \(run.id)")
        // TODO: Implement visibility change
    }
    
    private func handleDeleteRun() {
        logger.info("Delete run confirmed for run: \(run.id)")
        
        Task {
            isPerformingAction = true
            await onDelete?(run)
            isPerformingAction = false
        }
    }
    
    private func loadRouteData() {
        // Only load route if run has location data
        guard run.hasLocation else { return }
        
        isLoadingRoute = true
        
        Task {
            do {
                let fetchedRoute = try await supabaseManager.fetchRunRoute(runId: run.id)
                await MainActor.run {
                    self.route = fetchedRoute
                    self.isLoadingRoute = false
                }
                logger.info("Successfully loaded route for run: \(run.id)")
            } catch {
                await MainActor.run {
                    self.isLoadingRoute = false
                }
                logger.error(String(describing: error))
                logger.error("Failed to load route for run: \(run.id)", error: error)
            }
        }
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




#Preview {
    var sample: Run = {
            let json = """
            {
              "id": "D0C8A4FF-CC1B-4C2C-8E1E-05C9D9811F4A",
              "user_id": "3E9A6F2B-2C1D-4A53-9B6E-1C2D3E4F5A6B",
              "external_id": "strava_1234567890",
              "data_source": "strava",
              "title": "Morning 10K",
              "description": "Easy pace around the park.",
              "distance": 10000.0,
              "moving_time": 2820,
              "elapsed_time": 2900,
              "average_pace": 282.0,
              "average_speed": 3.55,
              "average_cadence": 164.0,
              "average_heart_rate": 148.0,
              "max_heart_rate": 178.0,
              "calories_burned": 680.0,
              "start_latitude": 50.8503,
              "start_longitude": 4.3517,
              "end_latitude": 50.8470,
              "end_longitude": 4.3600,
              "elevation_gain": 85.0,
              "started_at": "2025-08-14T06:30:00Z",
              "timezone": "Europe/Brussels",
              "pace_splits": [285.0, 283.0, 282.0, 281.0, 282.0, 281.0, 280.0, 282.0, 283.0, 282.0],
              "heart_rate_data": [105, 120, 135, 145, 150, 155, 158, 160, 162, 165],
              "created_at": "2025-08-14T07:35:00Z",
              "updated_at": "2025-08-14T07:35:00Z"
            }
            """
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try! decoder.decode(Run.self, from: Data(json.utf8))
        }()
    RunCard(run: sample) {_ in 
        logger.info("tap delete")
    }
}
