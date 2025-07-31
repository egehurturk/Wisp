//
//  AuthenticationViewModel.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//
import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let supabaseClient = SupabaseManager.shared
    private let logger = LoggerAuth.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        logger.debug("AuthenticationViewModel initialized", category: .ui)
        
        supabaseClient.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.logger.logAuthEvent("Authentication state changed in ViewModel", details: [
                    "isAuthenticated": isAuthenticated
                ])
                self?.clearForm()
            }
            .store(in: &cancellables)
    }
    
    var isSignUpFormValid: Bool {
        let isValid = !email.isEmpty &&
        !password.isEmpty &&
        !username.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        isValidEmail(email) &&
        isValidPassword(password)
        
        let errors = getSignUpValidationErrors()
        logger.logFormValidation("SignUp", isValid: isValid, errors: errors)
        
        return isValid
    }
    
    var isSignInFormValid: Bool {
        let isValid = !email.isEmpty &&
        !password.isEmpty &&
        isValidEmail(email)
        
        let errors = getSignInValidationErrors()
        logger.logFormValidation("SignIn", isValid: isValid, errors: errors)
        
        return isValid
    }
    
    private func getSignUpValidationErrors() -> [String] {
        var errors: [String] = []
        if email.isEmpty { errors.append("Email is empty") }
        else if !isValidEmail(email) { errors.append("Invalid email format") }
        if password.isEmpty { errors.append("Password is empty") }
        else if !isValidPassword(password) {
            errors.append(contentsOf: getPasswordValidationErrors(password))
        }
        if username.isEmpty { errors.append("Username is empty") }
        if confirmPassword.isEmpty { errors.append("Confirm password is empty") }
        if password != confirmPassword { errors.append("Passwords don't match") }
        return errors
    }
    
    private func getSignInValidationErrors() -> [String] {
        var errors: [String] = []
        if email.isEmpty { errors.append("Email is empty") }
        else if !isValidEmail(email) { errors.append("Invalid email format") }
        if password.isEmpty { errors.append("Password is empty") }
        return errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let config = Configuration.Security.self
        
        // Check minimum length
        guard password.count >= config.minimumPasswordLength else {
            return false
        }
        
        // Check for required character types
        if config.requireUppercase && !password.contains(where: { $0.isUppercase }) {
            return false
        }
        
        if config.requireLowercase && !password.contains(where: { $0.isLowercase }) {
            return false
        }
        
        if config.requireNumbers && !password.contains(where: { $0.isNumber }) {
            return false
        }
        
        if config.requireSpecialCharacters && !password.contains(where: { $0.isPunctuation || $0.isSymbol }) {
            return false
        }
        
        return true
    }
    
    func getPasswordValidationErrors(_ password: String) -> [String] {
        var errors: [String] = []
        let config = Configuration.Security.self
        
        if password.count < config.minimumPasswordLength {
            errors.append("Password must be at least \(config.minimumPasswordLength) characters long")
        }
        
        if config.requireUppercase && !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain at least one uppercase letter")
        }
        
        if config.requireLowercase && !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain at least one lowercase letter")
        }
        
        if config.requireNumbers && !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain at least one number")
        }
        
        if config.requireSpecialCharacters && !password.contains(where: { $0.isPunctuation || $0.isSymbol }) {
            errors.append("Password must contain at least one special character")
        }
        
        return errors
    }
    
    func signUp() async {
        logger.logUserAction("Sign up button tapped", details: Configuration.Logger.logSensitiveData ? ["email": email, "username": username] : [:])
        
        guard isSignUpFormValid else {
            logger.warning("Sign up attempted with invalid form", category: .ui)
            await showError("Please fill in all fields correctly.")
            return
        }
        
        guard password == confirmPassword else {
            logger.warning("Sign up attempted with mismatched passwords", category: .ui)
            await showError("Passwords do not match.")
            return
        }
        
        await performAuthAction("signUp") { [self] in
            try await supabaseClient.signUp(
                email: email,
                password: password,
                username: username
            )
        }
    }
    
    func signIn() async {
        logger.logUserAction("Sign in button tapped", details: Configuration.Logger.logSensitiveData ? ["email": email] : [:])
        
        guard isSignInFormValid else {
            logger.warning("Sign in attempted with invalid form", category: .ui)
            await showError("Please enter a valid email and password.")
            return
        }
        
        await performAuthAction("signIn") { [self] in
            try await supabaseClient.signIn(
                email: email,
                password: password
            )
        }
    }
    
    func signInWithGoogle() async {
        logger.logUserAction("Google sign in button tapped")
        
        await performAuthAction("googleSignIn") { [self] in
            try await supabaseClient.signInWithGoogle()
        }
    }
    
    func resetPassword() async {
        logger.logUserAction("Reset password button tapped", details: Configuration.Logger.logSensitiveData ? ["email": email] : [:])
        
        guard !email.isEmpty, isValidEmail(email) else {
            logger.warning("Password reset attempted with invalid email", category: .ui)
            await showError("Please enter a valid email address.")
            return
        }
        
        await performAuthAction("resetPassword") { [self] in
            try await supabaseClient.resetPassword(email: email)
        }
    }
    
    private func performAuthAction(_ actionName: String, _ action: @escaping () async throws -> Void) async {
        let startTime = Date()
        isLoading = true
        errorMessage = nil
        
        logger.info("Starting auth action: \(actionName)", category: .authentication)
        
        do {
            try await action()
            let duration = Date().timeIntervalSince(startTime)
            logger.logPerformanceMetric("\(actionName) duration", value: String(format: "%.3f", duration), unit: "seconds")
            logger.info("Auth action completed successfully: \(actionName)", category: .authentication)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.logPerformanceMetric("\(actionName) duration (failed)", value: String(format: "%.3f", duration), unit: "seconds")
            logger.error("Auth action failed: \(actionName)", error: error, category: .authentication)
            
            // Handle specific SignUpError types with better messaging
            if let signUpError = error as? SignUpError {
                await showSignUpError(signUpError)
            } else {
                await showError(error.localizedDescription)
            }
        }
        
        isLoading = false
    }
    
    private func showError(_ message: String) async {
        logger.warning("Showing error to user: \(message)", category: .ui)
        errorMessage = message
        showingError = true
    }
    
    private func showSignUpError(_ error: SignUpError) async {
        let message = error.errorDescription ?? "Sign up failed"
        logger.warning("Showing sign up error to user: \(message)", category: .ui)
        errorMessage = message
        showingError = true
    }
    
    private func clearForm() {
        logger.debug("Clearing authentication form", category: .ui)
        email = ""
        password = ""
        username = ""
        confirmPassword = ""
        errorMessage = nil
        showingError = false
    }
    
    func clearError() {
        logger.debug("Clearing error state", category: .ui)
        errorMessage = nil
        showingError = false
    }
}
