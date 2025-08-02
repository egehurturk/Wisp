//
//  AnimatedGradientBackgroundCard.swift
//  Wisp
//
//  Created by Ege Hurturk on 2.08.2025.
//
//
import SwiftUI

struct AnimatedBackgroundView: View {
    @State private var offsets: [CGSize] = Array(repeating: .zero, count: 3)
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if colorScheme == .dark {
                    // Original dark mode circles with screen blend mode
                    Circle()
                        .fill(Color.cyan.opacity(0.80))
                        .frame(width: geo.size.width * 0.85)
                        .offset(offsets[0])
                        .blendMode(.screen)
                    
                    Circle()
                        .fill(Color.yellow.opacity(0.80))
                        .frame(width: geo.size.width * 0.85)
                        .offset(offsets[1])
                        .blendMode(.screen)
                    
                    Circle()
                        .fill(Color.pink.opacity(0.80))
                        .frame(width: geo.size.width * 0.85)
                        .offset(offsets[2])
                        .blendMode(.screen)
                } else {
                    // Light mode optimized circles with subtle radial gradients
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.05)],
                                center: .center,
                                startRadius: 50,
                                endRadius: geo.size.width * 0.4
                            )
                        )
                        .frame(width: geo.size.width * 0.85)
                        .offset(offsets[0])
                        .blendMode(.multiply)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.05)],
                                center: .center,
                                startRadius: 50,
                                endRadius: geo.size.width * 0.4
                            )
                        )
                        .frame(width: geo.size.width * 0.85)
                        .offset(offsets[1])
                        .blendMode(.multiply)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.04)],
                                center: .center,
                                startRadius: 50,
                                endRadius: geo.size.width * 0.4
                            )
                        )
                        .frame(width: geo.size.width * 0.85)
                        .offset(offsets[2])
                        .blendMode(.multiply)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .task {
                for index in offsets.indices {
                    animateCircle(index: index, in: geo.size)
                }
            }
        }
    }
    
    private func animateCircle(index: Int, in size: CGSize) {
        let maxX = size.width  * 0.4
        let maxY = size.height * 0.4
        
        // Pick a random point on one of the four edges of the rectangle.
        func randomEdgePoint() -> CGSize {
            switch Int.random(in: 0..<4) {
            case 0: // top
                return CGSize(width: .random(in: -maxX...maxX), height: -maxY)
            case 1: // bottom
                return CGSize(width: .random(in: -maxX...maxX), height:  maxY)
            case 2: // left
                return CGSize(width: -maxX, height: .random(in: -maxY...maxY))
            default: // right
                return CGSize(width:  maxX, height: .random(in: -maxY...maxY))
            }
        }
        
        let destination = randomEdgePoint()
        
        // Use a constant speed so longer moves take longer.
        // Points per second
        let speed: CGFloat = 20
        
        // Current position of the circle.
        let current = offsets[index]
        
        // Euclidean distance to the destination.
        let distance = hypot(destination.width - current.width,
                             destination.height - current.height)
        
        // Time = distance / speed
        let travelTime = Double(distance / speed)
        
        // Animate to the selected edge
        withAnimation(.linear(duration: travelTime)) {
            offsets[index] = destination
        }
        
        // After reaching the edge, choose a new edge and repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + travelTime) {
            animateCircle(index: index, in: size)
        }
    }
}

struct AnimatedBGCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let content: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            AnimatedBackgroundView()
                .ignoresSafeArea()
            
            // Adaptive frosted glass background
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            colorScheme == .dark ?
                            Color.white.opacity(0.3) :
                            Color.black.opacity(0.1),
                            lineWidth: 2
                        )
                )
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(Font.system(.title).smallCaps())
                        .bold()
                        .foregroundColor(.primary) // Adaptive text color
                }
                
                Text(content)
                    .font(.callout.smallCaps())
                    .monospaced()
                    .foregroundColor(.secondary)
                
            } // End Card Content
            .padding()
            
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

// Preview with both light and dark mode
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedBGCardView(title: "Welcome!", content:"These changes create a much more gentle, barely-there background effect that won't compete with the card content while still providing that subtle animated movement and color variation. The gradients now fade out much more gradually and with lower overall intensity.")
                .frame(height: 300)
                .padding()
        }
    }
}
