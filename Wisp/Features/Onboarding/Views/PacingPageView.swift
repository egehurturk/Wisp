import SwiftUI

struct PacingPageView: View {
    @State private var fadeInAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Professional DotLottie Chart Animation
                DotLottieView(
                    url: "https://lottie.host/4dde0176-66b9-4f1c-be61-7432a2823f72/rUM5aozCwI.lottie",
                    animationSpeed: 0.8,
                    looping: true
                )
                .frame(width: 300, height: 200)
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .scaleEffect(fadeInAnimation ? 1.0 : 0.8)
                
                Spacer()
                
                // Content
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Stay On Pace,")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                        
                        Text("Effortlessly")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                    }
                    
                    Text("AI-powered pacing strategies that adapt to terrain, your fitness level, and goal time. Never burn out early or finish with energy left.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .opacity(fadeInAnimation ? 1.0 : 0.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Feature highlights
                VStack(spacing: 16) {
                    featureRow(icon: "brain.head.profile", text: "AI Terrain Analysis", color: .blue)
                    featureRow(icon: "speedometer", text: "Dynamic Pace Adjustments", color: .green)
                    featureRow(icon: "target", text: "Goal-Optimized Strategy", color: .orange)
                }
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                fadeInAnimation = true
            }
        }
    }
    
    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
}

#Preview {
    PacingPageView()
        .background(Color.black)
}