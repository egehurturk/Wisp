import SwiftUI

/// Main tab bar controller for the Wisp app
struct MainTabView: View {
    
    // MARK: - Properties
    @State private var selectedTab: Tab = .home
    @State private var showingSelectRunType = false
    @State private var showingStravaModal = false
    private let logger = Logger.ui
    
    // MARK: - Tab Enum
    enum Tab: String, CaseIterable {
        case home = "Home"
        case runs = "Runs"
        case record = "Record"
        case ghosts = "Ghosts"
        case statistics = "Statistics"
        case goals = "Goals"
        case groups = "Groups"
        case settings = "Settings"
        
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .runs: return "figure.run"
            case .ghosts: return "sparkles"
            case .record: return "record.circle"
            case .statistics: return "chart.bar"
            case .goals: return "target"
            case .groups: return "person.3"
            case .settings: return "gearshape"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .runs: return "figure.run"
            case .ghosts: return "sparkles"
            case .record: return "record.circle.fill"
            case .statistics: return "chart.bar.fill"
            case .goals: return "target"
            case .groups: return "person.3.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var displayName: String {
            switch self {
            case .ghosts: return "Ghosts"
            case .record: return "Run"
            case .statistics: return "Stats"
            case .goals: return "Goals"
            case .groups: return "Groups"
            default: return rawValue
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Tab Content
            TabView(selection: $selectedTab) {
                HomeView(onNavigateToRuns: {
                    selectedTab = .runs
                })
                    .tag(Tab.home)
                
                RunsView()
                    .tag(Tab.runs)
                
                
                // Record button handled separately
                
                GhostsView()
                    .tag(Tab.ghosts)
                
                GroupsView()
                    .tag(Tab.groups)
                
                SettingsView()
                    .tag(Tab.settings)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom Tab Bar - Floating
            VStack {
                Spacer()
                customTabBar
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingSelectRunType) {
            SelectRunTypeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingStravaModal) {
            StravaConnectionModalView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedTab) { newTab in
            handleTabChange(newTab)
        }
        .onAppear {
            checkAndShowStravaModal()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            logger.info("Received navigation to home notification")
            
            // Dismiss the SelectRunTypeView modal
            showingSelectRunType = false
            
            // Navigate to home tab
            selectedTab = .home
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Home Tab
            tabBarItem(for: .home)
            
            // Runs Tab
            tabBarItem(for: .runs)
            
            // Record Button (Center)
            recordButton
            
            // Ghosts Tab
            tabBarItem(for: .ghosts)
            
            // Settings Tab
            tabBarItem(for: .settings)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 34) // Account for home indicator
    }
    
    // MARK: - Tab Bar Items
    private func tabBarItem(for tab: Tab) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 1) {
                ZStack {
                    // Background for selected tab
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 64, height: 36)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .blue : .gray)
                }
                
                Text(tab.displayName)
                    .font(.caption2)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    // MARK: - Record Button
    private var recordButton: some View {
        Button(action: {
            handleRecordButtonTap()
        }) {
            ZStack {
                Circle()
                    .fill(.red)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(selectedTab == .record ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab == .record)
    }
    
    
    // MARK: - Private Methods
    private func handleTabChange(_ newTab: Tab) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleRecordButtonTap() {
        logger.info("Record button tapped")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Show Select Run Type screen
        showingSelectRunType = true
    }
    
    private func checkAndShowStravaModal() {
        if UserDefaults.standard.shouldShowStravaConnectionModal() {
            logger.info("Showing Strava connection modal for first-time user")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingStravaModal = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
