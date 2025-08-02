//
//  GradientBackground.swift
//  Wisp
//
//  Created by Ege Hurturk on 20.07.2025.
//

import SwiftUI

struct GradientBackground: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if colorScheme == .dark {
                DarkGradientBackground()
            } else {
                LightGradientBackground()
            }
        }
    }
    
}

private struct DarkGradientBackground: View {
    private let blackColors: [Color] = [
        Color(red: 44/255, green: 27/255, blue: 23/255),
        Color(red: 11/255, green: 12/255, blue: 15/255)
    ]

    private let center: UnitPoint = .bottom
    private let startRadius: CGFloat = 20
    private let endRadius: CGFloat = 300
    private let cornerRadius: CGFloat = 20

    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: blackColors),
            center: center,
            startRadius: startRadius,
            endRadius: endRadius
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}


private struct LightGradientBackground: View {
    private let lightColors: [Color] = [
        Color.pink.opacity(0.2),
        Color.white
    ]

    private let center: UnitPoint = .bottom
    private let startRadius: CGFloat = 20
    private let endRadius: CGFloat = 300
    private let cornerRadius: CGFloat = 20

    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: lightColors),
            center: center,
            startRadius: startRadius,
            endRadius: endRadius
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    GradientBackground()
        .ignoresSafeArea()
}
