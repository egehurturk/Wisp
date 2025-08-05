//
//  WispApp.swift
//  Wisp
//
//  Created by Ege Hurturk on 14.07.2025.
//

import SwiftUI

@main
struct WispApp: App {
    
    var body: some Scene {
        WindowGroup {
           ContentView()
                .onOpenURL { url in
                    // Use multiple log methods to ensure we see this
                    LoggerAuth.shared.info("🔗 RECEIVED URL CALLBACK: \(url.absoluteString)", category: .authentication)
                    
                    // Log URL components for debugging
                    LoggerAuth.shared.info("URL Scheme: \(url.scheme ?? "nil"), Host: \(url.host ?? "nil"), Path: \(url.path)", category: .authentication)
                    
                    // Validate URL scheme
                    guard url.scheme == "supabaselogindemo" else {
                        LoggerAuth.shared.warning("Invalid URL scheme received: \(url.scheme ?? "nil")", category: .security)
                        return
                    }
                    
                    // Handle OAuth callbacks
                    if url.host == "auth-callback" || url.path.contains("auth-callback") {
                        LoggerAuth.shared.info("🔗 Handling Supabase OAuth callback", category: .authentication)
                        Task {
                            await SupabaseManager.shared.handleOAuthCallback(url: url)
                        }
                    } else if url.host == "strava-callback" || url.path.contains("strava-callback") {
                        LoggerAuth.shared.info("🔗 Handling Strava OAuth callback", category: .authentication)
                        // TODO: remove these (not required with backend)
                        Task {
                            await StravaOAuthManager.shared.handleOAuthCallback(url: url)
                        }
                    } else {
                        LoggerAuth.shared.warning("Unhandled URL callback: \(url.absoluteString)", category: .security)
                    }
                }
        }
    }
}
