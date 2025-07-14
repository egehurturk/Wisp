import SwiftUI

/// Home screen view displaying past runs and custom goal ghosts
struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var showingCreateChallenge = false
    @State private var showingProfileMenu = false
    private let logger = Logger.ui
    
    // Callback to switch tabs - will be provided by parent
    var onNavigateToRuns: (() -> Void)?
    
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
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView()
        }
        .overlay(
            // Profile dropdown overlay
            Group {
                if showingProfileMenu {
                    ZStack {
                        // Background overlay to detect taps outside
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingProfileMenu = false
                                }
                            }
                        
                        // Dropdown menu positioned below profile picture
                        VStack {
                            HStack {
                                Spacer()
                                ProfileDropdownMenu(
                                    userName: "John Doe",
                                    userLocation: "San Francisco, CA",
                                    onEditProfile: {
                                        handleEditProfile()
                                    },
                                    onSettings: {
                                        handleSettings()
                                    },
                                    onNotifications: {
                                        handleNotifications()
                                    },
                                    onHelp: {
                                        handleHelp()
                                    },
                                    onSignOut: {
                                        handleSignOut()
                                    },
                                    onDismiss: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showingProfileMenu = false
                                        }
                                    }
                                )
                                .padding(.trailing, 20)
                            }
                            .padding(.top, 130) // Position below profile section
                            
                            Spacer()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(1000)
                }
            }
        )
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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingProfileMenu.toggle()
        }
    }
    
    private func handleEditProfile() {
        logger.info("Edit profile tapped")
        showingProfileMenu = false
        // TODO: Navigate to edit profile screen
    }
    
    private func handleSettings() {
        logger.info("Settings tapped")
        showingProfileMenu = false
        // TODO: Navigate to settings screen
    }
    
    private func handleNotifications() {
        logger.info("Notifications tapped")
        showingProfileMenu = false
        // TODO: Navigate to notifications screen
    }
    
    private func handleHelp() {
        logger.info("Help tapped")
        showingProfileMenu = false
        // TODO: Navigate to help screen
    }
    
    private func handleSignOut() {
        logger.info("Sign out tapped")
        showingProfileMenu = false
        // TODO: Handle sign out
    }
    
    private func handleViewAllRunsTap() {
        logger.info("View all runs tapped")
        onNavigateToRuns?()
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
            }
            
            if viewModel.isLoadingChallenges {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Create new challenge card (first card)
                        CreateChallengeCard {
                            handleCreateChallengeTap()
                        }
                        .padding(.horizontal, 6)
                        
                        // Existing challenge cards
                        ForEach(viewModel.challenges) { challenge in
                            ChallengeCard(challenge: challenge)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private func handleCreateChallengeTap() {
        logger.info("Create challenge tapped")
        showingCreateChallenge = true
    }
}

// MARK: - Profile Dropdown Menu
private struct ProfileDropdownMenu: View {
    let userName: String
    let userLocation: String
    let onEditProfile: () -> Void
    let onSettings: () -> Void
    let onNotifications: () -> Void
    let onHelp: () -> Void
    let onSignOut: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // User info header
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(userLocation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Circle().fill(.gray.opacity(0.2)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
            }
            
            // Menu items
            VStack(spacing: 0) {
                ProfileMenuItem(
                    title: "Edit Profile",
                    icon: "person.circle",
                    color: .blue,
                    action: onEditProfile
                )
                
                ProfileMenuItem(
                    title: "Settings",
                    icon: "gear",
                    color: .gray,
                    action: onSettings
                )
                
                ProfileMenuItem(
                    title: "Notifications",
                    icon: "bell",
                    color: .orange,
                    action: onNotifications
                )
                
                ProfileMenuItem(
                    title: "Help & Support",
                    icon: "questionmark.circle",
                    color: .green,
                    action: onHelp
                )
                
                Divider()
                    .padding(.horizontal, 16)
                
                ProfileMenuItem(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right",
                    color: .red,
                    action: onSignOut
                )
            }
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .frame(width: 260)
    }
}

// MARK: - Profile Menu Item
private struct ProfileMenuItem: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(.clear)
                .onTapGesture(perform: action)
        )
    }
}

// MARK: - Create Challenge Card
private struct CreateChallengeCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Plus icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 4) {
                    Text("Create")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("New Challenge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.05))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
