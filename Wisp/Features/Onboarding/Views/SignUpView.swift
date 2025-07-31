//
//  SignUpView.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation
import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FormField?
    
    enum FormField: Hashable {
        case email, username, password, confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    formSection
                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Join us and start your journey")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            CustomTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                isSecure: false
            )
            .focused($focusedField, equals: .email)
            .onSubmit {
                focusedField = .username
            }
            
            CustomTextField(
                title: "Username",
                placeholder: "Choose a username",
                text: $viewModel.username,
                keyboardType: .default,
                isSecure: false
            )
            .focused($focusedField, equals: .username)
            .onSubmit {
                focusedField = .password
            }
            
            CustomTextField(
                title: "Password",
                placeholder: "Create a password",
                text: $viewModel.password,
                keyboardType: .default,
                isSecure: true
            )
            .focused($focusedField, equals: .password)
            .onSubmit {
                focusedField = .confirmPassword
            }
            
            CustomTextField(
                title: "Confirm Password",
                placeholder: "Confirm your password",
                text: $viewModel.confirmPassword,
                keyboardType: .default,
                isSecure: true
            )
            .focused($focusedField, equals: .confirmPassword)
            .onSubmit {
                if viewModel.isSignUpFormValid {
                    Task {
                        await viewModel.signUp()
                    }
                }
            }
            
            passwordRequirements
        }
    }
    
    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password requirements:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            PasswordRequirementRow(
                text: "At least 12 characters",
                isValid: viewModel.password.count >= Configuration.Security.minimumPasswordLength
            )
            
            PasswordRequirementRow(
                text: "Contains uppercase letter",
                isValid: viewModel.password.contains(where: { $0.isUppercase })
            )
            
            PasswordRequirementRow(
                text: "Contains lowercase letter",
                isValid: viewModel.password.contains(where: { $0.isLowercase })
            )
            
            PasswordRequirementRow(
                text: "Contains number",
                isValid: viewModel.password.contains(where: { $0.isNumber })
            )
            
            PasswordRequirementRow(
                text: "Contains special character",
                isValid: viewModel.password.contains(where: { $0.isPunctuation || $0.isSymbol })
            )
            
            if !viewModel.confirmPassword.isEmpty {
                PasswordRequirementRow(
                    text: "Passwords match",
                    isValid: viewModel.password == viewModel.confirmPassword,
                    showError: viewModel.password != viewModel.confirmPassword
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isSignUpFormValid ? .blue : .gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.isSignUpFormValid || viewModel.isLoading)
            
            HStack {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
            }
            
            GoogleSignInButton(
                title: "Sign up with Google",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }
        }
    }
}

struct PasswordRequirementRow: View {
    let text: String
    let isValid: Bool
    let showError: Bool
    
    init(text: String, isValid: Bool, showError: Bool = false) {
        self.text = text
        self.isValid = isValid
        self.showError = showError
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : (showError ? "xmark.circle.fill" : "circle"))
                .foregroundStyle(isValid ? .green : (showError ? .red : .secondary))
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(isValid ? .green : (showError ? .red : .secondary))
            
            Spacer()
        }
    }
}

#Preview {
    SignUpView()
}
