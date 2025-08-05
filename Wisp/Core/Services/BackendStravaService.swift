//
//  BackendStravaService.swift
//  Wisp
//
//  Created by Claude on 05.08.2025.
//

import Foundation

// MARK: - Backend Response Models

struct StravaOAuthInitiateResponse: Codable {
    let authUrl: String
    let state: String
    let expiresAt: String
    
    enum CodingKeys: String, CodingKey {
        case authUrl = "auth_url"
        case state
        case expiresAt = "expires_at"
    }
}

struct StravaConnectionStatus: Codable {
    let connected: Bool
    let athleteId: Int?
    let athleteName: String?
    let connectedAt: String?
    let tokenExpiresAt: String?
    let scopes: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case connected
        case athleteId = "athlete_id"
        case athleteName = "athlete_name"
        case connectedAt = "connected_at"
        case tokenExpiresAt = "token_expires_at"
        case scopes
        case isActive = "is_active"
    }
}

// MARK: - Backend Errors

enum BackendStravaError: LocalizedError {
    case invalidURL
    case noAuthToken
    case networkError(String)
    case httpError(Int, String?)
    case decodingError(String)
    case unauthorized
    case oauthFailed(String)
    case pollTimeout
    case connectionNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case .noAuthToken:
            return "No authentication token available"
        case .networkError(let message):
            return "Network error: \(message)"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message ?? "Unknown error")"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .unauthorized:
            return "Unauthorized - authentication required"
        case .oauthFailed(let message):
            return "OAuth failed: \(message)"
        case .pollTimeout:
            return "Connection polling timed out"
        case .connectionNotFound:
            return "Strava connection not found"
        }
    }
}

// MARK: - Backend Strava Service

@MainActor
class BackendStravaService: ObservableObject {
    private let logger = Logger.network
    private let session = URLSession.shared
    
    // MARK: - OAuth Initiation
    
