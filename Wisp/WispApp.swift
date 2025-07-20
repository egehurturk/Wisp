//
//  WispApp.swift
//  Wisp
//
//  Created by Ege Hurturk on 14.07.2025.
//

import SwiftUI

@main
struct WispApp: App {
    private let logger = Logger.general
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            if false {
                MainTabView()
                    .onAppear {
                        logger.info("Wisp app launched successfully - returning user")
                    }
            } else {
                OnboardingView()
                    .onAppear {
                        logger.info("Wisp app launched successfully - new user, showing onboarding")
                    }
                    .onChange(of: UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")) { completed in
                        hasCompletedOnboarding = completed
                    }
            }
        }
    }
}
