//
//  LoggerAuth.swift
//  Wisp
//
//  Created by Ege Hurturk on 24.07.2025.
//

import Foundation
import os.log

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🚨"
        }
    }
}

enum LogCategory: String, CaseIterable {
    case authentication = "Authentication"
    case network = "Network"
    case ui = "UI"
    case general = "General"
    case security = "Security"
    case database = "Database"
    
    var subsystem: String {
        return "com.SupaBaseLoginDemo.\(self.rawValue)"
    }
}

final class LoggerAuth {
    static let shared = LoggerAuth()
    
    private let dateFormatter: DateFormatter
    private let minimumLogLevel: LogLevel
    private var loggers: [LogCategory: os.Logger] = [:]
    
    private init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.minimumLogLevel = Configuration.Logger.minimumLevel
        
        // Initialize OS loggers for each category
        for category in LogCategory.allCases {
            loggers[category] = os.Logger(subsystem: category.subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - Public Logging Methods
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .error, message: fullMessage, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .critical, message: fullMessage, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Authentication Specific Logging
    
    func logAuthEvent(_ event: String, details: [String: Any] = [:]) {
        let detailsString = details.isEmpty ? "" : " | Details: \(details)"
        info("Auth Event: \(event)\(detailsString)", category: .authentication)
    }
    
    func logAuthError(_ event: String, error: Error) {
        self.error("Auth Error: \(event)", error: error, category: .authentication)
    }
    
    func logSecurityEvent(_ event: String, details: [String: Any] = [:]) {
        let detailsString = details.isEmpty ? "" : " | Details: \(details)"
        warning("Security Event: \(event)\(detailsString)", category: .security)
    }
    
    // MARK: - UI Event Logging
    
    func logUIEvent(_ event: String, view: String, details: [String: Any] = [:]) {
        let detailsString = details.isEmpty ? "" : " | Details: \(details)"
        debug("UI Event: \(event) in \(view)\(detailsString)", category: .ui)
    }
    
    func logViewLifecycle(_ event: String, view: String) {
        debug("View Lifecycle: \(view) - \(event)", category: .ui)
    }
    
    // MARK: - Network Logging
    
    func logNetworkRequest(_ endpoint: String, method: String) {
        info("Network Request: \(method) \(endpoint)", category: .network)
    }
    
    func logNetworkResponse(_ endpoint: String, statusCode: Int, duration: TimeInterval) {
        info("Network Response: \(endpoint) | Status: \(statusCode) | Duration: \(String(format: "%.3f", duration))s", category: .network)
    }
    
    func logNetworkError(_ endpoint: String, error: Error) {
        self.error("Network Error: \(endpoint)", error: error, category: .network)
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, category: LogCategory, file: String, function: String, line: Int) {
        guard shouldLog(level: level) else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "\(level.emoji) [\(level.rawValue)] \(timestamp) | \(fileName):\(line) \(function) | \(message)"
        
        // Log to OS Logger
        if let osLogger = loggers[category] {
            osLogger.log(level: level.osLogType, "\(logMessage)")
        }
        
        // Log to console in debug builds
        #if DEBUG
        print(logMessage)
        #endif
    }
    
    private func shouldLog(level: LogLevel) -> Bool {
        return level.rawValue >= minimumLogLevel.rawValue
    }
}

// MARK: - Convenience Extensions

extension LoggerAuth {
    func logUserAction(_ action: String, details: [String: Any] = [:]) {
        let detailsString = details.isEmpty ? "" : " | \(details)"
        info("User Action: \(action)\(detailsString)", category: .ui)
    }
    
    func logFormValidation(_ form: String, isValid: Bool, errors: [String] = []) {
        let status = isValid ? "Valid" : "Invalid"
        let errorString = errors.isEmpty ? "" : " | Errors: \(errors.joined(separator: ", "))"
        debug("Form Validation: \(form) - \(status)\(errorString)", category: .ui)
    }
    
    func logPerformanceMetric(_ metric: String, value: Any, unit: String = "") {
        info("Performance: \(metric) = \(value) \(unit)", category: .general)
    }
}
