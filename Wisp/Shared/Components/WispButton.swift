import SwiftUI

/// Custom button component with Wisp branding and multiple styles
struct WispButton: View {
    
    // MARK: - Button Styles
    enum Style {
        case primary
        case secondary
        case icon
        case record
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray.opacity(0.2)
            case .icon: return .clear
            case .record: return .red
            case .ghost: return .purple.opacity(0.8)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            case .icon: return .blue
            case .record: return .white
            case .ghost: return .white
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray.opacity(0.3)
            case .icon: return .clear
            case .record: return .red
            case .ghost: return .purple
            }
        }
    }
    
    // MARK: - Properties
    let title: String
    let style: Style
    let action: () -> Void
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    
    private let logger = Logger.ui
    
    // MARK: - Initialization
    init(
        title: String,
        style: Style = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: handleButtonTap) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    if !title.isEmpty {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .foregroundColor(isDisabled ? .gray : style.foregroundColor)
            .padding(.horizontal, style == .icon ? 8 : 16)
            .padding(.vertical, style == .icon ? 8 : 12)
            .background(
                RoundedRectangle(cornerRadius: style == .record ? 40 : 12)
                    .fill(isDisabled ? Color.gray.opacity(0.3) : style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: style == .record ? 40 : 12)
                            .stroke(style.borderColor, lineWidth: 1)
                    )
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
    
    // MARK: - Private Methods
    private func handleButtonTap() {
        logger.info("Button tapped: \(title)")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        action()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        WispButton(title: "Start Run", style: .primary) { }
        WispButton(title: "Secondary", style: .secondary) { }
        WispButton(title: "", style: .icon, icon: "play.fill") { }
        WispButton(title: "Record", style: .record) { }
        WispButton(title: "Ghost Mode", style: .ghost) { }
        WispButton(title: "Loading", isLoading: true) { }
        WispButton(title: "Disabled", isDisabled: true) { }
    }
    .padding()
}