    func initiateStravaOAuth() async throws -> StravaOAuthInitiateResponse {
        logger.info("Initiating Strava OAuth through backend")
        
        guard let url = URL(string: "\(Configuration.Backend.baseURL)\(Configuration.Backend.Endpoints.stravaInitiate)") else {
            logger.error("Invalid backend initiate URL")
            throw BackendStravaError.invalidURL
        }
        
        guard let authToken = await getAuthToken() else {
            logger.error("No authentication token available")
            throw BackendStravaError.noAuthToken
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Configuration.Backend.defaultTimeout
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendStravaError.networkError("Invalid response type")
            }
            
            logger.info("OAuth initiate response status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                let initiateResponse = try JSONDecoder().decode(StravaOAuthInitiateResponse.self, from: data)
                logger.info("Successfully initiated OAuth - state: \(initiateResponse.state)")
                return initiateResponse
                
            case 401:
                logger.error("Unauthorized - invalid JWT token")
                throw BackendStravaError.unauthorized
                
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                logger.error("Client error during OAuth initiation: \(errorMessage)")
                throw BackendStravaError.httpError(httpResponse.statusCode, errorMessage)
                
            case 500...599:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                logger.error("Server error during OAuth initiation: \(errorMessage)")
                throw BackendStravaError.httpError(httpResponse.statusCode, errorMessage)
                
            default:
                throw BackendStravaError.httpError(httpResponse.statusCode, "Unexpected response")
            }
            
        } catch let error as BackendStravaError {
            throw error
        } catch {
            logger.error("Network error during OAuth initiation: \(error.localizedDescription)")
            throw BackendStravaError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Connection Status Polling
    
    func getStravaConnectionStatus() async throws -> StravaConnectionStatus {
        logger.debug("Checking Strava connection status")
        
        guard let url = URL(string: "\(Configuration.Backend.baseURL)\(Configuration.Backend.Endpoints.stravaStatus)") else {
            logger.error("Invalid backend status URL")
            throw BackendStravaError.invalidURL
        }
        
        guard let authToken = await getAuthToken() else {
            logger.error("No authentication token available")
            throw BackendStravaError.noAuthToken
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Configuration.Backend.pollTimeout
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendStravaError.networkError("Invalid response type")
            }
            
            logger.debug("Status check response: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                let status = try JSONDecoder().decode(StravaConnectionStatus.self, from: data)
                logger.debug("Connection status: connected=\(status.connected)")
                return status
                
            case 401:
                logger.error("Unauthorized - invalid JWT token")
                throw BackendStravaError.unauthorized
                
            case 404:
                logger.debug("No Strava connection found")
                throw BackendStravaError.connectionNotFound
                
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                logger.error("Client error during status check: \(errorMessage)")
                throw BackendStravaError.httpError(httpResponse.statusCode, errorMessage)
                
            case 500...599:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                logger.error("Server error during status check: \(errorMessage)")
                throw BackendStravaError.httpError(httpResponse.statusCode, errorMessage)
                
            default:
                throw BackendStravaError.httpError(httpResponse.statusCode, "Unexpected response")
            }
            
        } catch let error as BackendStravaError {
            throw error
        } catch {
            logger.error("Network error during status check: \(error.localizedDescription)")
            throw BackendStravaError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Polling with Timeout
    
    func pollForConnection(maxAttempts: Int = 30) async throws -> StravaConnectionStatus {
        logger.info("Starting connection polling (max attempts: \(maxAttempts))")
        
        for attempt in 1...maxAttempts {
            logger.debug("Poll attempt \(attempt)/\(maxAttempts)")
            
            do {
                let status = try await getStravaConnectionStatus()
                
                if status.connected {
                    logger.info("Strava connection established after \(attempt) attempts")
                    return status
                }
                
                // Connection not ready yet, wait before next attempt
                if attempt < maxAttempts {
                    logger.debug("Connection not ready, waiting \(Configuration.Backend.pollInterval)s...")
                    try await Task.sleep(nanoseconds: UInt64(Configuration.Backend.pollInterval * 1_000_000_000))
                }
                
            } catch BackendStravaError.connectionNotFound {
                // Connection not found yet, continue polling
                if attempt < maxAttempts {
                    logger.debug("Connection not found, waiting \(Configuration.Backend.pollInterval)s...")
                    try await Task.sleep(nanoseconds: UInt64(Configuration.Backend.pollInterval * 1_000_000_000))
                }
                continue
                
            } catch {
                // Other errors should be propagated immediately
                logger.error("Error during polling attempt \(attempt): \(error.localizedDescription)")
                throw error
            }
        }
        
        logger.error("Connection polling timed out after \(maxAttempts) attempts")
        throw BackendStravaError.pollTimeout
    }
    
    // MARK: - Authentication Helper
    
    private func getAuthToken() async -> String? {
        logger.debug("Getting authentication token from Supabase")
        
        // Get JWT token from SupabaseManager
        let token = await SupabaseManager.shared.getCurrentUserToken()
        
        if token != nil {
            logger.debug("Successfully retrieved JWT token from Supabase")
        } else {
            logger.warning("No JWT token available - user may not be authenticated")
        }
        
        return token
    }
    
    // MARK: - Connection Management
    
    func disconnectStrava() async throws {
        logger.info("Disconnecting Strava account")
        
        guard let url = URL(string: "\(Configuration.Backend.baseURL)/strava/disconnect") else {
            logger.error("Invalid backend disconnect URL")
            throw BackendStravaError.invalidURL
        }
        
        guard let authToken = await getAuthToken() else {
            logger.error("No authentication token available")
            throw BackendStravaError.noAuthToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Configuration.Backend.defaultTimeout
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendStravaError.networkError("Invalid response type")
            }
            
            logger.info("Disconnect response status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                logger.info("✅ Successfully disconnected Strava account")
                return
                
            case 401:
                logger.error("Unauthorized - invalid JWT token")
                throw BackendStravaError.unauthorized
                
            case 404:
                logger.warning("No Strava connection found to disconnect")
                throw BackendStravaError.connectionNotFound
                
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                logger.error("Client error during disconnect: \(errorMessage)")
                throw BackendStravaError.httpError(httpResponse.statusCode, errorMessage)
                
            case 500...599:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                logger.error("Server error during disconnect: \(errorMessage)")
                throw BackendStravaError.httpError(httpResponse.statusCode, errorMessage)
                
            default:
                throw BackendStravaError.httpError(httpResponse.statusCode, "Unexpected response")
            }
            
        } catch let error as BackendStravaError {
            throw error
        } catch {
            logger.error("Network error during disconnect: \(error.localizedDescription)")
            throw BackendStravaError.networkError(error.localizedDescription)
        }
    }
}
