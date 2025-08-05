//
//  StravaService.swift
//  Wisp
//
//  Created by Ege Hurturk on 24.07.2025.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Security
import CryptoKit

@MainActor
class StravaOAuthManager: NSObject, ObservableObject {
    static let shared = StravaOAuthManager()
    
    @Published var isAuthenticated = false
    @Published var activities: [StravaActivity] = []
    @Published var isLoading = false
    @Published var lastError: StravaError?
    
    // Authenticated athlete information
    @Published var athleteId: Int?
    @Published var athleteUsername: String?
    @Published var athleteFirstName: String?
    @Published var athleteLastName: String?
    
    // Computed property for display name
    var athleteDisplayName: String {
        let fullName = [athleteFirstName, athleteLastName].compactMap { $0 }.joined(separator: " ")
        if !fullName.isEmpty {
            return fullName
        } else if let username = athleteUsername {
            return username
        } else if let id = athleteId {
            return "Athlete \(id)"
        } else {
            return "Unknown Athlete"
        }
    }
    
    private let logger = Logger.general
    private let keychainService = "com.wisp.strava"
    private let backendService = BackendStravaService()
    
    // OAuth session state
    private var authSession: ASWebAuthenticationSession?
    private var currentCodeVerifier: String?
    private var currentState: String?
    
