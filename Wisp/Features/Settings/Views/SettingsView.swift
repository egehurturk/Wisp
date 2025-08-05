//
//  SettingsView.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import SwiftUI
import Foundation

/// Settings screen view for app configuration
struct SettingsView: View {
    
    // MARK: - Properties
    @StateObject private var stravaManager = StravaOAuthManager.shared
    @State private var isConnectingToStrava = false
    @State private var isDisconnectingStrava = false
    @State private var showingStravaDisconnectAlert = false
    private let logger = Logger.ui
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                profileSection
                
                // Integrations Section
                integrationsSection
                
                // App Settings Section
                appSettingsSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Disconnect Strava", isPresented: $showingStravaDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                Task {
                    await disconnectStrava()
                }
            }
        } message: {
            Text("Are you sure you want to disconnect your Strava account? This will remove access to your Strava activities and friends.")
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("John Runner")
                        .font(.headline)
                    
                    Text("john.runner@example.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Integrations Section
    
    private var integrationsSection: some View {
        Section("Integrations") {
            // Strava Integration Row
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strava")
                        .font(.body)
                    
                    Text(stravaConnectionStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if stravaManager.isAuthenticated {
                    WispButton(
                        title: "Disconnect",
                        style: .destructive,
                        isLoading: isDisconnectingStrava
                    ) {
                        showingStravaDisconnectAlert = true
                    }
                } else {
                    WispButton(
                        title: "Connect",
                        style: .secondary,
                        isLoading: isConnectingToStrava
                    ) {
                        connectToStrava()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        Section("App Settings") {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    
                    Text("Notifications")
                }
            }
            
            NavigationLink(destination: PrivacySettingsView()) {
                HStack {
                    Image(systemName: "hand.raised")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .frame(width: 24)
                    
                    Text("Privacy")
                }
            }
            
            NavigationLink(destination: DataSettingsView()) {
                HStack {
                    Image(systemName: "internaldrive")
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .frame(width: 24)
                    
                    Text("Data & Storage")
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version")
                        .font(.body)
                    
                    Text("1.0.0 (1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            NavigationLink(destination: SupportView()) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    
                    Text("Help & Support")
                }
            }
            
            NavigationLink(destination: LegalView()) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .frame(width: 24)
                    
                    Text("Legal")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var stravaConnectionStatusText: String {
        if stravaManager.isAuthenticated {
            return "Connected"
        } else {
            return "Not connected"
        }
    }
    
    // MARK: - Private Methods
    
    private func connectToStrava() {
        isConnectingToStrava = true
        
        Task {
            do {
                try await stravaManager.startAuthorization()
            } catch {
                logger.error("Failed to start Strava authorization from Settings: \(error)")
                isConnectingToStrava = false
            }
        }
    }
    
    private func disconnectStrava() async {
        isDisconnectingStrava = true
        
        do {
            try await stravaManager.disconnectStrava()
            logger.info("Successfully disconnected Strava from Settings")
        } catch {
            logger.error("Failed to disconnect Strava from Settings: \(error)")
        }
        
        isDisconnectingStrava = false
        isConnectingToStrava = false
    }
}

// MARK: - Placeholder Views

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataSettingsView: View {
    var body: some View {
        Text("Data & Storage Settings")
            .navigationTitle("Data & Storage")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegalView: View {
    var body: some View {
        Text("Legal Information")
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
