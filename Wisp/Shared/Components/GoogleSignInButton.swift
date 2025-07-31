//
//  GoogleSignInButton.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation
import SwiftUI

struct GoogleSignInButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    init(title: String = "Continue with Google", isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.8)
                } else {
                    // Google "G" logo recreation using SF Symbols and styling
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                        
                        Text("G")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .red, .yellow, .green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text(title)
                        .fontWeight(.medium)
                        .font(.system(.body, design: .rounded))
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        GoogleSignInButton(title: "Sign up with Google") {
            // Preview action
        }
        
        GoogleSignInButton(title: "Sign in with Google") {
            // Preview action
        }
        
        GoogleSignInButton(title: "Continue with Google", isLoading: true) {
            // Preview action
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
