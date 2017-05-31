//
//  Cache.swift
//  MONK
//
//  MIT License
//
//  Copyright (c) 2017 Mobelux
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// This controls the system's purge behavior
///
/// - purgeOnLowDiskSpace: iOS will be free to purge all/part of the cache on OS updates & low disk space situations. The cache is also purged when you manually call `emptyCache()` or `uncacheObject(for:)`, or when an object's expiration (if it has one) passes.
/// - manualPurgeOrExpirationOnly: The cache is only purged when you manually call `emptyCache()` or `uncacheObject(for:)`, or when an object's expiration (if it has one) passes.
public enum CacheBehavior {
    case purgeOnLowDiskSpace
    case manualPurgeOrExpirationOnly
}

public class Cache {
    fileprivate enum Constants {
        static let cacheFolderName = "MONK_Cache"
        static let cacheMetadataFileName = "cache.metadata"
    }

    private let behavior: CacheBehavior
    fileprivate let fileManager: FileManager
    fileprivate let cacheFolderURL: URL?
    fileprivate let cacheMetadataFile: URL?
    fileprivate var cacheEntries: [URL : CacheEntry]

    struct CacheData {
        let data: Data
        let cachedAt: Date
        let statusCode: Int
    }

    static var purgableCache: Cache = Cache(behavior: .purgeOnLowDiskSpace)
    static var persistantCache: Cache = Cache(behavior: .manualPurgeOrExpirationOnly)

    /// Create the cache. Generally you would want a maximum of 2 caches. One for each behavior, if you create duplicate caches for a behavior, they could interfeer with each other and cause issues. Typically you would use `purgableCache` or `persistantCache` instead of this `init` to prevent that clashing.
    ///
    /// - Parameter behavior: Should the system be allowed to purge the cache or not
    init(behavior: CacheBehavior) {
        self.fileManager = FileManager.default
        self.behavior = behavior
        let directory: FileManager.SearchPathDirectory
        switch behavior {
        case .purgeOnLowDiskSpace:
            directory = .cachesDirectory
        case .manualPurgeOrExpirationOnly:
            directory = .applicationSupportDirectory
        }
        let baseCacheURL = try? fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
        cacheFolderURL = baseCacheURL?.appendingPathComponent(Constants.cacheFolderName, isDirectory: true)
        cacheMetadataFile = cacheFolderURL?.appendingPathComponent(Constants.cacheMetadataFileName)
        cacheEntries = [:]

        createCacheDirectory()
        loadCacheEntries()
    }

    /// Remove everything from the cache
    public func removeAll() {
        guard let cacheFolderURL = cacheFolderURL else { return }
        do {
            try fileManager.removeItem(at: cacheFolderURL)
        } catch {
            print("Couldn't delete MONK cache directory: \(cacheFolderURL.absoluteString), with error: \(error)")
        }
        createCacheDirectory()
        loadCacheEntries()
    }

    /// Purges a specific object from the cache, dispite any expiration it may have had. Also triggers a purge of any expired objects in the cache
    ///
    /// - Parameter url: The remote URL that was used to fetch the object
    public func removeObject(for url: URL) {
        purgeAnyExpiredObjects()

        guard let entry = cacheEntries[url] else {
            return
        }

        do {
            try fileManager.removeItem(at: entry.cacheURL)
        } catch {
            print("Couldn't delete MONK cache file with error: \(error)")
        }

        cacheEntries.removeValue(forKey: url)
    }

    /// Adds an object to the cache, also triggers a purge of any expired objects in the cache
    ///
    /// - Parameters:
    ///   - object: The object to cache
    ///   - url: The remote URL that was used to fetch the `object`
    ///   - statusCode: The status code originally recieved when the object was fetched
    ///   - expiration: If you want this object to expire, this should be the time that expiration should occur. The cached object is not guarenteed to be purged as soon as this time is hit, but with normal cache use it should be purged shortly there after. You will never be able to get an expired object out of the cache. If the expiration is in the past, then the object won't be cached to begin with.
    func add(object: Data, url: URL, statusCode: Int, expiration: Date?) {
        // incase there is a previously cached entry for this URL, remove it first, otherwise it's cache file would become orphaned and would not be able to be individually purged.
        removeObject(for: url)
        if let expiration = expiration, expiration < Date() {
            // Expiration already passed, so don't cache
            return
        }

        guard let entry = createCacheEntry(forRequestURL: url, statusCode: statusCode, expiration: expiration) else { return }
        do {
            try object.write(to: entry.cacheURL, options: .atomic)
            cacheEntries[url] = entry
            saveCacheEntries()
        } catch {
            print("Couldn't write MONK cache file with error: \(error)")
        }
    }

    /// Gets the cached object for a URL. Also triggers a purge of expired objects, prior to getting the cached object
    ///
    /// - Parameter url: The remote URL that you want the cached response data for
    /// - Returns: The cached response data, nil if there isn't any, or it had expired
    func cachedObject(for url: URL) -> CacheData? {
        purgeAnyExpiredObjects()
        guard let entry = cacheEntries[url] else {
            return nil
        }
        do {
            let data = try Data(contentsOf: entry.cacheURL)
            return CacheData(data: data, cachedAt: entry.cachedAt, statusCode: entry.statusCode)
        } catch {
            print("Couldn't read MONK cache file with error: \(error)")
            // We can't read the data from disk, so we should stop thinking we have this object cached
            removeObject(for: url)
            return nil
        }
    }
}

private extension Cache {
    func createCacheDirectory() {
        guard let cacheFolderURL = cacheFolderURL else { return }
        do {
            try fileManager.createDirectory(at: cacheFolderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Couldn't create MONK cache directory: \(cacheFolderURL.absoluteString), with error: \(error)")
        }
    }

    func loadCacheEntries() {
        cacheEntries.removeAll()
        guard let cacheMetadataFile = cacheMetadataFile else { return }

        do {
            let data = try Data(contentsOf: cacheMetadataFile)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [JSON] {
                let entries = json.flatMap({ return CacheEntry(json: $0) })
                for entry in entries {
                    cacheEntries[entry.requestURL] = entry
                }
            }
        } catch {
            print("Couldn't load the MONK cache metadata with error: \(error)")
        }
    }

    func saveCacheEntries() {
        guard let cacheMetadataFile = cacheMetadataFile else { return }
        let entries = cacheEntries.map({ $0.value.json })
        do {
            let data = try JSONSerialization.data(withJSONObject: entries, options: [])
            try data.write(to: cacheMetadataFile)
        } catch {
            print("Couldn't save the MONK cache metadata with error: \(error)")
        }
    }

    func purgeAnyExpiredObjects() {
        let now = Date()
        let expiredEntrys = cacheEntries.filter({ (_, entry) in
            if let expiration = entry.expiration, expiration < now {
                return true
            } else {
                return false
            }
        })
        for (url, entry) in expiredEntrys {
            do {
                try fileManager.removeItem(at: entry.cacheURL)
            } catch {
                print("Couldn't purge MONK cache file with error: \(error)")
            }
            cacheEntries.removeValue(forKey: url)
        }
        saveCacheEntries()
    }

    func createCacheEntry(forRequestURL url: URL, statusCode: Int, expiration: Date?) -> CacheEntry? {
        guard let cacheFolderURL = cacheFolderURL else { return nil }

        let uuid = UUID().uuidString
        let cacheFileName = "\(uuid).cache"
        let cacheURL = cacheFolderURL.appendingPathComponent(cacheFileName)
        let entry = CacheEntry(cacheURL: cacheURL, requestURL: url, statusCode: statusCode, expiration: expiration)
        return entry
    }
}
