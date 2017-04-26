//
//  DownloadTaskCachingTests.swift
//  MONK
//
//  Created by Jerry Mayers on 4/25/17.
//  Copyright © 2017 Mobelux. All rights reserved.
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
