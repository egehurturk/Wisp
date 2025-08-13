import SwiftUI
import Charts

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
        .onReceive(NotificationCenter.default.publisher(for: .runSaved)) { _ in
            logger.info("Received runSaved notification - refreshing data")
            Task {
                await viewModel.refreshData()
            }
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
            
            // Weekly chart replacing old stats
            weeklyChartView
        }
    }
    
    // MARK: - Weekly Chart View
    private var weeklyChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart title with navigation
            HStack {
                Button(action: {
                    viewModel.navigateToPreviousWeek()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(viewModel.weekTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    viewModel.navigateToNextWeek()
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.canNavigateToNextWeek ? .blue : .gray)
                }
                .disabled(!viewModel.canNavigateToNextWeek)
            }
            
            // Chart with smooth animation
            Chart(viewModel.weeklyChartData) { data in
                BarMark(
                    x: .value("Day", data.dayName),
                    y: .value("Distance", data.distance)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let distance = value.as(Double.self) {
                            Text("\(distance, specifier: "%.1f")")
                        }
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                    AxisTick()
                }
            }
            .chartYAxisLabel("Distance (km)", position: .leading)
            .animation(.easeInOut(duration: 0.6), value: viewModel.currentWeekOffset)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .gesture(
                DragGesture()
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: 0.6)) {
                            if value.translation.width > 50 {
                                // Swipe right - go to previous week
                                viewModel.navigateToPreviousWeek()
                            } else if value.translation.width < -50 && viewModel.canNavigateToNextWeek {
                                // Swipe left - go to next week (if available)
                                viewModel.navigateToNextWeek()
                            }
                        }
                    }
            )
            
            // Summary stats below chart
            HStack(spacing: 16) {
                Text("Runs: \(viewModel.runCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Distance: \(viewModel.totalDistance)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Time: \(viewModel.totalDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Latest Run Section
    private var pastRunsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text("Latest Run")
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
            } else if let latestRun = viewModel.latestRun {
                VStack(alignment: .leading, spacing: 12) {
                    RunCard(run: latestRun)
                    
                    // Analysis text
                    Text(viewModel.analysisText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            } else {
                EmptyStateView(
                    title: "No runs yet",
                    message: "Ready for your first run?",
                    icon: "figure.run"
                )
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
                    GoalGhostCard(goal: goal).background(GradientBackground())
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
                            ChallengeCard(challenge: challenge).background(GradientBackground())
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
