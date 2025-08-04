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
        logger.info("🔍 Checking Strava authentication status on app launch" )
        
        // Check if we have any tokens at all
        guard let accessToken = getSecureToken(key: StravaKeychainKeys.accessToken),
              !accessToken.isEmpty else {
            logger.info("❌ No Strava access token found - user needs to authenticate" )
            await MainActor.run {
                self.isAuthenticated = false
            }
            return
        }
        
        // Check if we have athlete info
        guard let athleteId = getSecureToken(key: StravaKeychainKeys.athleteId).flatMap({ Int($0) }),
              athleteId > 0 else {
            logger.warning("❌ Strava token exists but no athlete info - clearing tokens" )
            await MainActor.run {
                self.signOut()
            }
            return
        }
        
        // Check token expiration
        if let expirationDate = getTokenExpiration() {
            if expirationDate <= Date() {
                logger.info("⏰ Strava access token has expired, attempting automatic refresh" )
                
                // Attempt to refresh the token
                let refreshSuccessful = await refreshAccessToken()
                
                if refreshSuccessful {
                    logger.info("✅ Strava token refreshed successfully - maintaining authentication" )
                    await MainActor.run {
                        self.loadAthleteInfo()
                        self.isAuthenticated = true
                        let athleteInfo = self.athleteFirstName.map { "\($0) (ID: \(self.athleteId ?? 0))" } ?? "ID: \(self.athleteId ?? 0)"
                        self.logger.info("✅ Strava auth status: authenticated as \(athleteInfo)" )
                    }
                } else {
                    logger.warning("❌ Failed to refresh Strava token - user needs to re-authenticate" )
                    await MainActor.run {
                        self.signOut() // Clear invalid tokens
                    }
                }
            } else {
                // Token is still valid
                let timeUntilExpiry = expirationDate.timeIntervalSinceNow
                logger.info("✅ Strava access token is valid (expires in \(Int(timeUntilExpiry/60)) minutes)" )
                await MainActor.run {
                    self.loadAthleteInfo()
                    self.isAuthenticated = true
                    let athleteInfo = self.athleteFirstName.map { "\($0) (ID: \(self.athleteId ?? 0))" } ?? "ID: \(self.athleteId ?? 0)"
                    self.logger.info("✅ Strava auth status: authenticated as \(athleteInfo)" )
                }
            }
        } else {
            // No expiration date stored - assume token might be expired and try to refresh
            logger.warning("⚠️ No expiration date found for Strava token, attempting refresh as precaution" )
            
            let refreshSuccessful = await refreshAccessToken()
            
            if refreshSuccessful {
                logger.info("✅ Strava token refresh successful" )
                await MainActor.run {
                    self.loadAthleteInfo()
                    self.isAuthenticated = true
                    let athleteInfo = self.athleteFirstName.map { "\($0) (ID: \(self.athleteId ?? 0))" } ?? "ID: \(self.athleteId ?? 0)"
                    self.logger.info("✅ Strava auth status: authenticated as \(athleteInfo)" )
                }
            } else {
                logger.warning("❌ Failed to refresh Strava token without expiration date - user needs to re-authenticate" )
                await MainActor.run {
                    self.signOut()
                }
            }
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
        logger.info("Starting Strava OAuth authorization")
        
        // Generate PKCE parameters
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = generateState()
        
        // Store for validation
        self.currentCodeVerifier = codeVerifier
        self.currentState = state
        
        // Try Strava app first (recommended by Strava)
        let appAuthURL = buildAppAuthorizationURL(
            codeChallenge: codeChallenge,
            state: state
        )
        
        // Check if Strava app is installed
        if UIApplication.shared.canOpenURL(appAuthURL) {
            logger.info("Opening Strava app for authentication" )
            UIApplication.shared.open(appAuthURL, options: [:]) { success in
                if !success {
                    Task { @MainActor in
                        self.fallbackToWebAuth(codeChallenge: codeChallenge, state: state)
                    }
                }
            }
        } else {
            // Fallback to web authentication
            fallbackToWebAuth(codeChallenge: codeChallenge, state: state)
        }
    }
    
    private func fallbackToWebAuth(codeChallenge: String, state: String) {
        logger.info("Using web authentication session" )
        
        let webAuthURL = buildWebAuthorizationURL(
            codeChallenge: codeChallenge,
            state: state
        )
        
        logger.info("Using web URL: \(webAuthURL)")
        logger.info("Using callback scheme: \(Configuration.URLSchemes.main)")
        
        authSession = ASWebAuthenticationSession(
            url: webAuthURL,
            callbackURLScheme: Configuration.URLSchemes.main
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                await self?.handleAuthCallback(url: callbackURL, error: error)
            }
        }
        
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }
    
    // MARK: - URL Building
    
    private func buildAppAuthorizationURL(codeChallenge: String, state: String) -> URL {
        logger.info("App redirect uri: \(Configuration.StravaConstants.redirectURI)")
        var components = URLComponents(string: Configuration.StravaConstants.appAuthorizationScheme)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Configuration.StravaConstants.clientID),
            URLQueryItem(name: "redirect_uri", value: Configuration.StravaConstants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: Configuration.StravaConstants.scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: Configuration.StravaConstants.PKCE.codeChallengeMethod)
        ]
        return components.url!
    }
    
    private func buildWebAuthorizationURL(codeChallenge: String, state: String) -> URL {
        logger.info("App redirect uri: \(Configuration.StravaConstants.redirectURI)")
        var components = URLComponents(string: Configuration.StravaConstants.mobileAuthorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Configuration.StravaConstants.clientID),
            URLQueryItem(name: "redirect_uri", value: Configuration.StravaConstants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: Configuration.StravaConstants.scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: Configuration.StravaConstants.PKCE.codeChallengeMethod)
        ]
        return components.url!
    }
    
    // MARK: - Callback Handling
    
    func handleOAuthCallback(url: URL) async {
        await handleAuthCallback(url: url, error: nil)
    }
    
    private func handleAuthCallback(url: URL?, error: Error?) async {
        defer {
            // Clean up session state
            currentCodeVerifier = nil
            currentState = nil
            authSession = nil
        }
        
        if let error = error {
            logger.info("OAuth callback error")
            if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                logger.info("User cancelled OAuth authorization" )
            }
            return
        }
        
        guard let url = url else {
            logger.error("OAuth callback received nil URL" )
            lastError = .authorizationFailed("No callback URL received")
            return
        }
        
        logger.info("Processing OAuth callback: \(url.absoluteString)" )
        
        // Validate callback URL
        print("URL: \(url.absoluteString)")
        guard url.scheme == Configuration.URLSchemes.main else {
            logger.error("Invalid callback URL scheme: \(url.scheme ?? "nil")" )
            lastError = .invalidCallback("Invalid URL scheme")
            return
        }
        
        // Parse callback parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            logger.error("Failed to parse callback URL components" )
            lastError = .invalidCallback("Failed to parse callback URL")
            return
        }
        
        // Check for errors in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            logger.error("OAuth callback contained error: \(error)" )
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value
            lastError = .authorizationFailed(errorDescription ?? error)
            return
        }
        
        // Validate state parameter (CSRF protection)
        guard let receivedState = queryItems.first(where: { $0.name == "state" })?.value,
              receivedState == currentState else {
            logger.error("State parameter mismatch - possible CSRF attack" )
            lastError = .securityError("State parameter mismatch")
            return
        }
        
        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            logger.error("No authorization code in callback" )
            lastError = .authorizationFailed("No authorization code received")
            return
        }
        
        // Extract granted scope
        let grantedScope = queryItems.first(where: { $0.name == "scope" })?.value
        logger.info("OAuth authorization successful, granted scope: \(grantedScope ?? "none")" )
        
        // Note: In a secure implementation, you would send the code to your backend
        // The backend would exchange it for tokens using the client secret
        // For demo purposes, we'll show what the backend call would look like
        await notifyBackendOfAuthorizationCode(code: code, codeVerifier: currentCodeVerifier!)
    }
    
    // MARK: - Token Exchange (Development Implementation)
    
    private func notifyBackendOfAuthorizationCode(code: String, codeVerifier: String) async {
        logger.warning("🚨 DEVELOPMENT ONLY: Direct token exchange in mobile app" )
        logger.warning("⚠️ In production, this should be handled by a secure backend service" )
        
        await exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)
    }
    
    private func exchangeCodeForTokens(code: String, codeVerifier: String) async {
        logger.info("Exchanging authorization code for access tokens" )
        
        guard let url = URL(string: Configuration.StravaConstants.tokenEndpoint) else {
            logger.error("Invalid token endpoint URL" )
            await MainActor.run {
                self.lastError = .invalidURL
            }
            return
        }
        
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Prepare form data
        let parameters = [
            "client_id": Configuration.StravaConstants.clientID,
            "client_secret": Configuration.StravaConstants.clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        let formBody = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        
        request.httpBody = formBody.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StravaError.invalidResponse
            }
            
            logger.info("Token exchange response status: \(httpResponse.statusCode)" )
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 400 {
                    logger.error("Bad request - check client credentials and authorization code" )
                    throw StravaError.authorizationFailed("Invalid authorization code or client credentials")
                } else if httpResponse.statusCode == 401 {
                    logger.error("Unauthorized - invalid client credentials" )
                    throw StravaError.unauthorized
                } else {
                    throw StravaError.httpError(httpResponse.statusCode)
                }
            }
            
            // Parse response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.error("Failed to parse token response JSON" )
                throw StravaError.decodingError("Invalid JSON response")
            }
            
            // Extract tokens
            guard let accessToken = json["access_token"] as? String,
                  let refreshToken = json["refresh_token"] as? String else {
                logger.error("Missing tokens in response" )
                throw StravaError.decodingError("Missing access_token or refresh_token")
            }
            
            // Calculate expiration (Strava tokens expire in 6 hours)
            let expiresIn = json["expires_in"] as? Int ?? 21600 // Default to 6 hours
            let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            
            // Extract and store athlete info
            var athleteId = 0
            var athleteUsername: String?
            var athleteFirstName: String?
            var athleteLastName: String?
            
            if let athlete = json["athlete"] as? [String: Any] {
                athleteId = athlete["id"] as? Int ?? 0
                athleteUsername = athlete["username"] as? String
                athleteFirstName = athlete["firstname"] as? String
                athleteLastName = athlete["lastname"] as? String
                
                let displayName = [athleteFirstName, athleteLastName].compactMap { $0 }.joined(separator: " ")
                let logName = displayName.isEmpty ? (athleteUsername ?? "Unknown") : displayName
                logger.info("Successfully authenticated athlete: \(logName) (ID: \(athleteId))" )
            }
            
            // Store tokens and athlete info securely
            await MainActor.run {
                self.storeSecureToken(token: accessToken, key: StravaKeychainKeys.accessToken)
                self.storeSecureToken(token: refreshToken, key: StravaKeychainKeys.refreshToken)
                self.storeTokenExpiration(date: expirationDate)
                self.storeAthleteInfo(id: athleteId, username: athleteUsername, firstName: athleteFirstName, lastName: athleteLastName)
                
                // Update published properties
                self.athleteId = athleteId
                self.athleteUsername = athleteUsername
                self.athleteFirstName = athleteFirstName
                self.athleteLastName = athleteLastName
                
                self.isAuthenticated = true
                self.isLoading = false
                self.lastError = nil
                
                self.logger.info("Successfully exchanged code for tokens and stored athlete info")
                self.logger.info("Access token expires at: \(expirationDate)" )
            }
            
        } catch {
            logger.info("Token exchange failed")
            await MainActor.run {
                self.isLoading = false
                self.lastError = error as? StravaError ?? .networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Token Management
    
    func refreshAccessToken() async -> Bool {
        guard let refreshToken = getSecureToken(key: StravaKeychainKeys.refreshToken),
              !refreshToken.isEmpty else {
            logger.error("No refresh token available for token refresh" )
            return false
        }
        
        logger.info("🔄 Refreshing Strava access token..." )
        
        let success = await performTokenRefresh(refreshToken: refreshToken)
        
        if success {
            logger.info("✅ Strava access token refreshed successfully" )
        } else {
            logger.error("❌ Failed to refresh Strava access token" )
        }
        
        return success
    }
    
    private func performTokenRefresh(refreshToken: String) async -> Bool {
        logger.warning("🚨 DEVELOPMENT ONLY: Direct token refresh in mobile app" )
        
        guard let url = URL(string: Configuration.StravaConstants.tokenEndpoint) else {
            logger.error("Invalid token endpoint URL" )
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Prepare form data for refresh
        let parameters = [
            "client_id": Configuration.StravaConstants.clientID,
            "client_secret": Configuration.StravaConstants.clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        let formBody = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        
        request.httpBody = formBody.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type during token refresh" )
                return false
            }
            
            logger.info("Token refresh response status: \(httpResponse.statusCode)" )
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                    logger.error("Token refresh failed - refresh token may be expired" )
                    await MainActor.run {
                        self.signOut() // Clear invalid tokens
                    }
                }
                return false
            }
            
            // Parse refresh response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newAccessToken = json["access_token"] as? String else {
                logger.error("Failed to parse token refresh response" )
                return false
            }
            
            // Strava may or may not return a new refresh token
            let newRefreshToken = json["refresh_token"] as? String ?? refreshToken
            
            // Calculate new expiration
            let expiresIn = json["expires_in"] as? Int ?? 21600 // Default to 6 hours
            let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
            
            // Store new tokens on main actor
            await MainActor.run {
                self.storeSecureToken(token: newAccessToken, key: StravaKeychainKeys.accessToken)
                self.storeSecureToken(token: newRefreshToken, key: StravaKeychainKeys.refreshToken)
                self.storeTokenExpiration(date: expirationDate)
            }
            
            logger.info("Access token refreshed successfully")
            logger.info("New token expires at: \(expirationDate)" )
            
            return true
            
        } catch {
            logger.info("Token refresh failed")
            return false
        }
    }
    
    // MARK: - API Requests
    
    func fetchActivities() async {
        guard isAuthenticated else {
            logger.warning("Attempted to fetch activities without authentication" )
            return
        }
        
        isLoading = true
        lastError = nil
        
        // Ensure we have a valid token before making API calls
        let tokenValidated = await ensureValidToken()
        guard tokenValidated else {
            logger.error("Could not obtain valid access token for API request" )
            await MainActor.run {
                self.isLoading = false
                self.lastError = .unauthorized
                self.signOut()
            }
            return
        }
        
        guard let accessToken = getSecureToken(key: StravaKeychainKeys.accessToken) else {
            logger.error("No access token available after validation" )
            await MainActor.run {
                self.isLoading = false
                self.signOut()
            }
            return
        }
        
        do {
            let activities = try await performAPIRequest(accessToken: accessToken)
            let runs = activities.filter { $0.type == "Run" }
            
            await MainActor.run {
                self.activities = runs
                self.isLoading = false
            }
            
            logger.info("📊 Fetched \(activities.count) total activities, \(runs.count) are running activities" )
            
            // Log activity types for debugging
            let activityTypes = Dictionary(grouping: activities, by: { $0.type })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            let typeSummary = activityTypes.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logger.info("Activity breakdown: \(typeSummary)" )
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.lastError = error as? StravaError ?? .networkError(error.localizedDescription)
            }
            logger.info("Failed to fetch activities")
        }
    }
    
    // MARK: - Token Validation Helper
    
    private func ensureValidToken() async -> Bool {
        // Check if token needs refresh (with 5 minute buffer)
        if let expirationDate = getTokenExpiration() {
            if expirationDate <= Date().addingTimeInterval(300) { // 5 min buffer
                logger.info("⏰ Token expires soon, refreshing before API call..." )
                let refreshed = await refreshAccessToken()
                if !refreshed {
                    logger.error("❌ Failed to refresh token before API call" )
                    return false
                }
                logger.info("✅ Token refreshed successfully before API call" )
            }
        } else {
            // No expiration date - try refresh as precaution
            logger.warning("⚠️ No token expiration date, refreshing as precaution before API call" )
            let refreshed = await refreshAccessToken()
            if !refreshed {
                logger.error("❌ Failed to refresh token without expiration date" )
                return false
            }
        }
        
        return true
    }
    
    private func performAPIRequest(accessToken: String) async throws -> [StravaActivity] {
        // Fetch more activities with pagination parameters
        // per_page: number of activities per request (max 200)
        // page: page number (starts at 1)
        guard let url = URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=200&page=1") else {
            throw StravaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StravaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw StravaError.unauthorized
            }
            throw StravaError.httpError(httpResponse.statusCode)
        }
        
        
        
        do {
            return try JSONDecoder().decode([StravaActivity].self, from: data)
        } catch {
            throw StravaError.decodingError(error.localizedDescription)
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

// MARK: - PKCE Implementation

extension StravaOAuthManager {
    
    private func generateCodeVerifier() -> String {
        let data = Data((0..<Configuration.StravaConstants.PKCE.codeVerifierLength).map { _ in UInt8.random(in: 0...255) })
        return data.base64URLEncodedString()
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let challenge = SHA256.hash(data: verifier.data(using: .utf8)!)
        return Data(challenge).base64URLEncodedString()
    }
    
    private func generateState() -> String {
        return UUID().uuidString
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
