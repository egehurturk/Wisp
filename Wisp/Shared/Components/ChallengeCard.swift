import SwiftUI

/// Card component for displaying challenges
struct ChallengeCard: View {
    
    // MARK: - Properties
    let challenge: Challenge
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Challenge header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(challenge.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    }
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                // Challenge icon
                Image(systemName: challenge.type.icon)
                    .font(.title2)
                    .foregroundColor(challenge.type.color)
                    .frame(width: 32, height: 32)
            }
            
            // Challenge details
            VStack(alignment: .leading, spacing: 8) {
                // Progress bar
                ProgressView(value: challenge.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 1.2)
                    .tint(challenge.type.color)
                
                HStack {
                    Text(challenge.progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(challenge.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(challenge.type.color)
                }
                
                // Time remaining
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(challenge.timeRemainingText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Participant count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(challenge.participantCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Action button
            WispButton(
                title: challenge.isJoined ? "View Progress" : "Join Challenge",
                style: challenge.isJoined ? .icon : .icon,
                icon: challenge.isJoined ? "chart.bar" : "plus"
            ) {
                handleButtonTap()
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(challenge.type.color.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
        }
    }
    
    // MARK: - Private Methods
    private func handleButtonTap() {
        // TODO: Handle join/view challenge
    }
}

// MARK: - Preview
#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(Challenge.mockData) { challenge in
                ChallengeCard(challenge: challenge)
            }
        }
        .padding()
    }
}
