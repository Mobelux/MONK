//
//  DownloadTaskTests.swift
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

class DownloadTaskTests: XCTestCase {
    
    private let networkController = NetworkController(serverTrustSettings: nil)
    private let requestedLocalURL = URL(fileURLWithPath: NSTemporaryDirectory() + "image.jpg")

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: requestedLocalURL)
    }

    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
        try? FileManager.default.removeItem(at: requestedLocalURL)
    }
    
    func testDownloadTaskProgress() {
        let expectation = self.expectation(description: "Download network request")
        
        let url = URL(string: "https://httpbin.org/image/jpeg")!
        let requestedLocalURL = URL(fileURLWithPath: NSTemporaryDirectory() + "image.jpg")
        let _ = try? FileManager.default.removeItem(at: requestedLocalURL)
        let dummyFileURL = DataHelper.imageURL(for: .compiling)
        try! FileManager.default.copyItem(at: dummyFileURL, to: requestedLocalURL)
        
        let request = DownloadRequest(url: url, httpMethod: .get, localURL: requestedLocalURL)
        let task = networkController.download(with: request)
        
        XCTAssert(task.downloadRequest.url == task.request.url, "Download request not the same as the regular request")
        var progressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let localURL):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssert(localURL == requestedLocalURL, "File not saved to URL we requested")
                let fileExists = FileManager.default.fileExists(atPath: localURL.path)
                XCTAssert(fileExists, "File doesn't exist")
                XCTAssert(progressCalled, "Progress was never called")
                let image = CIImage(contentsOf: localURL)
                XCTAssertNotNil(image, "Image didn't load successfully")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                    let mutableTask = task as! MutableDownloadTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    let _ = try? FileManager.default.removeItem(at: requestedLocalURL)
                    expectation.fulfill()
                })
            }
        }
        
        task.addProgress { (progress) in
            XCTAssertNotNil(task.downloadProgress, "Download progress wasn't set")
            XCTAssert(progress.totalBytes == task.downloadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.downloadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.downloadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.progress! >= 0, "Progress % is less then 0")
            XCTAssert(progress.progress! <= 1, "Progress % is greater then 1")
            progressCalled = true
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testDownloadTaskCancellation() {
        let url = URL(string: "https://httpbin.org/image/jpeg")!
        let dummyFileURL = DataHelper.imageURL(for: .compiling)
        try! FileManager.default.copyItem(at: dummyFileURL, to: requestedLocalURL)
        
        let request = DownloadRequest(url: url, httpMethod: .get, localURL: requestedLocalURL)
        let task = networkController.download(with: request)
    
        XCTAssert(FileManager.default.fileExists(atPath: requestedLocalURL.path), "Dummy file isn't at requestedLocalURL")
        task.resume()
        task.cancel()
        XCTAssertFalse(FileManager.default.fileExists(atPath: requestedLocalURL.path), "File at requestedLocalURL wasn't cleaned up")
    }
}
