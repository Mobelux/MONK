//
//  CacheTests.swift
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

import XCTest
@testable import MONK

class CacheTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        Cache.purgableCache.removeAll()
        Cache.persistantCache.removeAll()
    }
    
    private func validateCache(_ cache: Cache, url: URL, data: Data, statusCode: Int) {
        let cachedData = cache.cachedObject(for: url)
        XCTAssertNotNil(cachedData, "No cached data found")
        if let cachedData = cachedData {
            XCTAssert(cachedData.data == data, "Data doesn't match")
            XCTAssert(cachedData.statusCode == statusCode, "Status code doesn't match")
        }
    }

    func testCacheManualPurge() {
        let cache = Cache(behavior: .manualPurgeOrExpirationOnly)

        let string = "Hello world"
        let data = string.data(using: .utf8)!
        let url = URL(string: "http://mobelux.com")!
        let statusCode = 200

        cache.add(object: data, url: url, statusCode: statusCode, expiration: nil)
        validateCache(cache, url: url, data: data, statusCode: statusCode)

        cache.removeObject(for: url)
        XCTAssertNil(cache.cachedObject(for: url), "Data was not purged")

        cache.add(object: data, url: url, statusCode: statusCode, expiration: nil)
        validateCache(cache, url: url, data: data, statusCode: statusCode)

        cache.removeAll()
        XCTAssertNil(cache.cachedObject(for: url), "Data was not purged")
    }

    func testExpiration() {
        let cache = Cache(behavior: .manualPurgeOrExpirationOnly)

        let string = "Hello world"
        let data = string.data(using: .utf8)!
        let url = URL(string: "http://mobelux.com")!
        let statusCode = 200
        let now = Date()

        cache.add(object: data, url: url, statusCode: statusCode, expiration: now)
        XCTAssertNil(cache.cachedObject(for: url), "Data was cached, but shouldn't have been")

        let timeInterval: TimeInterval = 0.25
        let future = Date(timeIntervalSinceNow: timeInterval)
        cache.add(object: data, url: url, statusCode: statusCode, expiration: future)
        XCTAssertNotNil(cache.cachedObject(for: url), "Data was not cached")

        let ex = expectation(description: "Cache expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { 
            XCTAssertNil(cache.cachedObject(for: url), "Data was cached, but have been expired")
            ex.fulfill()
        }
        wait(for: [ex], timeout: 3)
    }

    func testMetaDataSaveLoad() {
        let behavior: CacheBehavior = .manualPurgeOrExpirationOnly

        let cache = Cache(behavior: behavior)

        let string = "Hello world"
        let data = string.data(using: .utf8)!
        let url = URL(string: "http://mobelux.com")!
        let statusCode = 300

        cache.add(object: data, url: url, statusCode: statusCode, expiration: nil)
        validateCache(cache, url: url, data: data, statusCode: statusCode)

        // Outside of tests, you should NEVER create a duplicate cache with the same behavior as any existing cache. They will stomp all over each other's data
        let cache2 = Cache(behavior: behavior)
        validateCache(cache2, url: url, data: data, statusCode: statusCode)

    }
}
