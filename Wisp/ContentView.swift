//
//  ContentView.swift
//  Wisp
//
//  Created by Ege Hurturk on 24.07.2025.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var isInitialized = false
    private let logger = LoggerAuth.shared
    
    var body: some View {
        Group {
            if !isInitialized {
                LoadingView()
            } else if true { //supabaseManager.isAuthenticated {
                MainTabView()
                    .onAppear {
                        logger.info("Wisp app launched successfully & authenticated - returning user")
                    }
            } else {
                OnboardingView()
                    .onAppear {
                        logger.info("Wisp app launched successfully - new user, showing onboarding")
                    }
            }
        }
        .onAppear {
            Task {
                await waitForInitialization()
            }
        }
    }
    
    private func waitForInitialization() async {
        logger.info("ContentView: Waiting for authentication state initialization", category: .authentication)
        
        // Give SupabaseManager time to check the initial auth state
        // We'll check periodically if the auth state has been determined
        for attempt in 1...10 { // Max 5 seconds (10 * 0.5s)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if we have a definitive auth state (either authenticated or not)
            // The initialization is complete when we either have a session or confirmed no session
            if supabaseManager.isAuthenticated || supabaseManager.currentUser == nil {
                logger.info("ContentView: Authentication state determined after \(attempt * 500)ms", category: .authentication)
                break
            }
        }
        
        await MainActor.run {
            isInitialized = true
            logger.info("ContentView: Showing \(supabaseManager.isAuthenticated ? "HomeView" : "OnboardingView")", category: .authentication)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
