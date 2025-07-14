import SwiftUI

/// Card component for displaying custom goal ghosts (training plans)
struct GoalGhostCard: View {
    
    // MARK: - Properties
    let goal: CustomGoalGhost
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with goal type and difficulty
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Start run button
                WispButton(
                    title: "",
                    style: .icon,
                    icon: "play.fill"
                ) {
                    handleStartRun()
                }
            }
            
            // Goal details
            HStack(spacing: 16) {
                GoalDetailView(
                    title: "Distance",
                    value: goal.formattedDistance,
                    icon: "location"
                )
                
                GoalDetailView(
                    title: "Target",
                    value: goal.formattedTargetTime,
                    icon: "target"
                )
                
                GoalDetailView(
                    title: "Pace",
                    value: goal.formattedTargetPace,
                    icon: "speedometer"
                )
            }
            
            // Progress bar (if goal has been attempted)
            if let progress = goal.progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 0.8)
                
                HStack {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            // Difficulty indicator
            HStack {
                Text("Difficulty:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                DifficultyIndicator(level: goal.difficulty)
                
                Spacer()
                
                // Category tag
                Text(goal.category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(goal.category.color.opacity(0.2))
                    .foregroundColor(goal.category.color)
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            logger.info("GoalGhostCard appeared for goal: \(goal.id)")
        }
    }
    
    // MARK: - Private Methods
    private func handleStartRun() {
        logger.info("Start run button tapped for goal: \(goal.id)")
        // TODO: Navigate to run selection with this goal
    }
}

// MARK: - Supporting Views

/// Individual goal detail display component
private struct GoalDetailView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.purple)
            
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

/// Difficulty level indicator
private struct DifficultyIndicator: View {
    let level: CustomGoalGhost.Difficulty
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < level.rawValue ? level.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        LazyVStack(spacing: 16) {
            ForEach(CustomGoalGhost.mockData) { goal in
                GoalGhostCard(goal: goal)
            }
        }
        .padding()
    }
}