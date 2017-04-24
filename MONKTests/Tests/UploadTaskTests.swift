//
//  UploadTaskTests.swift
//  MONK
//
//  Created by Jerry Mayers on 7/11/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class UploadTaskTests: XCTestCase {

    private let networkController = NetworkController(serverTrustSettings: nil)
    
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
    func testUploadJSONTask() {
        let expectation = self.expectation(description: "Network request")
        
        let url = URL(string: "http://httpbin.org/post")!
        let json = try! DataHelper.data(for: .posts1).json()
        let dataToUpload = UploadableData.json(json: json)
        XCTAssertFalse(dataToUpload.isMultiPart, "Multipart data was not expected")
        
        let request = DataRequest(url: url, httpMethod: .post(bodyData: dataToUpload))
        let task = networkController.data(with: request)
        
        var downloadProgressCalled = false
        var uploadProgressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                guard let responseJSON = try? responseData!.json() else { expectation.fulfill(); return }
                let responseWhatWePosted = responseJSON["json"]
                XCTAssertNotNil(responseWhatWePosted, "The JSON we posted is missing")
                XCTAssert((responseWhatWePosted as! JSON) == json, "The JSON we posted is not what we got back")

                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")
                
                XCTAssert(downloadProgressCalled, "Download progress was never called")
                XCTAssert(uploadProgressCalled, "Upload progress was never called")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { 
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    XCTAssert(mutableTask.uploadProgressHandlers.count == 0, "Progress handlers aren't dealocated")
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
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            downloadProgressCalled = true
        }
        
        task.addUploadProgress { (progress) in
            XCTAssertNotNil(task.uploadProgress, "Upload progress wasn't set")
            XCTAssert(progress.totalBytes == task.uploadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.uploadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.uploadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            uploadProgressCalled = true
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

    func testPUTUploadJSONTask() {
        let expectation = self.expectation(description: "Network request")

        let url = URL(string: "http://httpbin.org/put")!
        let json = try! DataHelper.data(for: .posts1).json()
        let dataToUpload = UploadableData.json(json: json)
        XCTAssertFalse(dataToUpload.isMultiPart, "Multipart data was not expected")

        let request = DataRequest(url: url, httpMethod: .put(bodyData: dataToUpload))
        let task = networkController.data(with: request)

        var downloadProgressCalled = false
        var uploadProgressCalled = false

        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                guard let responseJSON = try? responseData!.json() else { expectation.fulfill(); return }
                let responseWhatWePosted = responseJSON["json"]
                XCTAssertNotNil(responseWhatWePosted, "The JSON we posted is missing")
                XCTAssert((responseWhatWePosted as! JSON) == json, "The JSON we posted is not what we got back")

                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")

                XCTAssert(downloadProgressCalled, "Download progress was never called")
                XCTAssert(uploadProgressCalled, "Upload progress was never called")

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    XCTAssert(mutableTask.uploadProgressHandlers.count == 0, "Progress handlers aren't dealocated")
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
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            downloadProgressCalled = true
        }

        task.addUploadProgress { (progress) in
            XCTAssertNotNil(task.uploadProgress, "Upload progress wasn't set")
            XCTAssert(progress.totalBytes == task.uploadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.uploadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.uploadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            uploadProgressCalled = true
        }

        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUploadImageFromURLTask() {
        let expectation = self.expectation(description: "Network request")
        
        let imageURL = DataHelper.imageURL(for: .compiling)
        let file = UploadableData.FileData.init(name: "imageFile", fileName: "compiling.png", mimeType: ContentType.png, data: .file(url: imageURL))
        let dataToUpload = UploadableData.files(files: [file])
        
        let url = URL(string: "http://httpbin.org/post")!
        
        let request = DataRequest(url: url, httpMethod: .post(bodyData: dataToUpload))
        let task = networkController.data(with: request)
        
        var downloadProgressCalled = false
        var uploadProgressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                guard let responseJSON = try? responseData!.json() else { expectation.fulfill(); return }
                
                XCTAssert(FileValidator.validate(files: [file], response: responseJSON), "Uploaded files don't match recieved files")
                
                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")
                
                XCTAssert(downloadProgressCalled, "Download progress was never called")
                XCTAssert(uploadProgressCalled, "Upload progress was never called")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    XCTAssert(mutableTask.uploadProgressHandlers.count == 0, "Progress handlers aren't dealocated")
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
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            downloadProgressCalled = true
        }
        
        task.addUploadProgress { (progress) in
            XCTAssertNotNil(task.uploadProgress, "Upload progress wasn't set")
            XCTAssert(progress.totalBytes == task.uploadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.uploadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.uploadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            uploadProgressCalled = true
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUploadJSONAndImageFromURLTask() {
        let expectation = self.expectation(description: "Network request")
        
        let json = try! DataHelper.data(for: .posts1).json()
        let imageURL = DataHelper.imageURL(for: .compiling)
        let file = UploadableData.FileData.init(name: "imageFile", fileName: "compiling.png", mimeType: ContentType.png, data: .file(url: imageURL))
        let dataToUpload = UploadableData.jsonAndFiles(json: json, files: [file])
        
        let url = URL(string: "http://httpbin.org/post")!
        
        let request = DataRequest(url: url, httpMethod: .post(bodyData: dataToUpload))
        let task = networkController.data(with: request)
        
        var downloadProgressCalled = false
        var uploadProgressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                guard let responseJSON = try? responseData!.json() else { expectation.fulfill(); return }
                let responseWhatWePosted = responseJSON["form"] as? JSON
                XCTAssertNotNil(responseWhatWePosted, "The JSON we posted is missing")
                XCTAssert(responseWhatWePosted!.keys.elementsEqual(json.keys), "The JSON we posted is not what we got back")
                
                XCTAssert(FileValidator.validate(files: [file], response: responseJSON), "Uploaded files don't match recieved files")
                
                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")
                
                XCTAssert(downloadProgressCalled, "Download progress was never called")
                XCTAssert(uploadProgressCalled, "Upload progress was never called")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    XCTAssert(mutableTask.uploadProgressHandlers.count == 0, "Progress handlers aren't dealocated")
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
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            downloadProgressCalled = true
        }
        
        task.addUploadProgress { (progress) in
            XCTAssertNotNil(task.uploadProgress, "Upload progress wasn't set")
            XCTAssert(progress.totalBytes == task.uploadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.uploadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.uploadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            uploadProgressCalled = true
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUploadJSONAndImageFromDataTask() {
        let expectation = self.expectation(description: "Network request")
        
        let json = try! DataHelper.data(for: .posts1).json()
        let imageData = DataHelper.imageData(for: .compiling)
        let file = UploadableData.FileData.init(name: "imageFile", fileName: "compiling.png", mimeType: ContentType.png, data: .data(data: imageData))
        let dataToUpload = UploadableData.jsonAndFiles(json: json, files: [file])
        XCTAssert(dataToUpload.isMultiPart, "Multipart data expected")
        
        let url = URL(string: "http://httpbin.org/post")!
        
        let request = DataRequest(url: url, httpMethod: .post(bodyData: dataToUpload))
        let task = networkController.data(with: request)
        
        var downloadProgressCalled = false
        var uploadProgressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                guard let responseJSON = try? responseData!.json() else { expectation.fulfill(); return }
                let responseWhatWePosted = responseJSON["form"] as? JSON
                XCTAssertNotNil(responseWhatWePosted, "The JSON we posted is missing")
                XCTAssert(responseWhatWePosted!.keys.elementsEqual(json.keys), "The JSON we posted is not what we got back")
                
                XCTAssert(FileValidator.validate(files: [file], response: responseJSON), "Uploaded files don't match recieved files")
                
                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")
                
                XCTAssert(downloadProgressCalled, "Download progress was never called")
                XCTAssert(uploadProgressCalled, "Upload progress was never called")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    XCTAssert(mutableTask.uploadProgressHandlers.count == 0, "Progress handlers aren't dealocated")
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
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            downloadProgressCalled = true
        }
        
        task.addUploadProgress { (progress) in
            XCTAssertNotNil(task.uploadProgress, "Upload progress wasn't set")
            XCTAssert(progress.totalBytes == task.uploadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.uploadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.uploadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            uploadProgressCalled = true
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUploadImageFromRawData() {
        let expectation = self.expectation(description: "Network request")
        
        let imageData = DataHelper.imageData(for: .compiling)
        let dataToUpload = UploadableData.data(data: imageData, contentType: ContentType.png)
        
        let url = URL(string: "http://httpbin.org/post")!
        
        let request = DataRequest(url: url, httpMethod: .post(bodyData: dataToUpload))
        let task = networkController.data(with: request)
        
        var downloadProgressCalled = false
        var uploadProgressCalled = false
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                guard let responseJSON = try? responseData!.json() else { expectation.fulfill(); return }
                
                XCTAssert(FileValidator.validate(uploadedData: dataToUpload, response: responseJSON), "Uploaded data don't match recieved data")
                
                XCTAssert(downloadProgressCalled, "Download progress was never called")
                XCTAssert(uploadProgressCalled, "Upload progress was never called")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { 
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                    XCTAssert(mutableTask.uploadProgressHandlers.count == 0, "Progress handlers aren't dealocated")
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
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            downloadProgressCalled = true
        }
        
        task.addUploadProgress { (progress) in
            XCTAssertNotNil(task.uploadProgress, "Upload progress wasn't set")
            XCTAssert(progress.totalBytes == task.uploadProgress!.totalBytes, "Total bytes don't match")
            XCTAssert(progress.completeBytes == task.uploadProgress!.completeBytes, "Complete bytes don't match")
            XCTAssert(progress.progress == task.uploadProgress!.progress, "Progresses don't match")
            XCTAssertNotNil(progress.progress, "Progress was nil")
            XCTAssert(progress.totalBytes >= progress.completeBytes, "Total bytes should always be more then complete bytes")
            uploadProgressCalled = true
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
}
