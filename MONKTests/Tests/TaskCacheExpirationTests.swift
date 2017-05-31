//
//  TaskCacheExpirationTests.swift
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

class TaskCacheExpirationTests: XCTestCase {

    private let networkController = NetworkController(serverTrustSettings: nil)
    private let sessionController = URLSession.shared

    override func tearDown() {
        super.tearDown()
        Cache.purgableCache.removeAll()
        Cache.persistantCache.removeAll()
        networkController.cancelAllTasks()
    }

    private func createTask(with settings: RequestSettings) -> MutableDataTask {
        let cache = Cache(behavior: .purgeOnLowDiskSpace)
        let url = URL(string: "http://mobelux.com")!
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let urlTask = URLSessionDataTask()
        let task = MutableDataTask(request: request, task: urlTask, cache: cache)
        return task
    }

    func testExpireAt() {
        let expiresAt = Date(timeIntervalSince1970: 0)
        let settings = RequestSettings(cachePolicy: .expireAt(expiresAt))
        let task = createTask(with: settings)
        let cacheExpiration = task.cacheExpiration()
        XCTAssertNotNil(cacheExpiration, "We should have a valid expiration")
        if let cacheExpiration = cacheExpiration {
            XCTAssert(cacheExpiration == expiresAt, "Expiration date is not what we told it to be")
        }
    }

    func testNeverExpires() {
        let settings = RequestSettings(cachePolicy: .neverExpires)
        let task = createTask(with: settings)
        XCTAssertNil(task.cacheExpiration(), "We should not have an expiration date")
    }

    func testNoCaching() {
        let settings = RequestSettings(cachePolicy: .noAdditionalCaching(.useProtocolCachePolicy))
        let task = createTask(with: settings)
        XCTAssertNil(task.cacheExpiration(), "We should not have an expiration date")
    }

    func testHeaderExpirationNoCacheResponse() {
        let expectation = self.expectation(description: "Network request")

        let settings = RequestSettings(cachePolicy: .headerExpiration)
        let url = URL(string: "http://mobelux.com")!
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let task = networkController.data(with: request)
        XCTAssertNil(task.cacheExpiration(), "We should not have an expiration date yet as the task hasn't finished")

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData, let cached):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                switch cached {
                case .notCached, .updatedCache:
                    XCTAssertNil(task.cacheExpiration(), "Server should respond with `no-cache`, so we wouldn't have an expiration")
                case .fromCache:
                    XCTAssertNil(task.cacheExpiration(), "We should not have an expiration date yet as the task hasn't finished")
                }

                expectation.fulfill()
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

    func testHeaderExpirationCacheResponse() {
        let expectation = self.expectation(description: "Network request")

        let settings = RequestSettings(cachePolicy: .headerExpiration)
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let task = networkController.data(with: request)
        XCTAssertNil(task.cacheExpiration(), "We should not have an expiration date yet as the task hasn't finished")

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData, let cached):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                switch cached {
                case .notCached, .updatedCache:
                    XCTAssertNotNil(task.cacheExpiration(), "We should have an expiration date now")
                case .fromCache:
                    XCTAssertNil(task.cacheExpiration(), "We should not have an expiration date yet as the task hasn't finished")
                }

                expectation.fulfill()
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

    func testMaxAgeParsing() {
        let maxAge: TimeInterval? = 14400

        let string0 = "public, max-age=\(maxAge!)"
        let string1 = "max-age=\(maxAge!)"
        let string2 = "s-maxage=\(maxAge!)"
        let string3 = "public, s-maxage=\(maxAge!)"
        let string4 = "max-age=\(maxAge!), public"
        let string5 = "s-maxage=\(maxAge!), public"

        let age0 = string0.parseMaxCacheAge()
        let age1 = string1.parseMaxCacheAge()
        let age2 = string2.parseMaxCacheAge()
        let age3 = string3.parseMaxCacheAge()
        let age4 = string4.parseMaxCacheAge()
        let age5 = string5.parseMaxCacheAge()

        XCTAssertNotNil(age0, "Max age not found")
        XCTAssertNotNil(age1, "Max age not found")
        XCTAssertNotNil(age2, "Max age not found")
        XCTAssertNotNil(age3, "Max age not found")
        XCTAssertNotNil(age4, "Max age not found")
        XCTAssertNotNil(age5, "Max age not found")

        XCTAssert(age0 == maxAge, "Age doesn't match")
        XCTAssert(age1 == maxAge, "Age doesn't match")
        XCTAssert(age2 == maxAge, "Age doesn't match")
        XCTAssert(age3 == maxAge, "Age doesn't match")
        XCTAssert(age4 == maxAge, "Age doesn't match")
        XCTAssert(age5 == maxAge, "Age doesn't match")
    }
}
