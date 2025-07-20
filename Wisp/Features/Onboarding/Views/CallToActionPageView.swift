import SwiftUI

struct CallToActionPageView: View {
    @State private var pulseAnimation = false
    @State private var fadeInAnimation = false
    @State private var currentRoleIndex = 0
    
    let onGetStarted: () -> Void
    let onLogIn: () -> Void
    let onLearnMore: () -> Void
    
    private let roles = ["Running Coach", "Training Partner", "Pace Guide", "Goal Crusher", "Fitness Companion"]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // App logo section
                VStack(spacing: 24) {
                    // Main app logo
                    VStack(spacing: 16) {
                        Image("AppIconWithBG")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                            .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 8)
                        
                        Text("WISP")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .tracking(4)
                    }
                    .opacity(fadeInAnimation ? 1.0 : 0.0)
                    .scaleEffect(fadeInAnimation ? 1.0 : 0.8)
                    
                    // Motivational tagline
                    VStack(spacing: 8) {
                        Text("Your Personal")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(roles[currentRoleIndex])
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .animation(.easeInOut(duration: 0.5), value: currentRoleIndex)
                    }
                    .opacity(fadeInAnimation ? 1.0 : 0.0)
                    .offset(y: fadeInAnimation ? 0 : 20)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary CTA - Get Started
                    Button(action: onGetStarted) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                        .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    // Secondary CTA - Log In
                    Button(action: onLogIn) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Log In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                        )
                    }
                    
                    // Tertiary option - Learn More
                    Button(action: onLearnMore) {
                        HStack(spacing: 8) {
                            Text("Learn More About Wisp")
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .offset(y: fadeInAnimation ? 0 : 30)
                
                Spacer()
                
                // Footer motivation
                VStack(spacing: 8) {
                    Text("Join thousands of runners")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("crushing their goals with Wisp")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                fadeInAnimation = true
            }
            
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.8)) {
                pulseAnimation = true
            }
            
            // Start role rotation after initial animations
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentRoleIndex = (currentRoleIndex + 1) % roles.count
                }
            }
        }
    }
}

#Preview {
    CallToActionPageView(
        onGetStarted: {},
        onLogIn: {},
        onLearnMore: {}
    )
    .background(Color.black)
}
