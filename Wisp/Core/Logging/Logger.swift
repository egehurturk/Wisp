import Foundation
import os.log

/// Enterprise-level logging system for Wisp
/// Provides structured logging with different levels and categories
final class Logger {
    
    // MARK: - Log Levels
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    // MARK: - Log Categories
    enum Category: String, CaseIterable {
        case ui = "UI"
        case network = "NETWORK"
        case persistence = "PERSISTENCE"
        case location = "LOCATION"
        case authentication = "AUTH"
        case ghost = "GHOST"
        case groups = "GROUPS"
        case general = "GENERAL"
        
        var subsystem: String {
            "com.wisp.app"
        }
    }
    
    // MARK: - Properties
    private let osLog: OSLog
    private let category: Category
    private let dateFormatter: DateFormatter
    
    // MARK: - Initialization
    init(category: Category) {
        self.category = category
        self.osLog = OSLog(subsystem: category.subsystem, category: category.rawValue)
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    // MARK: - Public Logging Methods
    
    /// Log debug information
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    /// Log general information
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// Log warnings
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// Log errors
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .error, message: fullMessage, file: file, function: function, line: line)
    }
    
    /// Log critical errors
    func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Critical Error: \(error.localizedDescription)"
        }
        log(level: .critical, message: fullMessage, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(category.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // Also print to console in debug builds
        #if DEBUG
        print(logMessage)
        #endif
    }
}

// MARK: - Convenience Extensions
extension Logger {
    
    /// Create logger for UI components
    static let ui = Logger(category: .ui)
    
    /// Create logger for network operations
    static let network = Logger(category: .network)
    
    /// Create logger for persistence operations
    static let persistence = Logger(category: .persistence)
    
    /// Create logger for location services
    static let location = Logger(category: .location)
    
    /// Create logger for authentication
    static let auth = Logger(category: .authentication)
    
    /// Create logger for ghost features
    static let ghost = Logger(category: .ghost)
    
    /// Create logger for groups functionality
    static let groups = Logger(category: .groups)
    
    /// Create logger for general operations
    static let general = Logger(category: .general)
}
