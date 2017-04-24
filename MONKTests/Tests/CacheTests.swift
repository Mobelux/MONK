//
//  CacheTests.swift
//  MONK
//
//  Created by Jerry Mayers on 4/24/17.
//  Copyright © 2017 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class CacheTests: XCTestCase {

    func testCacheManualPurge() {
        guard let cache = try? Cache(behavior: .manualPurgeOrExpirationOnly) else {
            XCTAssert(false, "Could not create cache")
            return
        }

        let string = "Hello world"
        let data = string.data(using: .utf8)!
        let url = URL(string: "http://mobelux.com")!

        cache.add(object: data, url: url, expiration: nil)
        XCTAssertNotNil(cache.cachedObject(for: url), "Data was not cached")

        cache.removeObject(for: url)
        XCTAssertNil(cache.cachedObject(for: url), "Data was not purged")

        cache.add(object: data, url: url, expiration: nil)
        XCTAssertNotNil(cache.cachedObject(for: url), "Data was not cached")

        cache.removeAll()
        XCTAssertNil(cache.cachedObject(for: url), "Data was not purged")
    }

    func testExpiration() {
        guard let cache = try? Cache(behavior: .manualPurgeOrExpirationOnly) else {
            XCTAssert(false, "Could not create cache")
            return
        }

        let string = "Hello world"
        let data = string.data(using: .utf8)!
        let url = URL(string: "http://mobelux.com")!
        let now = Date()

        cache.add(object: data, url: url, expiration: now)
        XCTAssertNil(cache.cachedObject(for: url), "Data was cached, but shouldn't have been")

        let timeInterval: TimeInterval = 0.25
        let future = Date(timeIntervalSinceNow: timeInterval)
        cache.add(object: data, url: url, expiration: future)
        XCTAssertNotNil(cache.cachedObject(for: url), "Data was not cached")

        let ex = expectation(description: "Cache expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { 
            XCTAssertNil(cache.cachedObject(for: url), "Data was cached, but have been expired")
            ex.fulfill()
        }
        wait(for: [ex], timeout: 3)
    }

    func testMetaDataSaveLoad() {
        let behavior: Cache.Behavior = .manualPurgeOrExpirationOnly

        guard let cache = try? Cache(behavior: behavior) else {
            XCTAssert(false, "Could not create cache")
            return
        }

        let string = "Hello world"
        let data = string.data(using: .utf8)!
        let url = URL(string: "http://mobelux.com")!

        cache.add(object: data, url: url, expiration: nil)
        XCTAssertNotNil(cache.cachedObject(for: url), "Data was not cached")

        // Outside of tests, you should NEVER create a duplicate cache with the same behavior as any existing cache. They will stomp all over each other's data
        guard let cache2 = try? Cache(behavior: behavior) else {
            XCTAssert(false, "Couldn't create the second cache")
            return
        }
        XCTAssertNotNil(cache2.cachedObject(for: url), "Metadata was not successfully saved or loaded")

    }
}
