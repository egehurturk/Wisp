import SwiftUI

/// Ghost Selection screen for choosing a running competitor
struct GhostSelectionView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGhost: Ghost?
    @State private var searchText = ""
    @State private var selectedCategory: Ghost.GhostType? = nil
    @State private var showingActiveRun = false
    private let logger = Logger.ui
    
    private var filteredGhosts: [Ghost] {
        var ghosts = Ghost.mockData
        
        // Filter by category
        if let category = selectedCategory {
            ghosts = ghosts.filter { $0.type == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            ghosts = ghosts.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return ghosts
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Ghost list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredGhosts) { ghost in
                            GhostCard(
                                ghost: ghost,
                                isSelected: selectedGhost?.id == ghost.id
                            ) {
                                selectGhost(ghost)
                            }
                        }
                    }
                    .padding()
                }
                
                // Start run button
                if selectedGhost != nil {
                    startRunButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedGhost)
                }
            }
            .navigationTitle("Choose Your Ghost")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingActiveRun) {
            if let ghost = selectedGhost {
                ActiveRunView(selectedGhost: ghost)
            }
        }
        .onAppear {
            logger.info("GhostSelectionView appeared")
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            logger.info("GhostSelectionView received navigation to home notification")
            dismiss()
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search ghosts...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryButton(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(Ghost.GhostType.allCases, id: \.self) { category in
                        CategoryButton(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Start Run Button
    private var startRunButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: startRun) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("Start Run")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let ghost = selectedGhost {
                        Text("vs \(ghost.name)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green)
                )
            }
            .padding()
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Private Methods
    private func selectGhost(_ ghost: Ghost) {
        logger.info("Ghost selected: \(ghost.name)")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedGhost = ghost
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func startRun() {
        guard let ghost = selectedGhost else { return }
        logger.info("Starting run with ghost: \(ghost.name)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Navigate to Active Run screen
        showingActiveRun = true
    }
}

// MARK: - Ghost Card
private struct GhostCard: View {
    let ghost: Ghost
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar and type indicator
                ZStack {
                    Circle()
                        .fill(ghost.type.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    if let avatarURL = ghost.avatarImageURL {
                        AsyncImage(url: URL(string: avatarURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: ghost.type.icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(ghost.type.color)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: ghost.type.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(ghost.type.color)
                    }
                    
                    // Strava badge
                    if ghost.type == .stravaFriend {
                        Image(systemName: "s.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                            .background(Circle().fill(.white))
                            .offset(x: 20, y: -20)
                    }
                }
                
                // Ghost info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(ghost.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(ghost.type.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ghost.type.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(ghost.type.color.opacity(0.2))
                            )
                    }
                    
                    Text(ghost.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatPill(label: "Distance", value: ghost.formattedDistance)
                        StatPill(label: "Time", value: ghost.formattedTime)
                        StatPill(label: "Pace", value: ghost.formattedPace)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.green : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Category Button
private struct CategoryButton: View {
    let title: String
    let icon: String?
    let color: Color?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, color: Color? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : (color ?? .primary))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? (color ?? .blue) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(color ?? .secondary, lineWidth: 1)
                            .opacity(isSelected ? 0 : 1)
                    )
            )
        }
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    GhostSelectionView()
}