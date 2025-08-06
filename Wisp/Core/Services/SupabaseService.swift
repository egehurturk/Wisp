//
//  SupabaseService.swift
//  Wisp
//
//  Created by Ege Hurturk on 24.07.2025.
//
import Foundation
import AuthenticationServices
import Supabase
import Auth

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    private let logger = LoggerAuth.shared
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private init() {
        
        guard Configuration.validateConfiguration() else {
            logger.critical("Configuration validation failed", category: .security)
            fatalError(Configuration.configurationError())
        }
        
        guard let url = URL(string: Configuration.Supabase.url) else {
            logger.critical("Invalid Supabase URL provided", category: .security)
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
                   supabaseURL: url,
            supabaseKey: Configuration.Supabase.anonKey
        )
        
        logger.info("Supabase client initialized successfully", category: .authentication)
        
        Task {
            await checkInitialAuthState()
            await setupAuthStateListener()
        }
    }
    
    private func setupAuthStateListener() async {
        logger.info("Setting up auth state listener", category: .authentication)
        for await (event, session) in client.auth.authStateChanges {
            await handleAuthStateChange(event, session: session)
        }
    }
    
    private func handleAuthStateChange(_ event: AuthChangeEvent, session: Session?) async {
        logger.logAuthEvent("Auth state changed", details: ["event": event.rawValue])
        
        switch event {
        case .signedIn:
            if let session = session {
                self.currentUser = session.user
                self.isAuthenticated = true
                let logDetails = Configuration.Logger.logSensitiveData ? [
                    "userId": session.user.id.uuidString,
                    "email": session.user.email ?? "unknown"
                ] : [:]
                logger.logAuthEvent("User signed in successfully", details: logDetails)
            }
        case .signedOut:
            let previousUserId = self.currentUser?.id.uuidString
            self.currentUser = nil
            self.isAuthenticated = false
            let logDetails = Configuration.Logger.logSensitiveData ? [
                "previousUserId": previousUserId ?? "unknown"
            ] : [:]
            logger.logAuthEvent("User signed out", details: logDetails)
        case .passwordRecovery:
            logger.logAuthEvent("Password recovery initiated")
        case .tokenRefreshed:
            logger.logAuthEvent("Auth token refreshed")
        case .userUpdated:
            logger.logAuthEvent("User data updated")
        default:
            logger.logAuthEvent("Unknown auth event", details: ["event": event.rawValue])
        }
    }
    
    private func checkInitialAuthState() async {
        logger.info("🔍 Starting initial authentication state check", category: .authentication)
        
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentUser = session.user
                self.isAuthenticated = true
            }
            let logDetails = Configuration.Logger.logSensitiveData ? [
                "userId": session.user.id.uuidString,
                "email": session.user.email ?? "unknown"
            ] : [:]
            logger.logAuthEvent("✅ Initial auth check: User IS authenticated", details: logDetails)
            logger.info("✅ Session found - user should see HomeView", category: .authentication)
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            logger.logAuthEvent("❌ Initial auth check: User is NOT authenticated")
            logger.info("❌ No session found - user should see OnboardingView. Error: \(error.localizedDescription)", category: .authentication)
        }
        
        logger.info("🔍 Initial auth check completed. isAuthenticated = \(self.isAuthenticated)", category: .authentication)
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        let logDetails = Configuration.Logger.logSensitiveData ? [
            "email": email,
            "username": username
        ] : [:]
        logger.logAuthEvent("Sign up attempt started", details: logDetails)
        
        let metadata: [String: AnyJSON] = [
            "username": AnyJSON.string(username)
        ]
        
        do {
            try await client.auth.signUp(
                email: email,
                password: password,
                data: metadata
            )
            let successDetails = Configuration.Logger.logSensitiveData ? ["email": email] : [:]
            logger.logAuthEvent("Sign up completed successfully", details: successDetails)
        } catch {
            logger.logAuthError("Sign up failed", error: error)
            
            // Transform Supabase errors into user-friendly errors
            throw transformError(error, email: email, username: username)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let logDetails = Configuration.Logger.logSensitiveData ? ["email": email] : [:]
        logger.logAuthEvent("Sign in attempt started", details: logDetails)
        
        do {
            try await client.auth.signIn(email: email, password: password)
            let successDetails = Configuration.Logger.logSensitiveData ? ["email": email] : [:]
            logger.logAuthEvent("Sign in completed successfully", details: successDetails)
        } catch {
            logger.logAuthError("Sign in failed", error: error)
            throw error
        }
    }
    
    func signInWithGoogle() async throws {
        logger.logAuthEvent("Google OAuth sign in attempt started")
        
        // Ensure we have a valid redirect URL
        guard let redirectURL = URL(string: Configuration.URLSchemes.oauthCallback) else {
            logger.error("Invalid OAuth callback URL: \(Configuration.URLSchemes.oauthCallback)", category: .security)
            throw OAuthError.invalidScheme
        }
        
        logger.info("Using OAuth redirect URL: \(redirectURL.absoluteString)", category: .authentication)
        
        do {
            _ = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL
            ) { (session: ASWebAuthenticationSession) in
                // Customize session for better UX
                session.presentationContextProvider = nil
                session.prefersEphemeralWebBrowserSession = false
            }
            logger.logAuthEvent("Google OAuth sign in completed successfully")
        } catch {
            logger.logAuthError("Google OAuth sign in failed", error: error)
            
            // Provide better error context
            if let authError = error as? NSError {
                if authError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && authError.code == 1 {
                    logger.error("OAuth URL validation failed - check Supabase provider configuration", category: .security)
                    throw OAuthError.invalidScheme
                }
            }
            
            throw error
        }
    }
    
    func signOut() async throws {
        let userId = currentUser?.id.uuidString
        logger.logAuthEvent("Sign out attempt started", details: ["userId": userId ?? "unknown"])
        
        do {
            try await client.auth.signOut()
            logger.logAuthEvent("Sign out completed successfully", details: ["userId": userId ?? "unknown"])
        } catch {
            logger.logAuthError("Sign out failed", error: error)
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        let logDetails = Configuration.Logger.logSensitiveData ? ["email": email] : [:]
        logger.logAuthEvent("Password reset attempt started", details: logDetails)
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            let successDetails = Configuration.Logger.logSensitiveData ? ["email": email] : [:]
            logger.logAuthEvent("Password reset email sent successfully", details: successDetails)
        } catch {
            logger.logAuthError("Password reset failed", error: error)
            throw error
        }
    }
    
    /// Handle OAuth callback URL with comprehensive error handling
    func handleOAuthCallback(url: URL) async {
        logger.info("Processing OAuth callback: \(url.absoluteString)", category: .authentication)
        
        // Validate URL structure
        guard url.scheme == Configuration.URLSchemes.main else {
            logger.error("Invalid OAuth callback scheme: \(url.scheme ?? "nil")", category: .security)
            await handleOAuthError(.invalidScheme)
            return
        }
        
        // Check for error parameters in callback
        if let errorCode = url.queryItem(named: "error") {
            logger.error("OAuth callback contained error: \(errorCode)", category: .authentication)
            if let errorDescription = url.queryItem(named: "error_description") {
                logger.error("OAuth error description: \(errorDescription)", category: .authentication)
            }
            await handleOAuthError(.authorizationDenied(errorCode))
            return
        }
        
        do {
            try await client.auth.session(from: url)
            logger.logAuthEvent("OAuth callback processed successfully")
        } catch {
            logger.logAuthError("OAuth callback processing failed", error: error)
            await handleOAuthError(.sessionCreationFailed(error))
        }
    }
    
    private func handleOAuthError(_ error: OAuthError) async {
        // Handle different types of OAuth errors
        switch error {
        case .invalidScheme:
            logger.critical("OAuth callback with invalid URL scheme detected", category: .security)
        case .authorizationDenied(let code):
            logger.warning("User denied OAuth authorization: \(code)", category: .authentication)
        case .sessionCreationFailed(let underlyingError):
            logger.error("Failed to create session from OAuth callback", error: underlyingError, category: .authentication)
        }
        
        // Notify UI about the error
        await MainActor.run {
            // Could emit error notifications here for UI handling
        }
    }
    
    // Get current user's JWT token for backend API calls
    func getCurrentUserToken() async -> String? {
        do {
            let session = try await client.auth.session
            return session.accessToken
        } catch {
            logger.warning("Failed to get current user token: \(error.localizedDescription)", category: .authentication)
            return nil
        }
    }
    
    // Get current user ID
    var currentUserId: String? {
        return currentUser?.id.uuidString
    }
    
    private func transformError(_ error: Error, email: String, username: String) -> SignUpError {
        let errorMessage = error.localizedDescription.lowercased()
        
        // Check for rate limiting
        if errorMessage.contains("rate limit") || errorMessage.contains("too many") {
            return .rateLimitExceeded
        }
        
        // Check for sign-up disabled
        if errorMessage.contains("signup") && (errorMessage.contains("disabled") || errorMessage.contains("closed")) {
            return .signUpDisabled
        }
        
        // Check for duplicate email
        if errorMessage.contains("email") && (errorMessage.contains("already") || errorMessage.contains("exists") || errorMessage.contains("duplicate") || errorMessage.contains("unique")) {
            return .emailAlreadyRegistered(email)
        }
        
        // Check for duplicate username
        if errorMessage.contains("username") && (errorMessage.contains("already") || errorMessage.contains("exists") || errorMessage.contains("duplicate") || errorMessage.contains("unique")) {
            return .usernameAlreadyTaken(username)
        }
        
        // Check for general duplicate constraint violations
        if errorMessage.contains("duplicate") || errorMessage.contains("unique") {
            // Try to determine if it's email or username based on context
            if errorMessage.contains("email") || errorMessage.contains(email) {
                return .emailAlreadyRegistered(email)
            } else if errorMessage.contains("username") || errorMessage.contains(username) {
                return .usernameAlreadyTaken(username)
            }
        }
        
        // Check for invalid email format
        if errorMessage.contains("invalid") && errorMessage.contains("email") {
            return .unknownError("Please enter a valid email address.")
        }
        
        // Check for weak password
        if errorMessage.contains("password") && (errorMessage.contains("weak") || errorMessage.contains("too short") || errorMessage.contains("requirements")) {
            return .unknownError("Password does not meet security requirements. Please use a stronger password.")
        }
        
        // Generic sign up error
        if errorMessage.contains("sign") && errorMessage.contains("up") {
            return .unknownError("Sign up failed. Please check your information and try again.")
        }
        
        return .unknownError(error.localizedDescription)
    }
}

