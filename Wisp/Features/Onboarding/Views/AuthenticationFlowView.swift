//
//  AuthenticationFlowView.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation
import SwiftUI

struct AuthenticationFlowView: View {
    let flow: AuthenticationFlow
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch flow {
            case .signUp:
                SignUpView()
            case .signIn:
                SignInView()
            case .googleOAuth:
                GoogleOAuthView()
            }
        }
    }
}

struct GoogleOAuthView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "globe")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    VStack(spacing: 12) {
                        Text("Continue with Google")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in securely with your Google account")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    GoogleSignInButton(
                        title: "Continue with Google",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    }
                    
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
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
}

#Preview {
    AuthenticationFlowView(flow: .signUp)
}
