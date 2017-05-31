//
//  DownloadTaskCachingTests.swift
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

class DownloadTaskCachingTests: XCTestCase {

    private let networkController = NetworkController(serverTrustSettings: nil)
    private let sessionController = URLSession.shared
    private let requestedLocalURL = URL(fileURLWithPath: NSTemporaryDirectory() + "image.jpg")

    override func setUp() {
        super.setUp()
        Cache.purgableCache.removeAll()
        Cache.persistantCache.removeAll()
        try? FileManager.default.removeItem(at: requestedLocalURL)
    }

    override func tearDown() {
        super.tearDown()
        Cache.purgableCache.removeAll()
        Cache.persistantCache.removeAll()
        networkController.cancelAllTasks()
        try? FileManager.default.removeItem(at: requestedLocalURL)
    }

    private func runSecondRequest(for request: DownloadRequest, expectation: XCTestExpectation) {
        let task = self.networkController.data(with: request)
        var numberOfCompletionCalls = 0

        task.addCompletion(handler: { (result) in
            numberOfCompletionCalls += 1
        })
        task.resume()

        // We delay this so if the API returns a multiple responses (cached vs non-cached), we can catch that.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            XCTAssert(numberOfCompletionCalls == 1, "We should never get multiple calls on a download task")
            expectation.fulfill()
        })
    }


    func testDownloadTaskCaching() {
        let expectation = self.expectation(description: "Download caching network request")

        let url = URL(string: "https://httpbin.org/image/jpeg")!
        let dummyFileURL = DataHelper.imageURL(for: .compiling)
        try! FileManager.default.copyItem(at: dummyFileURL, to: requestedLocalURL)
        let settings = RequestSettings(cachePolicy: .neverExpires)
        let request = DownloadRequest(url: url, httpMethod: .get, localURL: requestedLocalURL, settings: settings)
        let task = networkController.download(with: request)

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code found")
                self.runSecondRequest(for: request, expectation: expectation)
            }
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

}
