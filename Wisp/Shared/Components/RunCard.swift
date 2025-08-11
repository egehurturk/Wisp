import SwiftUI
import MapKit

/// Card component displaying run information
struct RunCard: View {
    
    // MARK: - Properties
    let run: Run
    @State private var route: RunRoute?
    @State private var isLoadingRoute = false
    private let logger = Logger.ui
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Map area showing GPS route
            RunMapView(route: route)
                .frame(height: 120)
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
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(run.startedAt, style: .date)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            loadRouteData()
        }
    }
    
    // MARK: - Private Methods
    private func handleReplayTap() {
        logger.info("Replay button tapped for run: \(run.id)")
        // TODO: Navigate to replay screen
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






// TODO:
//  Poly lines are rendered incorrectly. Either do not render coordinates, custom decode the polyline and render it, or render the coordinates.
// 
