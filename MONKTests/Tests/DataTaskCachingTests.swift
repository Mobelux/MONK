//
//  DataTaskCachingTests.swift
//  MONK
//
//  Created by Jerry Mayers on 4/25/17.
//  Copyright © 2017 Mobelux. All rights reserved.
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
                case .notFromCache:
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
                case .notFromCache:
                    if let responseData = responseData {
                        self.validateCache(task.cache, url: url, data: responseData, statusCode: statusCode)
                    } else {
                        XCTAssert(false, "Did not get valid data")
                    }

                    self.runCacheHit(for: request, expectation: expectation)
                case .fromCache:
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
                case .notFromCache:
                    XCTAssertNotNil(responseData, "If data is nil, it couldn't be updated")
                    update = true
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
                case .notFromCache:
                    if let responseData = responseData {
                        self.validateCache(task.cache, url: url, data: responseData, statusCode: statusCode)
                    } else {
                        XCTAssert(false, "Did not get valid data")
                    }

                    self.runCacheHitThenUpdate(for: request, expectation: expectation)
                case .fromCache:
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
                case .notFromCache:
                    if responseData != nil {
                        let cachedData = task.cache.cachedObject(for: url)
                        XCTAssertNil(cachedData, "POST data shouldn't be cached")
                    } else {
                        XCTAssert(false, "Did not get valid data")
                    }
                case .fromCache:
                    XCTAssert(false, "We should not have a cache hit on a POST")
                }
                expectation.fulfill()
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
}
