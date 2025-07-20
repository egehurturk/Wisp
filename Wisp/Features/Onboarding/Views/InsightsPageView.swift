import SwiftUI

struct InsightsPageView: View {
    @State private var chartProgress: CGFloat = 0.0
    @State private var fadeInAnimation = false
    @State private var dataPointAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Data Dashboard Visual
                VStack(spacing: 16) {
                    // Top metrics row
                    HStack(spacing: 12) {
                        metricCard(title: "Weekly Miles", value: "32.4", trend: "+12%", color: .green)
                        metricCard(title: "Avg Pace", value: "7:45", trend: "-8s", color: .blue)
                    }
                    
                    // Chart visualization
                    chartVisualization
                    
                    // Strava sync indicator
                    stravaConnection
                }
                .padding(.horizontal, 32)
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                
                Spacer()
                
                // Content
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Level Up with")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                        
                        Text("Data & Strava Sync")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(fadeInAnimation ? 1.0 : 0.0)
                    }
                    
                    Text("Sync with Strava and get detailed analytics on split adherence, pace deltas, and training trends to continuously improve your performance.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .opacity(fadeInAnimation ? 1.0 : 0.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Feature insights
                VStack(spacing: 12) {
                    insightRow(icon: "chart.line.uptrend.xyaxis", text: "Performance Trends", value: "↗️ Improving")
                    insightRow(icon: "target", text: "Split Adherence", value: "94% On Target")
                    insightRow(icon: "heart.fill", text: "Training Load", value: "Optimal Zone")
                }
                .opacity(fadeInAnimation ? 1.0 : 0.0)
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                fadeInAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startDataAnimation()
            }
        }
    }
    
    private func metricCard(title: String, value: String, trend: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Image(systemName: trend.hasPrefix("+") || trend.hasPrefix("↗") ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                    .foregroundColor(color)
                
                Text(trend)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var chartVisualization: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        let height: CGFloat = [0.4, 0.6, 0.8, 0.5, 0.9, 0.7, 0.3][index]
                        
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: (chartProgress > CGFloat(index) / 7) ? height * geo.size.height : 0)
                                .cornerRadius(3)
                                .scaleEffect(dataPointAnimation && chartProgress > CGFloat(index) / 7 ? 1.05 : 1.0)
                            
                            Text(["S", "M", "T", "W", "T", "F", "S"][index])
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var stravaConnection: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Connected to Strava")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Auto-sync your runs and compete with friends")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func insightRow(icon: String, text: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private func startDataAnimation() {
        withAnimation(.easeInOut(duration: 2.0)) {
            chartProgress = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(1.0)) {
            dataPointAnimation = true
        }
    }
}

#Preview {
    InsightsPageView()
        .background(Color.black)
}