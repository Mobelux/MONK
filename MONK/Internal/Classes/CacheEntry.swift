//
//  CacheEntry.swift
//  MONK
//
//  Created by Jerry Mayers on 4/24/17.
//  Copyright © 2017 Mobelux. All rights reserved.
//

import Foundation

struct CacheEntry: Equatable, Hashable {
    private enum Constants {
        static let expiration: NSString = "expiration"
        static let requestURL: NSString = "request_url"
        static let cacheURL: NSString = "cache_url"
        static let cachedAt: NSString = "cached_at"
        static let statusCode: NSString = "status_code"
    }

    /// The time at which this entry should no longer be used
    let expiration: Date?

    /// The URL of the original network request
    let requestURL: URL

    /// The URL of the cached file on disk
    let cacheURL: URL

    /// The date this data was added to the cache
    let cachedAt: Date

    /// The original status code
    let statusCode: Int

    var hashValue: Int { return cacheURL.hashValue ^ requestURL.hashValue ^ (expiration?.hashValue ?? 0) ^ statusCode.hashValue }

    var json: JSON {
        var json: JSON = [Constants.cacheURL : cacheURL.absoluteString as NSString, Constants.requestURL : requestURL.absoluteString as NSString, Constants.cachedAt : "\(cachedAt.timeIntervalSince1970)" as NSString, Constants.statusCode : statusCode as NSNumber]
        if let expiration = expiration {
            json[Constants.expiration] = "\(expiration.timeIntervalSince1970)" as NSString
        }
        return json
    }

    init?(json: JSON) {
        guard let cacheURLString = json[Constants.cacheURL] as? String,
            let requestURLString = json[Constants.requestURL] as? String,
            let cacheURL = URL(string: cacheURLString),
            let requestURL = URL(string: requestURLString),
            let cachedAtString = json[Constants.cachedAt] as? String,
            let cachedAtTimeInterval = TimeInterval(cachedAtString),
            let statusCode = json[Constants.statusCode] as? Int else {
                return nil
        }

        self.cacheURL = cacheURL
        self.requestURL = requestURL
        self.cachedAt = Date(timeIntervalSince1970: cachedAtTimeInterval)
        self.statusCode = statusCode

        if let expirationString = json[Constants.expiration] as? String,
            let timeInterval = TimeInterval(expirationString) {
            self.expiration = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.expiration = nil
        }
    }

    init(cacheURL: URL, requestURL: URL, statusCode: Int, expiration: Date?) {
        self.cacheURL = cacheURL
        self.requestURL = requestURL
        self.statusCode = statusCode
        self.expiration = expiration
        self.cachedAt = Date()
    }

    static func == (lhs: CacheEntry, rhs: CacheEntry) -> Bool { return lhs.cacheURL == rhs.cacheURL && lhs.requestURL == rhs.requestURL && lhs.cachedAt == rhs.cachedAt && lhs.statusCode == rhs.statusCode && lhs.expiration == rhs.expiration }
}
