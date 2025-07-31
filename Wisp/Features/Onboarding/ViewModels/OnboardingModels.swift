//
//  OnboardingModels.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation

struct OnboardingPage {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to AuthDemo",
            subtitle: "Secure Authentication Made Simple",
            imageName: "shield.checkered",
            description: "Experience seamless and secure authentication with our comprehensive solution powered by Supabase."
        ),
        OnboardingPage(
            title: "Multiple Sign-In Options",
            subtitle: "Choose Your Preferred Method",
            imageName: "person.2.circle",
            description: "Sign in with email and password, or use your Google account for quick and secure access."
        ),
        OnboardingPage(
            title: "Your Data, Protected",
            subtitle: "Enterprise-Grade Security",
            imageName: "lock.circle",
            description: "Your personal information is encrypted and protected with industry-leading security standards."
        )
    ]
}

enum AuthenticationFlow: String {
    case signUp = "signUp"
    case signIn = "signIn"
    case googleOAuth = "googleOAuth"
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
