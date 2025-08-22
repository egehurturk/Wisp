import Foundation
import SwiftUI

/// Centralized cache management system for Wisp app
/// Provides both in-memory and persistent caching capabilities
@MainActor
final class CacheManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    
    // MARK: - Properties
    private let logger = Logger.ui
    private let memoryCache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Cache configuration
    private let defaultCacheTTL: TimeInterval = 5 * 60 // 5 minutes
    private let routeCacheTTL: TimeInterval = 24 * 60 * 60 // 24 hours (routes rarely change)
    private let runsCacheTTL: TimeInterval = 20 * 60 // 20 minutes
    
    // MARK: - Initialization
    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        memoryCache.countLimit = 1000 // Max 1000 items
        
        // Setup cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("WispCache", isDirectory: true)
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        logger.info("CacheManager initialized with cache directory: \(cacheDirectory.path)")
        
        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Warning Handler
    @objc private func handleMemoryWarning() {
        logger.warning("Memory warning received - clearing memory cache")
        memoryCache.removeAllObjects()
    }
    
    // MARK: - Generic Cache Methods
    
    /// Cache an object in memory with TTL
    func cacheObject<T: Codable>(_ object: T, forKey key: String, ttl: TimeInterval = 0) {
        let actualTTL = ttl > 0 ? ttl : defaultCacheTTL
        let wrapper = CacheWrapper(object: object, expiresAt: Date().addingTimeInterval(actualTTL))
        
        memoryCache.setObject(wrapper as AnyObject, forKey: NSString(string: key))
        logger.debug("Cached object for key: \(key) with TTL: \(actualTTL)s")
    }
    
    /// Retrieve cached object from memory
    func getCachedObject<T: Codable>(forKey key: String, type: T.Type) -> T? {
        guard let wrapper = memoryCache.object(forKey: NSString(string: key)) as? CacheWrapper<T> else {
            return nil
        }
        
        // Check if expired
        if wrapper.expiresAt < Date() {
            memoryCache.removeObject(forKey: NSString(string: key))
            logger.debug("Cache expired for key: \(key)")
            return nil
        }
        
        logger.debug("Cache hit for key: \(key)")
        return wrapper.object
    }
    
    /// Cache object to disk (persistent)
    func persistObject<T: Codable>(_ object: T, forKey key: String, ttl: TimeInterval = 0) {
        let actualTTL = ttl > 0 ? ttl : defaultCacheTTL
        let wrapper = CacheWrapper(object: object, expiresAt: Date().addingTimeInterval(actualTTL))
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: fileURL)
            logger.debug("Persisted object for key: \(key)")
        } catch {
            logger.error("Failed to persist object for key: \(key)", error: error)
        }
    }
    
    /// Retrieve persisted object from disk
    func getPersistedObject<T: Codable>(forKey key: String, type: T.Type) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let wrapper = try JSONDecoder().decode(CacheWrapper<T>.self, from: data)
            
            // Check if expired
            if wrapper.expiresAt < Date() {
                try? fileManager.removeItem(at: fileURL)
                logger.debug("Persisted cache expired for key: \(key)")
                return nil
            }
            
            logger.debug("Persisted cache hit for key: \(key)")
            return wrapper.object
        } catch {
            logger.error("Failed to retrieve persisted object for key: \(key)", error: error)
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    // MARK: - Cache Invalidation
    
    /// Remove object from memory cache
    func invalidateMemoryCache(forKey key: String) {
        memoryCache.removeObject(forKey: NSString(string: key))
        logger.debug("Invalidated memory cache for key: \(key)")
    }
    
    /// Remove object from persistent cache
    func invalidatePersistedCache(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: fileURL)
        logger.debug("Invalidated persisted cache for key: \(key)")
    }
    
    /// Remove object from both memory and persistent cache
    func invalidateCache(forKey key: String) {
        invalidateMemoryCache(forKey: key)
        invalidatePersistedCache(forKey: key)
    }
    
    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        logger.info("Cleared all memory cache")
    }
    
    /// Clear all persistent cache
    func clearPersistedCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "cache" {
                try fileManager.removeItem(at: file)
            }
            logger.info("Cleared all persistent cache")
        } catch {
            logger.error("Failed to clear persistent cache", error: error)
        }
    }
    
    /// Clear all cache (memory + persistent)
    func clearAllCache() {
        clearMemoryCache()
        clearPersistedCache()
    }
    
    // MARK: - Cache Statistics
    
    /// Get cache usage statistics
    func getCacheStatistics() -> CacheStatistics {
        var diskSize: Int64 = 0
        var fileCount = 0
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            fileCount = files.filter { $0.pathExtension == "cache" }.count
            
            for file in files where file.pathExtension == "cache" {
                if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]),
                   let size = resources.fileSize {
                    diskSize += Int64(size)
                }
            }
        } catch {
            logger.error("Failed to calculate cache statistics", error: error)
        }
        
        return CacheStatistics(
            memoryItemCount: memoryCache.totalCostLimit,
            diskFileCount: fileCount,
            diskSizeBytes: diskSize,
            diskSizeMB: Double(diskSize) / 1024.0 / 1024.0
        )
    }
}

// MARK: - Specialized Cache Methods

extension CacheManager {
    
    // MARK: - Run Caching
    
    private func runsKey(forUserId userId: String) -> String {
        return "runs_\(userId)"
    }
    
    func cacheRuns(_ runs: [Run], forUserId userId: String) {
        let key = runsKey(forUserId: userId)
        cacheObject(runs, forKey: key, ttl: runsCacheTTL)
    }
    
    func getCachedRuns(forUserId userId: String) -> [Run]? {
        let key = runsKey(forUserId: userId)
        return getCachedObject(forKey: key, type: [Run].self)
    }
    
    func invalidateRunsCache(forUserId userId: String) {
        let key = runsKey(forUserId: userId)
        invalidateCache(forKey: key)
    }
    
    // MARK: - Route Caching
    
    private func routeKey(forRunId runId: String) -> String {
        return "route_\(runId)"
    }
    
    func cacheRoute(_ route: RunRoute, forRunId runId: String) {
        let key = routeKey(forRunId: runId)
        // Cache in memory for quick access
        cacheObject(route, forKey: key, ttl: routeCacheTTL)
        // Also persist to disk since routes are large and don't change
        persistObject(route, forKey: key, ttl: routeCacheTTL)
    }
    
    func getCachedRoute(forRunId runId: String) -> RunRoute? {
        let key = routeKey(forRunId: runId)
        // Try memory cache first
        if let route = getCachedObject(forKey: key, type: RunRoute.self) {
            return route
        }
        // Fallback to persistent cache
        if let route = getPersistedObject(forKey: key, type: RunRoute.self) {
            // Re-cache in memory for future access
            cacheObject(route, forKey: key, ttl: routeCacheTTL)
            return route
        }
        return nil
    }
    
    func invalidateRouteCache(forRunId runId: String) {
        let key = routeKey(forRunId: runId)
        invalidateCache(forKey: key)
    }
}

// MARK: - Supporting Types

/// Wrapper for cached objects with expiration
private struct CacheWrapper<T: Codable>: Codable {
    let object: T
    let expiresAt: Date
}

/// Cache usage statistics
struct CacheStatistics {
    let memoryItemCount: Int
    let diskFileCount: Int
    let diskSizeBytes: Int64
    let diskSizeMB: Double
    
    var description: String {
        return """
        Cache Statistics:
        - Memory items: \(memoryItemCount)
        - Disk files: \(diskFileCount)
        - Disk size: \(String(format: "%.2f", diskSizeMB)) MB
        """
    }
}
