import SwiftUI

/// Animated trophy component for displaying ghost race results
struct TrophyAnimation: View {
    
    // MARK: - Properties
    let didWin: Bool
    let isUserWinner: Bool
    let ghostName: String
    let timeDifference: String?
    @State private var animationScale: CGFloat = 0.8
    @State private var animationOpacity: Double = 0.0
    @State private var showConfetti: Bool = false
    @State private var bounceAnimation: Bool = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            // Trophy and winner display
            HStack(spacing: 16) {
                // User avatar/profile
                userAvatarView
                
                // Trophy in center
                trophyView
                
                // Ghost avatar
                ghostAvatarView
            }
            
            // Result text
            resultTextView
            
            // Time difference
            if let timeDifference = timeDifference {
                timeDifferenceView(timeDifference)
            }
        }
        .scaleEffect(animationScale)
        .opacity(animationOpacity)
        .onAppear {
            startAnimation()
        }
        .overlay(
            // Confetti effect for wins
            confettiOverlay
        )
    }
    
    // MARK: - User Avatar View
    private var userAvatarView: some View {
        ZStack {
            Circle()
                .fill(isUserWinner ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .scaleEffect(isUserWinner ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3).delay(0.5), value: isUserWinner)
            
            // User icon
            Image(systemName: "person.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isUserWinner ? .green : .gray)
        }
        .overlay(
            // Winner crown
            crownOverlay(isWinner: isUserWinner)
        )
    }
    
    // MARK: - Trophy View
    private var trophyView: some View {
        ZStack {
            // Trophy background
            Circle()
                .fill(Color.yellow.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: bounceAnimation)
            
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(bounceAnimation ? 15 : 0))
                .animation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true), value: bounceAnimation)
        }
        .shadow(color: .yellow.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Ghost Avatar View
    private var ghostAvatarView: some View {
        ZStack {
            Circle()
                .fill(!isUserWinner ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .scaleEffect(!isUserWinner ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3).delay(0.5), value: !isUserWinner)
            
            // Ghost icon
            Image(systemName: "figure.run")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(!isUserWinner ? .purple : .gray)
        }
        .overlay(
            // Winner crown
            crownOverlay(isWinner: !isUserWinner)
        )
    }
    
    // MARK: - Crown Overlay
    private func crownOverlay(isWinner: Bool) -> some View {
        Group {
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.yellow)
                    .offset(y: -22)
                    .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3), value: bounceAnimation)
            }
        }
    }
    
    // MARK: - Result Text View
    private var resultTextView: some View {
        VStack(spacing: 4) {
            Text(isUserWinner ? "You Won!" : "\(ghostName) Won!")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isUserWinner ? .green : .purple)
            
            Text("vs \(ghostName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Time Difference View
    private func timeDifferenceView(_ timeDifference: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isUserWinner ? "plus.circle.fill" : "minus.circle.fill")
                .font(.caption)
                .foregroundColor(isUserWinner ? .green : .red)
            
            Text(timeDifference)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUserWinner ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isUserWinner ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
    
    // MARK: - Confetti Overlay
    private var confettiOverlay: some View {
        Group {
            if showConfetti && isUserWinner {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimation() {
        // Initial fade in and scale
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animationScale = 1.0
            animationOpacity = 1.0
        }
        
        // Delayed trophy bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            bounceAnimation = true
        }
        
        // Show confetti for wins
        if isUserWinner {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
            
            // Hide confetti after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showConfetti = false
            }
        }
    }
}

// MARK: - Confetti View
private struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.yellow, .green, .blue, .purple, .red, .orange]
        
        for i in 0..<30 {
            let piece = ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .yellow,
                position: CGPoint(
                    x: CGFloat.random(in: 0...300),
                    y: CGFloat.random(in: -50...50)
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            confettiPieces.append(piece)
        }
        
        // Animate confetti falling
        withAnimation(.easeOut(duration: 2.0)) {
            for i in 0..<confettiPieces.count {
                confettiPieces[i].position.y += 400
                confettiPieces[i].opacity = 0.0
                confettiPieces[i].rotation += 360
            }
        }
    }
    
    private struct ConfettiPiece {
        let id: Int
        let color: Color
        var position: CGPoint
        var rotation: Double
        var opacity: Double
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        TrophyAnimation(
            didWin: true,
            isUserWinner: true,
            ghostName: "Sarah Chen",
            timeDifference: "2:30"
        )
        
        TrophyAnimation(
            didWin: false,
            isUserWinner: false,
            ghostName: "Elite Runner",
            timeDifference: "5:30"
        )
    }
    .padding()
}