//
//  CustomTextField.swift
//  Wisp
//
//  Created by Ege Hurturk on 31.07.2025.
//

import Foundation
import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    
    @State private var isSecureTextVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            HStack {
                Group {
                    if isSecure && !isSecureTextVisible {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .font(.body)
                .padding(.horizontal, 16)
                .frame(height: 56)
                
                if isSecure {
                    Button(action: {
                        isSecureTextVisible.toggle()
                    }) {
                        Image(systemName: isSecureTextVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .padding(.trailing, 16)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            keyboardType: .emailAddress,
            isSecure: false
        )
        
        CustomTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            keyboardType: .default,
            isSecure: true
        )
    }
    .padding()
}
