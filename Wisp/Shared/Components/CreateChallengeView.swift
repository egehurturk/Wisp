import SwiftUI

/// Modal view for creating a new challenge
struct CreateChallengeView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var challengeTitle = ""
    @State private var challengeDescription = ""
    @State private var selectedType: Challenge.ChallengeType = .distance
    @State private var targetValue = ""
    @State private var duration = 30 // days
    @State private var isPrivate = false
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Challenge details form
                    formSection
                    
                    // Settings
                    settingsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChallenge()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            logger.info("CreateChallengeView appeared")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "trophy")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("Create New Challenge")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Set a goal and invite others to join you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            // Challenge title
            VStack(alignment: .leading, spacing: 8) {
                Text("Challenge Title")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField("Enter challenge title", text: $challengeTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Challenge description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField("Describe your challenge", text: $challengeDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Challenge type
            VStack(alignment: .leading, spacing: 8) {
                Text("Challenge Type")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Challenge Type", selection: $selectedType) {
                    ForEach(Challenge.ChallengeType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                            Text(type.rawValue)
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Target value
            VStack(alignment: .leading, spacing: 8) {
                Text("Target \(targetLabel)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField("Enter target value", text: $targetValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
            
            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Stepper(value: $duration, in: 1...365) {
                    Text("\(duration) days")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 16) {
            Toggle("Private Challenge", isOn: $isPrivate)
                .font(.headline)
            
            if isPrivate {
                Text("Only people you invite can join this challenge")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Anyone can discover and join this challenge")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Computed Properties
    private var targetLabel: String {
        switch selectedType {
        case .distance:
            return "Distance (km)"
        case .time:
            return "Time (minutes)"
        case .streak:
            return "Days"
        case .speed:
            return "Runs"
        case .community:
            return "Points"
        }
    }
    
    private var isFormValid: Bool {
        !challengeTitle.isEmpty && 
        !challengeDescription.isEmpty && 
        !targetValue.isEmpty &&
        Double(targetValue) != nil
    }
    
    // MARK: - Private Methods
    private func createChallenge() {
        logger.info("Creating challenge: \(challengeTitle)")
        
        // TODO: Implement actual challenge creation
        // For now, just dismiss the modal
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    CreateChallengeView()
}