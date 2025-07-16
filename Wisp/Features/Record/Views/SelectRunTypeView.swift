import SwiftUI

/// Select Run Type bottom sheet with minimalistic design
struct SelectRunTypeView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var showGhostCard = false
    @State private var showGroupCard = false
    @State private var selectedType: RunType? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var showingGhostSelection = false
    private let logger = Logger.ui
    
    enum RunType {
        case ghost
        case group
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag handle
                dragHandle
                
                // Header
                headerSection
                
                ScrollView {
                    // Run type cards
                    VStack(spacing: 24) {
                        // Ghost Run Card
                        GhostRunCard(isSelected: selectedType == .ghost) {
                            handleGhostRunTap()
                        }
                        .opacity(showGhostCard ? 1 : 0)
                        .offset(y: showGhostCard ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: showGhostCard)
                        .padding(.top, 20)
                        
                        // Group Run Card
                        GroupRunCard(isSelected: selectedType == .group) {
                            handleGroupRunTap()
                        }
                        .opacity(showGroupCard ? 1 : 0)
                        .offset(y: showGroupCard ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showGroupCard)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 40)
                
                // Continue button
                if selectedType != nil {
                    continueButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedType)
                }
            }
            .padding(.bottom, 40) // Account for home indicator and spacing
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height > 0 {
                            dragOffset = gesture.translation.height
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.height > 100 {
                            dismiss()
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .sheet(isPresented: $showingGhostSelection) {
            GhostSelectionView()
        }
        .onAppear {
            logger.info("SelectRunTypeView appeared")
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            logger.info("SelectRunTypeView received navigation to home notification")
            dismiss()
        }
    }
    
    // MARK: - Drag Handle
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 40, height: 6)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Choose Run Type")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Select how you want to run today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: handleContinue) {
            HStack(spacing: 12) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue)
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Private Methods
    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showGhostCard = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showGroupCard = true
        }
    }
    
    private func handleGhostRunTap() {
        logger.info("Ghost run selected")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedType = .ghost
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleGroupRunTap() {
        logger.info("Group run selected")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedType = .group
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleContinue() {
        logger.info("Continue tapped with type: \(selectedType?.description ?? "none")")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Navigate to appropriate screen
        switch selectedType {
        case .ghost:
            showingGhostSelection = true
        case .group:
            // TODO: Navigate to group selection
            break
        case .none:
            break
        }
    }
}

// MARK: - Ghost Run Card
private struct GhostRunCard: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // Icon and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Run Against Ghost")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Race against your past runs, PRs, or training goals")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Features
                VStack(spacing: 12) {
                    FeatureRow(icon: "trophy", text: "Beat your personal records")
                    FeatureRow(icon: "target", text: "Chase training goals")
                    FeatureRow(icon: "clock", text: "Real-time comparisons")
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.purple : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Group Run Card
private struct GroupRunCard: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // Icon and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.3")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Run With Group")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Join friends and race together against a ghost")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Features
                VStack(spacing: 12) {
                    FeatureRow(icon: "person.2", text: "Run with friends")
                    FeatureRow(icon: "location", text: "Live location sharing")
                    FeatureRow(icon: "chart.bar", text: "Group statistics")
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.orange : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}


// MARK: - Extensions
extension SelectRunTypeView.RunType {
    var description: String {
        switch self {
        case .ghost: return "ghost"
        case .group: return "group"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SelectRunTypeView()
    }
}
