//
//  UserDefaults+Strava.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation

extension UserDefaults {
    
    // MARK: - Strava Connection Tracking
    
    /// Whether the user has seen the Strava connection modal
    var hasSeenStravaConnectionModal: Bool {
        get { bool(forKey: "hasSeenStravaConnectionModal") }
        set { set(newValue, forKey: "hasSeenStravaConnectionModal") }
    }
    
    /// Whether the user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: "hasCompletedOnboarding") }
        set { set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    /// Whether this is the user's first app launch after account creation
    var isFirstLaunchAfterAccountCreation: Bool {
        get { bool(forKey: "isFirstLaunchAfterAccountCreation") }
        set { set(newValue, forKey: "isFirstLaunchAfterAccountCreation") }
    }
    
    // MARK: - Helper Methods
    
    /// Marks that the user has created an account and this is their first launch
    func markFirstLaunchAfterAccountCreation() {
        isFirstLaunchAfterAccountCreation = true
        hasSeenStravaConnectionModal = false
    }
    
    /// Marks that the user has seen the Strava connection modal
    func markStravaConnectionModalSeen() {
        hasSeenStravaConnectionModal = true
    }
    
    /// Checks if the Strava connection modal should be shown
    func shouldShowStravaConnectionModal() -> Bool {
        return isFirstLaunchAfterAccountCreation && !hasSeenStravaConnectionModal
    }
    
    /// Resets all Strava-related preferences (useful for testing)
    func resetStravaPreferences() {
        hasSeenStravaConnectionModal = false
        isFirstLaunchAfterAccountCreation = false
    }
}