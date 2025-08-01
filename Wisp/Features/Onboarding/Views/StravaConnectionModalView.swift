//
//  StravaConnectionModalView.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import SwiftUI
import Foundation

struct StravaConnectionModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var stravaManager = StravaOAuthManager.shared
    @State private var isConnecting = false
    
    private let logger = Logger.ui
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Strava Logo and Header
                VStack(spacing: 24) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange)
                        .background(
                            Circle()
                                .fill(.orange.opacity(0.1))
                                .frame(width: 120, height: 120)
                        )
                    
                    VStack(spacing: 12) {
                        Text("Connect with Strava")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sync your activities and compete with friends by connecting your Strava account")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(icon: "arrow.2.circlepath", title: "Sync Activities", description: "Import your past runs automatically")
                    BenefitRow(icon: "person.2", title: "Race Friends", description: "Compete against your Strava connections")
                    BenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Track Progress", description: "See your improvement over time")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    WispButton(
                        title: "Connect with Strava",
                        style: .primary,
                        icon: "link",
                        isLoading: isConnecting
                    ) {
                        connectToStrava()
                    }
                    
                    Button("Maybe Later") {
                        dismissModal()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // Settings Note
                Text("You can always connect later in Settings")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismissModal()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .onReceive(stravaManager.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                logger.info("Strava authentication successful, dismissing modal")
                dismiss()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func connectToStrava() {
        logger.info("User initiated Strava connection")
        isConnecting = true
        
        Task {
            do {
                try await stravaManager.startAuthorization()
                logger.info("Strava authorization started successfully")
            } catch {
                logger.error("Failed to start Strava authorization: \(error)")
                isConnecting = false
            }
        }
    }
    
    private func dismissModal() {
        logger.info("User dismissed Strava connection modal")
        UserDefaults.standard.markStravaConnectionModalSeen()
        dismiss()
    }
}

// MARK: - Benefit Row Component

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    StravaConnectionModalView()
}
