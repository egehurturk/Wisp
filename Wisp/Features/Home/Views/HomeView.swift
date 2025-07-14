import SwiftUI

/// Home screen view displaying past runs and custom goal ghosts
struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @State private var scrollOffset: CGFloat = 0
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // User profile and greeting section
                    profileSection
                    
                    // Past runs section
                    pastRunsSection
                    
                    // Challenges section
                    challengesSection
                    
                    // Custom goal ghosts section
                    customGoalsSection
                }
                .padding()
                .padding(.bottom, 100) // Add bottom padding for floating tab bar
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            logger.info("HomeView appeared")
            viewModel.loadData()
        }
    }
    
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 20) {
            // Greeting card
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.greetingMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Ready for your next run?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    handleProfileTap()
                }) {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 52, height: 52)
                        
                        AsyncImage(url: viewModel.userProfileImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            // Quick stats row
            HStack(spacing: 16) {
                QuickStatCard(title: "This Week", value: "12.5 km", icon: "figure.run", color: .blue)
                QuickStatCard(title: "Best Pace", value: "4:32/km", icon: "speedometer", color: .green)
                QuickStatCard(title: "Streak", value: "5 days", icon: "flame", color: .orange)
            }
        }
    }
    
    // MARK: - Past Runs Section
    private var pastRunsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text("Past Runs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button("View All") {
                    handleViewAllRunsTap()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
            
            if viewModel.isLoadingRuns {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.pastRuns.isEmpty {
                EmptyStateView(
                    title: "No runs yet",
                    message: "Start your first run to see it here!",
                    icon: "figure.run"
                )
            } else {
                ForEach(Array(zip(viewModel.pastRuns, viewModel.ghostResults)), id: \.0.id) { run, ghostResult in
                    RunCard(run: run, ghostResult: ghostResult)
                }
            }
        }
    }
    
    // MARK: - Custom Goals Section
    private var customGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(.purple)
                    
                    Text("Training Goals")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button("View All") {
                    handleViewAllGoalsTap()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            }
            
            if viewModel.isLoadingGoals {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.customGoals.isEmpty {
                EmptyStateView(
                    title: "No goals set",
                    message: "Create your first training goal to get started!",
                    icon: "target"
                )
            } else {
                ForEach(viewModel.customGoals) { goal in
                    GoalGhostCard(goal: goal)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleProfileTap() {
        logger.info("Profile button tapped")
        // TODO: Navigate to profile screen
    }
    
    private func handleViewAllRunsTap() {
        logger.info("View all runs tapped")
        // TODO: Navigate to runs screen
    }
    
    private func handleViewAllGoalsTap() {
        logger.info("View all goals tapped")
        // TODO: Navigate to goals screen
    }
    
    // MARK: - Challenges Section
    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("Challenges")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button("View All") {
                    handleViewAllChallengesTap()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            }
            
            if viewModel.isLoadingChallenges {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.challenges.isEmpty {
                EmptyStateView(
                    title: "No challenges",
                    message: "Join challenges to compete with others!",
                    icon: "trophy"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.challenges) { challenge in
                            ChallengeCard(challenge: challenge)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private func handleViewAllChallengesTap() {
        logger.info("View all challenges tapped")
        // TODO: Navigate to challenges screen
    }
}

// MARK: - Quick Stat Card
private struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}