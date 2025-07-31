//
//  SignInView.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation
import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FormField?
    @State private var showingForgotPassword = false
    
    enum FormField: Hashable {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    formSection
                    actionButtons
                    forgotPasswordSection
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
            .alert("Reset Password", isPresented: $showingForgotPassword) {
                Button("Cancel", role: .cancel) { }
                Button("Send Reset Email") {
                    Task {
                        await viewModel.resetPassword()
                    }
                }
            } message: {
                Text("Enter your email address and we'll send you a password reset link.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to your account")
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
                focusedField = .password
            }
            
            CustomTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: $viewModel.password,
                keyboardType: .default,
                isSecure: true
            )
            .focused($focusedField, equals: .password)
            .onSubmit {
                if viewModel.isSignInFormValid {
                    Task {
                        await viewModel.signIn()
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.isSignInFormValid ? .blue : .gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.isSignInFormValid || viewModel.isLoading)
            
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
                title: "Sign in with Google",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }
        }
    }
    
    private var forgotPasswordSection: some View {
        Button("Forgot Password?") {
            showingForgotPassword = true
        }
        .font(.callout)
        .foregroundStyle(.blue)
        .padding(.top, 16)
    }
}

#Preview {
    SignInView()
}
