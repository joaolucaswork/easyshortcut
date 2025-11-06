internal import Foundation
internal import AppKit
internal import CryptoKit

/// Manages persistent caching of menu shortcuts with change detection
@MainActor
final class MenuCacheManager {
    // MARK: - Singleton

    static let shared = MenuCacheManager()

    // MARK: - Private Properties

    /// In-memory cache for fast access
    private var memoryCache: [String: CachedMenuData] = [:]

    /// File URL for persistent storage
    private let cacheFileURL: URL

    /// Maximum age for cache entries (30 days)
    private let maxCacheAge: TimeInterval = 30 * 24 * 60 * 60

    // MARK: - Initialization

    private init() {
        // Set up cache file location in Application Support
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let appFolder = appSupport.appendingPathComponent("easyshortcut", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: appFolder,
            withIntermediateDirectories: true
        )

        cacheFileURL = appFolder.appendingPathComponent("menu_cache.json")

        // Load existing cache
        loadCache()
    }

    // MARK: - Public Methods

    /// Retrieves cached shortcuts for an app if valid
    func getCachedShortcuts(for app: NSRunningApplication) -> [ShortcutItem]? {
        guard let bundleID = app.bundleIdentifier else { return nil }

        // Check memory cache first
        guard var cached = memoryCache[bundleID] else {
            NSLog("📦 MenuCacheManager: No cache found for \(bundleID)")
            return nil
        }

        // Get current app metadata
        guard let metadata = getAppMetadata(for: app) else {
            NSLog("⚠️ MenuCacheManager: Could not get metadata for \(bundleID)")
            return nil
        }

        // Validate cache
        if cached.isValid(
            currentVersion: metadata.version,
            currentModificationDate: metadata.modificationDate,
            currentHash: metadata.hash
        ) {
            // Update access time
            cached.updateAccessTime()
            memoryCache[bundleID] = cached

            NSLog("✅ MenuCacheManager: Cache HIT for \(bundleID) - returning \(cached.shortcuts.count) shortcuts")
            return cached.shortcuts.map { $0.toShortcutItem() }
        } else {
            NSLog("❌ MenuCacheManager: Cache INVALID for \(bundleID) - version or structure changed")
            // Remove invalid cache
            memoryCache.removeValue(forKey: bundleID)
            return nil
        }
    }

    /// Stores shortcuts in cache with metadata
    func cacheShortcuts(_ shortcuts: [ShortcutItem], for app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return }
        guard let metadata = getAppMetadata(for: app) else { return }

        let cachedItems = shortcuts.map { CachedShortcutItem(from: $0) }

        let cacheEntry = CachedMenuData(
            bundleID: bundleID,
            appVersion: metadata.version,
            bundleModificationDate: metadata.modificationDate,
            menuStructureHash: metadata.hash,
            shortcuts: cachedItems
        )

        memoryCache[bundleID] = cacheEntry

        NSLog("💾 MenuCacheManager: Cached \(shortcuts.count) shortcuts for \(bundleID)")

        // Persist to disk asynchronously
        Task {
            await saveCache()
        }
    }

    /// Invalidates cache for a specific app
    func invalidateCache(for bundleID: String) {
        memoryCache.removeValue(forKey: bundleID)
        NSLog("🗑️ MenuCacheManager: Invalidated cache for \(bundleID)")

        Task {
            await saveCache()
        }
    }

    /// Clears all cached data
    func clearAllCache() {
        memoryCache.removeAll()
        NSLog("🗑️ MenuCacheManager: Cleared all cache")

        Task {
            await saveCache()
        }
    }

    // MARK: - Private Methods

    /// Gets metadata for change detection
    private func getAppMetadata(for app: NSRunningApplication) -> (version: String, modificationDate: Date, hash: String)? {
        guard let bundleURL = app.bundleURL else { return nil }

        // Get app version
        let version = app.bundleVersion ?? "unknown"

        // Get bundle modification date
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: bundleURL.path),
              let modDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        // Create a simple hash based on bundle ID + version + mod date
        let hashString = "\(app.bundleIdentifier ?? "")_\(version)_\(modDate.timeIntervalSince1970)"
        let hash = SHA256.hash(data: Data(hashString.utf8))
        let hashHex = hash.compactMap { String(format: "%02x", $0) }.joined()

        return (version, modDate, hashHex)
    }

    /// Loads cache from disk
    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            NSLog("📦 MenuCacheManager: No cache file found, starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: cacheFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let cacheArray = try decoder.decode([CachedMenuData].self, from: data)

            // Convert array to dictionary and filter out old entries
            let now = Date()
            for entry in cacheArray {
                let age = now.timeIntervalSince(entry.cachedAt)
                if age < maxCacheAge {
                    memoryCache[entry.bundleID] = entry
                }
            }

            NSLog("📦 MenuCacheManager: Loaded \(memoryCache.count) cache entries from disk")
        } catch {
            NSLog("⚠️ MenuCacheManager: Failed to load cache: \(error.localizedDescription)")
        }
    }

    /// Saves cache to disk
    private func saveCache() async {
        let cacheArray = Array(memoryCache.values)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(cacheArray)
            try data.write(to: cacheFileURL, options: .atomic)

            NSLog("💾 MenuCacheManager: Saved \(cacheArray.count) cache entries to disk")
        } catch {
            NSLog("⚠️ MenuCacheManager: Failed to save cache: \(error.localizedDescription)")
        }
    }

    /// Returns cache statistics for debugging
    func getCacheStats() -> (totalEntries: Int, oldestEntry: Date?, newestEntry: Date?) {
        let entries = memoryCache.values
        let oldest = entries.map { $0.cachedAt }.min()
        let newest = entries.map { $0.cachedAt }.max()

        return (entries.count, oldest, newest)
    }
}

// MARK: - NSRunningApplication Extension

private extension NSRunningApplication {
    /// Gets the bundle version string
    var bundleVersion: String? {
        guard let bundleURL = bundleURL,
              let bundle = Bundle(url: bundleURL) else {
            return nil
        }

        return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
}