// Custom error types for better UX
enum SignUpError: LocalizedError {
    case emailAlreadyRegistered(String)
    case usernameAlreadyTaken(String)
    case signUpDisabled
    case rateLimitExceeded
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyRegistered(let email):
            return "An account with the email '\(email)' already exists. Please try signing in instead."
        case .usernameAlreadyTaken(let username):
            return "The username '\(username)' is already taken. Please choose a different username."
        case .signUpDisabled:
            return "Account registration is currently disabled. Please try again later."
        case .rateLimitExceeded:
            return "Too many sign-up attempts. Please wait a few minutes before trying again."
        case .unknownError(let message):
            return "Sign up failed: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emailAlreadyRegistered:
            return "Try using the 'Sign In' option if you already have an account."
        case .usernameAlreadyTaken:
            return "Please choose a different username and try again."
        case .signUpDisabled, .rateLimitExceeded:
            return "Please try again later."
        case .unknownError:
            return "Please check your information and try again."
        }
    }
    
}

enum OAuthError: LocalizedError {
    case invalidScheme
    case authorizationDenied(String)
    case sessionCreationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidScheme:
            return "Invalid OAuth callback URL scheme. Please check your app configuration."
        case .authorizationDenied(let code):
            return "OAuth authorization was denied: \(code)"
        case .sessionCreationFailed(let underlyingError):
            return "Failed to create OAuth session: \(underlyingError.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidScheme:
            return "Check that your app's URL scheme matches the one configured in Supabase dashboard."
        case .authorizationDenied:
            return "Please try signing in again and allow the OAuth authorization."
        case .sessionCreationFailed:
            return "Please try again. If the problem persists, check your internet connection."
        }
    }
}

extension URL {
    func queryItem(named name: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.first { $0.name == name }?.value
    }
}