    private override init() {
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    private func checkAuthenticationStatus() {
        Task {
            await validateAndRefreshAuthenticationIfNeeded()
        }
    }
    
    private func validateAndRefreshAuthenticationIfNeeded() async {
        logger.info("🔍 Checking Strava authentication status via backend")
        
        // Check with backend service for current connection status
        do {
            let status = try await backendService.getStravaConnectionStatus()
            
            if status.connected {
                logger.info("✅ Backend reports Strava connection is active")
                
                await MainActor.run {
                    // Update local state with backend status
                    self.athleteId = status.athleteId
                    self.athleteUsername = nil
                    self.athleteFirstName = status.athleteName
                    self.athleteLastName = nil
                    
                    // Store athlete info locally for consistency
                    if let athleteId = status.athleteId {
                        self.storeAthleteInfo(
                            id: athleteId,
                            username: nil,
                            firstName: status.athleteName,
                            lastName: nil
                        )
                    }
                    
                    self.isAuthenticated = true
                    let athleteInfo = status.athleteName ?? "ID: \(status.athleteId ?? 0)"
                    self.logger.info("✅ User authenticated via backend: \(athleteInfo)")
                }
                return
                
            } else {
                logger.info("❌ Backend reports no active Strava connection")
                await MainActor.run {
                    self.isAuthenticated = false
                }
                return
            }
            
        } catch BackendStravaError.connectionNotFound {
            logger.info("❌ No Strava connection found on backend")
            await MainActor.run {
                self.isAuthenticated = false
            }
            return
            
        } catch BackendStravaError.unauthorized {
            logger.warning("❌ Backend authentication failed - user needs to login")
            await MainActor.run {
                self.isAuthenticated = false
            }
            return
            
        } catch {
            logger.warning("⚠️ Backend connection check failed, falling back to local validation: \(error.localizedDescription)")
        }
        
        // Fallback to local token validation for offline scenarios
        await validateLocalTokensFallback()
    }
    
    private func validateLocalTokensFallback() async {
        logger.info("🔄 Falling back to local token validation")
        
        // Check if we have athlete info stored locally
        guard let athleteId = getSecureToken(key: StravaKeychainKeys.athleteId).flatMap({ Int($0) }),
              athleteId > 0 else {
            logger.info("❌ No local athlete info found")
            await MainActor.run {
                self.isAuthenticated = false
            }
            return
        }
        
        await MainActor.run {
            self.loadAthleteInfo()
            self.isAuthenticated = true
            let athleteInfo = self.athleteFirstName.map { "\($0) (ID: \(athleteId))" } ?? "ID: \(athleteId)"
            self.logger.info("✅ Using cached authentication: \(athleteInfo)")
        }
    }
    
    private func hasValidTokens() -> Bool {
        guard let accessToken = getSecureToken(key: StravaKeychainKeys.accessToken),
              !accessToken.isEmpty else {
            return false
        }
        
        // Check if token is expired
        if let expirationDate = getTokenExpiration() {
            return expirationDate > Date()
        }
        
        // If no expiration date, assume we have a token but can't verify validity
        // The actual refresh will be handled by validateAndRefreshAuthenticationIfNeeded
        return true
    }
    
    // MARK: - Secure OAuth Flow
    
    func startAuthorization() {
        logger.info("Starting Strava OAuth authorization through backend")
        
        isLoading = true
        lastError = nil
        
        Task {
            do {
                // Step 1: Initiate OAuth with backend
                let initiateResponse = try await backendService.initiateStravaOAuth()
                logger.info("Backend OAuth initiated - state: \(initiateResponse.state)")
                
                // Step 2: Open OAuth URL
                guard let authURL = URL(string: initiateResponse.authUrl) else {
                    throw StravaError.invalidURL
                }
                
                await MainActor.run {
                    self.openOAuthURL(authURL)
                }
                
                // Step 3: Poll for connection status
                let connectionStatus = try await backendService.pollForConnection()
                
                // Step 4: Update UI with success
                await MainActor.run {
                    self.handleBackendAuthSuccess(connectionStatus)
                }
                
            } catch {
                logger.error("Backend OAuth failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    if let backendError = error as? BackendStravaError {
                        self.lastError = .authorizationFailed(backendError.localizedDescription)
                    } else {
                        self.lastError = .networkError(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // MARK: - Backend OAuth Helpers
    
    private func openOAuthURL(_ url: URL) {
        logger.info("Opening OAuth URL: \(url.absoluteString)")
        
        // Try to open in Strava app first if available
        if url.scheme == "strava" && UIApplication.shared.canOpenURL(url) {
            logger.info("Opening in Strava app")
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    self.logger.warning("Failed to open Strava app, trying Safari")
                    // Fallback to Safari
                    UIApplication.shared.open(url, options: [:])
                }
            }
        } else {
            // Open in Safari
            logger.info("Opening in Safari")
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    private func handleBackendAuthSuccess(_ status: StravaConnectionStatus) {
        logger.info("✅ Backend OAuth successful")
        
        // Update local state with backend response
        self.athleteId = status.athleteId
        self.athleteUsername = nil // Backend doesn't return username yet
        self.athleteFirstName = status.athleteName // Using name as first name for now
        self.athleteLastName = nil
        
        // Store athlete info locally for consistency with existing keychain logic
        if let athleteId = status.athleteId {
            storeAthleteInfo(
                id: athleteId, 
                username: nil,
                firstName: status.athleteName,
                lastName: nil
            )
        }
        
        self.isAuthenticated = true
        self.isLoading = false
        self.lastError = nil
        
        logger.info("Strava authentication complete - athlete: \(status.athleteName ?? "Unknown") (ID: \(status.athleteId ?? 0))")
    }
    
    // MARK: - Callback Handling
    
    func handleOAuthCallback(url: URL) async {
        logger.info("⚠️ OAuth callback received - this is no longer used with backend integration")
        
        // With backend integration, we don't need to handle callbacks directly
        // The backend handles the callback and we poll for status instead
        // This method is kept for compatibility but doesn't process the callback
        
        logger.info("OAuth callback ignored - backend handles token exchange automatically")
    }
    
    // MARK: - Connection Management
    
    func disconnectStrava() async {
        logger.info("🔌 Disconnecting Strava account")
        
        isLoading = true
        
        do {
            try await backendService.disconnectStrava()
            
            await MainActor.run {
                self.signOut()
                self.isLoading = false
            }
            
            logger.info("✅ Successfully disconnected from Strava")
            
        } catch {
            logger.error("❌ Failed to disconnect from Strava backend: \(error.localizedDescription)")
            
            await MainActor.run {
                self.isLoading = false
                if let backendError = error as? BackendStravaError {
                    self.lastError = .networkError(backendError.localizedDescription)
                } else {
                    self.lastError = .networkError(error.localizedDescription)
                }
                
                // Still sign out locally even if backend call failed
                self.signOut()
            }
        }
    }
    
    
    // MARK: - Sign Out
    
    func signOut() {
        logger.info("Signing out from Strava")
        
        // Clear tokens from Keychain
        clearSecureToken(key: StravaKeychainKeys.accessToken)
        clearSecureToken(key: StravaKeychainKeys.refreshToken)
        clearTokenExpiration()
        clearAthleteInfo()
        
        // Reset state
        isAuthenticated = false
        activities = []
        lastError = nil
        
        logger.info("Strava sign out completed")
    }
}

// MARK: - Keychain Management

extension StravaOAuthManager {
    
    private enum StravaKeychainKeys {
        static let accessToken = "strava_access_token"
        static let refreshToken = "strava_refresh_token"
        static let tokenExpiration = "strava_token_expiration"
        static let athleteId = "strava_athlete_id"
        static let athleteUsername = "strava_athlete_username"
        static let athleteFirstName = "strava_athlete_first_name"
        static let athleteLastName = "strava_athlete_last_name"
    }
    
    private func storeSecureToken(token: String, key: String) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary) // Remove existing
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            logger.info("Securely stored token in Keychain: \(key)" )
        } else {
            logger.error("Failed to store token in Keychain: \(status)" )
        }
    }
    
    private func getSecureToken(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func clearSecureToken(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func storeTokenExpiration(date: Date) {
        let data = String(date.timeIntervalSince1970).data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: StravaKeychainKeys.tokenExpiration,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getTokenExpiration() -> Date? {
        guard let expirationString = getSecureToken(key: StravaKeychainKeys.tokenExpiration),
              let timestamp = TimeInterval(expirationString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func clearTokenExpiration() {
        clearSecureToken(key: StravaKeychainKeys.tokenExpiration)
    }
    
    // MARK: - Athlete Data Management
    
    private func storeAthleteInfo(id: Int, username: String?, firstName: String?, lastName: String?) {
        // Store athlete ID
        storeSecureToken(token: String(id), key: StravaKeychainKeys.athleteId)
        
        // Store optional athlete data
        if let username = username {
            storeSecureToken(token: username, key: StravaKeychainKeys.athleteUsername)
        }
        if let firstName = firstName {
            storeSecureToken(token: firstName, key: StravaKeychainKeys.athleteFirstName)
        }
        if let lastName = lastName {
            storeSecureToken(token: lastName, key: StravaKeychainKeys.athleteLastName)
        }
        
        logger.info("Stored athlete info for ID: \(id)" )
    }
    
    private func loadAthleteInfo() {
        athleteId = getSecureToken(key: StravaKeychainKeys.athleteId).flatMap { Int($0) }
        athleteUsername = getSecureToken(key: StravaKeychainKeys.athleteUsername)
        athleteFirstName = getSecureToken(key: StravaKeychainKeys.athleteFirstName)
        athleteLastName = getSecureToken(key: StravaKeychainKeys.athleteLastName)
    }
    
    private func clearAthleteInfo() {
        clearSecureToken(key: StravaKeychainKeys.athleteId)
        clearSecureToken(key: StravaKeychainKeys.athleteUsername)
        clearSecureToken(key: StravaKeychainKeys.athleteFirstName)
        clearSecureToken(key: StravaKeychainKeys.athleteLastName)
        
        athleteId = nil
        athleteUsername = nil
        athleteFirstName = nil
        athleteLastName = nil
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension StravaOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Error Types

enum StravaError: LocalizedError {
    case authorizationFailed(String)
    case invalidCallback(String)
    case securityError(String)
    case networkError(String)
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let message):
            return "Authorization failed: \(message)"
        case .invalidCallback(let message):
            return "Invalid callback: \(message)"
        case .securityError(let message):
            return "Security error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let message):
            return "Data parsing error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authorizationFailed, .invalidCallback:
            return "Please try signing in again."
        case .securityError:
            return "Please restart the authorization process."
        case .networkError:
            return "Check your internet connection and try again."
        case .unauthorized:
            return "Please sign in to Strava again."
        case .httpError, .invalidResponse, .decodingError:
            return "Please try again later."
        case .invalidURL:
            return "Contact support if this persists."
        }
    }
}

// MARK: - Data Extensions

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
