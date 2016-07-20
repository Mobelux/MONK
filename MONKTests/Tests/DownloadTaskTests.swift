//
//  DownloadTaskTests.swift
//  MONK
//
//  Created by Jerry Mayers on 7/6/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class DownloadTaskTests: XCTestCase {
    
    private let networkController = NetworkController()
    
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
    func testDownloadTaskProgress() {
        let expectation = self.expectation(withDescription: "Download network request")
        
        let url = URL(string: "https://httpbin.org/image/jpeg")!
        let requestedLocalURL = URL(fileURLWithPath: NSTemporaryDirectory() + "image.jpg")
        
        let dummyFileURL = DataHelper.imageURL(for: .compiling)
        try! FileManager.default.copyItem(at: dummyFileURL, to: requestedLocalURL)
        
        let request = DownloadRequest(url: url, httpMethod: .get, localURL: requestedLocalURL)
        let task = networkController.download(with: request)
        
        XCTAssert(task.downloadRequest.url == task.request.url, "Download request not the same as the regular request")
        var progressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(error)")
                expectation.fulfill()
            case .success(let statusCode, let localURL):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssert(localURL == requestedLocalURL, "File not saved to URL we requested")
                let fileExists = FileManager.default.fileExists(atPath: localURL.path!)
                XCTAssert(fileExists, "File doesn't exist")
                XCTAssert(progressCalled, "Progress was never called")
                
                let image = UIImage(contentsOfFile: localURL.path!)
                XCTAssertNotNil(image, "Image didn't load successfully")
                
                DispatchQueue.main.after(when: DispatchTime.now() + 0.1, execute: {
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
            XCTAssert(progress.progress >= 0, "Progress % is less then 0")
            XCTAssert(progress.progress <= 1, "Progress % is greater then 1")
            progressCalled = true
        }
        
        task.resume()
        waitForExpectations(withTimeout: 4, handler: nil)
    }
    
    func testDownloadTaskCancellation() {
        let url = URL(string: "https://httpbin.org/image/jpeg")!
        let requestedLocalURL = URL(fileURLWithPath: NSTemporaryDirectory() + "image.jpg")
        let dummyFileURL = DataHelper.imageURL(for: .compiling)
        try! FileManager.default.copyItem(at: dummyFileURL, to: requestedLocalURL)
        
        let request = DownloadRequest(url: url, httpMethod: .get, localURL: requestedLocalURL)
        let task = networkController.download(with: request)
    
        XCTAssert(FileManager.default.fileExists(atPath: requestedLocalURL.path!), "Dummy file isn't at requestedLocalURL")
        task.resume()
        task.cancel()
        XCTAssertFalse(FileManager.default.fileExists(atPath: requestedLocalURL.path!), "File at requestedLocalURL wasn't cleaned up")
    }
}
