import SwiftUI

struct GhostsPageView: View {
    @State private var fadeInAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Professional DotLottie Ghost Racing Animation
                DotLottieView(
                    url: "https://lottie.host/14fc05dd-a9a4-41d1-ac0b-4708a2761669/2ivTsywdXP.lottie",
                    animationSpeed: 1.0,
                    looping: true
                )
                .frame(width: 320, height: 240)
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .scaleEffect(fadeInAnimation ? 1.0 : 0.8)
                
                Spacer()
                
                // Content
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Race Your")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                        
                        Text("Inner Champion")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                    }
                    
                    Text("Compete live against your personal records, custom training goals, or friends from Strava. Ghost pacing keeps you motivated and on track.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .opacity(fadeInAnimation ? 1.0 : 0.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Feature badges
                HStack(spacing: 16) {
                    featureBadge(icon: "trophy.fill", text: "PR Ghosts", color: .yellow)
                    featureBadge(icon: "target", text: "Custom Goals", color: .blue)
                    featureBadge(icon: "person.2.fill", text: "Friend Races", color: .green)
                }
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                fadeInAnimation = true
            }
        }
    }
    
    private func featureBadge(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    GhostsPageView()
        .background(Color.black)
}