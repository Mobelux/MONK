//
//  DataTaskCachingTests.swift
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

class DataTaskCachingTests: XCTestCase {

    private let networkController = NetworkController(serverTrustSettings: nil)
    private let sessionController = URLSession.shared

    override func setUp() {
        super.setUp()
        Cache.purgableCache.removeAll()
        Cache.persistantCache.removeAll()
    }

    override func tearDown() {
        super.tearDown()
        Cache.purgableCache.removeAll()
        Cache.persistantCache.removeAll()
        networkController.cancelAllTasks()
    }

    private func validateCache(_ cache: Cache, url: URL, data: Data, statusCode: Int) {
        let cachedData = cache.cachedObject(for: url)
        XCTAssertNotNil(cachedData, "No cached data found")
        if let cachedData = cachedData {
            XCTAssert(cachedData.data == data, "Data doesn't match")
            XCTAssert(cachedData.statusCode == statusCode, "Status code doesn't match")
        }
    }

    private func runCacheHit(for request: DataRequest, expectation: XCTestExpectation) {
        let task = self.networkController.data(with: request)
        task.addCompletion(handler: { (result) in
            switch result {
            case .success(_, let responseData, let cached):
                switch cached {
                case .fromCache:
                    XCTAssertNotNil(responseData, "If data is nil, it couldn't be cached")
                case .notCached, .updatedCache:
                    XCTAssert(false, "Cache miss")
                }
            case .failure(error: let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
            }
        })
        task.resume()

        // We delay this so if the API returns a different response then the cached one, the test hasn't finished yet, and we can catch that as a failure (since this test doesn't expect that. Others do.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            expectation.fulfill()
        })
    }

    func testCacheNeverExpire() {
        let expectation = self.expectation(description: "cache hit network request")

        let settings = RequestSettings(cachePolicy: .neverExpires)
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let task = networkController.data(with: request)

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData, let cached):
                switch cached {
                case .notCached:
                    if let responseData = responseData {
                        self.validateCache(task.cache, url: url, data: responseData, statusCode: statusCode)
                    } else {
                        XCTAssert(false, "Did not get valid data")
                    }

                    self.runCacheHit(for: request, expectation: expectation)
                case .fromCache, .updatedCache:
                    XCTAssert(false, "We should not have a cache hit on the first try")
                    expectation.fulfill()
                }
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

    private func runCacheHitThenUpdate(for request: DataRequest, expectation: XCTestExpectation) {
        let task = self.networkController.data(with: request)
        var completionCalls = 0
        var cacheHit = false
        var update = false

        task.addCompletion(handler: { (result) in
            completionCalls += 1
            switch result {
            case .success(_, let responseData, let cached):
                switch cached {
                case .fromCache:
                    XCTAssertNotNil(responseData, "If data is nil, it couldn't be cached")
                    cacheHit = true
                case .updatedCache:
                    XCTAssertNotNil(responseData, "If data is nil, it couldn't be updated")
                    update = true
                case .notCached:
                    XCTAssert(false, "On the 2nd request, we should never get a not cached response")
                }
            case .failure(error: let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
            }
        })
        task.resume()

        // We delay this so if the API returns a different response then the cached one, the test hasn't finished yet, and we can catch that as a failure (since this test doesn't expect that. Others do.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            XCTAssert(completionCalls == 2, "An incorrect number of completion calls occured")
            XCTAssert(cacheHit, "Never loaded from the cache")
            XCTAssert(update, "Response never updated")
            expectation.fulfill()
        })
    }

    func testCacheHitButUpdated() {
        // This site returns the current time in the specified time zone. This way this test will cache data, but our second task will be called twice (cache hit, and updated data from API)

        let expectation = self.expectation(description: "cache hit & update network request")
        let url = URL(string: "http://www.unixtimestamp.com")!
        let settings = RequestSettings(cachePolicy: .neverExpires)
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let task = networkController.data(with: request)

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData, let cached):
                switch cached {
                case .notCached:
                    if let responseData = responseData {
                        self.validateCache(task.cache, url: url, data: responseData, statusCode: statusCode)
                    } else {
                        XCTAssert(false, "Did not get valid data")
                    }

                    self.runCacheHitThenUpdate(for: request, expectation: expectation)
                case .fromCache, .updatedCache:
                    XCTAssert(false, "We should not have a cache hit on the first try")
                    expectation.fulfill()
                }
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

    func testCacheNotUsedForPost() {
        let expectation = self.expectation(description: "cache not used for post network request")

        let settings = RequestSettings(cachePolicy: .neverExpires)
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts")!
        let data = UploadableData.json(json: ["hello" as NSString : "world" as NSString])
        let method: HTTPMethod = .post(bodyData: data)
        let request = DataRequest(url: url, httpMethod: method, settings: settings)
        let task = networkController.data(with: request)

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(_, let responseData, let cached):
                switch cached {
                case .notCached:
                    if responseData != nil {
                        let cachedData = task.cache.cachedObject(for: url)
                        XCTAssertNil(cachedData, "POST data shouldn't be cached")
                    } else {
                        XCTAssert(false, "Did not get valid data")
                    }
                case .fromCache, .updatedCache:
                    XCTAssert(false, "We should not have a cache hit on a POST")
                }
                expectation.fulfill()
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
}
