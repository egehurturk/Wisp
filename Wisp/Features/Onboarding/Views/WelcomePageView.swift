import SwiftUI

struct WelcomePageView: View {
    @State private var fadeInAnimation = false
    
    let onGetStarted: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Professional DotLottie Runner Animation
                DotLottieView(
                    url: "https://lottie.host/827c83d4-950c-4f3c-a957-777de5468290/PnPEgfGOxq.lottie",
                    animationSpeed: 1.2,
                    looping: true
                )
                .frame(width: 280, height: 280)
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .scaleEffect(fadeInAnimation ? 1.0 : 0.8)
                
                Spacer()
                
                // Title and Subtitle
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Run Smarter,")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                            .offset(y: fadeInAnimation ? 0 : 20)
                        
                        Text("Race Harder")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                            .offset(y: fadeInAnimation ? 0 : 20)
                    }
                    
                    Text("Improve your pacing and crush your PRs with AI-guided strategy and ghost racing against your best times.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .opacity(fadeInAnimation ? 1.0 : 0.0)
                        .offset(y: fadeInAnimation ? 0 : 20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Wisp Logo/Brand
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("WISP")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .offset(y: fadeInAnimation ? 0 : 20)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                fadeInAnimation = true
            }
        }
    }
}

#Preview {
    WelcomePageView(onGetStarted: {})
        .background(Color.black)
}