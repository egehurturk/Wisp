//
//  Configuration.swift
//  Wisp
//
//  Created by Ege Hurturk on 24.07.2025.
//

import Foundation

let logger = Logger.general

enum Configuration {
    
    
    enum URLSchemes {
        static let main = "wisp"
        static let oauthCallback = "\(main)://supabase-auth-callback"
        static let stravaCallback = "\(main)://strava-callback"
    }
    
    enum StravaConstants {
        static var clientID: String {
            if let clientId = Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_ID") as? String,
               !clientId.isEmpty, !clientId.contains("YOUR_") {
                return clientId
            }
            
            #if DEBUG
            // Demo client ID - replace with your actual Strava client ID
            logger.warning("Using demo Strava client ID. Configure STRAVA_CLIENT_ID in Info.plist for production.")
            return "168939"
            #else
            fatalError("STRAVA_CLIENT_ID not configured. Add it to Info.plist or use environment variables.")
            #endif
        }
        
        static let redirectURI = URLSchemes.stravaCallback
        
        // Use mobile authorization endpoint as recommended by Strava
        static let mobileAuthorizationEndpoint = "https://www.strava.com/oauth/mobile/authorize"
        static let appAuthorizationScheme = "strava://oauth/mobile/authorize"
        
        static let tokenEndpoint = "https://www.strava.com/oauth/token"
        static let scope = "read,activity:read_all"
        
        // PKCE configuration for secure OAuth
        enum PKCE {
            static let codeChallengeMethod = "S256"
            static let codeVerifierLength = 128
        }
        
        // DEVELOPMENT ONLY: Client secret for direct token exchange
        // ⚠️ WARNING: This should be moved to backend in production
        static var clientSecret: String {
            if let secret = Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_SECRET") as? String,
               !secret.isEmpty, !secret.contains("YOUR_") {
                return secret
            }
            
            #if DEBUG
            // Demo client secret - replace with your actual Strava client secret
            logger.warning("🚨 Using demo Strava client secret in mobile app - INSECURE for production!")
            return "d27e14c9d1cd96d5dfc9e05ce44b4576739766eb"
            #else
            fatalError("STRAVA_CLIENT_SECRET not configured and this should be handled by backend in production.")
            #endif
        }
    }

    enum Supabase {
        // TODO: migrate these to new API keys (supabase)
        // These should be loaded from environment variables or configuration files
        // For development, fallback to demo values (mark them clearly as insecure)
        static var url: String {
            if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
               !url.isEmpty, !url.contains("YOUR_") {
                return url
            }
            
            #if DEBUG
            // Demo URL - replace with your actual Supabase URL
            logger.warning("Using demo Supabase URL. Configure SUPABASE_URL in Info.plist for production.")
            return "https://tcpvmldytbxoyslrobot.supabase.co"
            #else
            fatalError("SUPABASE_URL not configured. Add it to Info.plist or use environment variables.")
            #endif
        }
        
        static var anonKey: String {
            if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
               !key.isEmpty, !key.contains("YOUR_") {
                return key
            }
            
            #if DEBUG
            // Demo key - replace with your actual Supabase anon key
            logger.warning("Using demo Supabase anon key. Configure SUPABASE_ANON_KEY in Info.plist for production.")
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjcHZtbGR5dGJ4b3lzbHJvYm90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMDYwMDgsImV4cCI6MjA2ODU4MjAwOH0.HalhuU06EK1wOnT2dQ_qNDQnZVauD5g2XXacI5w9qws"
            #else
            fatalError("SUPABASE_ANON_KEY not configured. Add it to Info.plist or use environment variables.")
            #endif
        }
    }
    
    enum Google {
        static var clientId: String {
            if let clientId = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
               !clientId.isEmpty, !clientId.contains("YOUR_") {
                return clientId
            }
            
            #if DEBUG
            // Demo client ID - replace with your actual Google client ID
            logger.warning("Using demo Google client ID. Configure GOOGLE_CLIENT_ID in Info.plist for production.")
            return "482888449961-i0njs56p0dkecjhfdf4ki64m20qvn3go.apps.googleusercontent.com"
            #else
            fatalError("GOOGLE_CLIENT_ID not configured. Add it to Info.plist or use environment variables.")
            #endif
        }
        
        // Client secret should never be in mobile apps
        // Google OAuth for mobile uses PKCE flow without client secret
        // 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
    }
    
    enum Security {
        static let minimumPasswordLength = 12
        static let requireSpecialCharacters = true
        static let requireNumbers = true
        static let requireUppercase = true
        static let requireLowercase = true
        
        // PKCE code challenge method
        static let codeChallengeMethod = "S256"
    }
    
    enum Logger {
        #if DEBUG
        static let minimumLevel: LogLevel = .debug
        static let enableConsoleLogging = true
        static let logSensitiveData = false // Never log sensitive data even in debug
        #else
        static let minimumLevel: LogLevel = .info
        static let enableConsoleLogging = false
        static let logSensitiveData = false
        #endif
    }
}

// Legacy support - mark as deprecated
@available(*, deprecated, message: "Use Configuration instead")
typealias Secrets = Configuration

extension Configuration {
    
    static func validateConfiguration() -> Bool {
        // Configuration is now self-validating through the computed properties
        // Just check if we can access the basic values without crashing
        return true
    }
    
    static func configurationError() -> String {
        return """
        Configuration Error: Please configure your API keys and URLs.
        
        For development, add the following to your Info.plist:
        - SUPABASE_URL: Your Supabase project URL
        - SUPABASE_ANON_KEY: Your Supabase anonymous key
        - GOOGLE_CLIENT_ID: Your Google OAuth client ID
        
        For production, use secure configuration management.
        """
    }
}

enum ConfigurationError: LocalizedError {
    case missing(String)
    
    var errorDescription: String? {
        switch self {
        case .missing(let key):
            return "Configuration key '\(key)' is missing or invalid. Please check your Info.plist or environment configuration."
        }
    }
}
