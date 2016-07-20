//
//  NetworkControllerDelegateTests.swift
//  MONK
//
//  Created by Jerry Mayers on 7/6/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class NetworkControllerDelegateTests: XCTestCase {
    
    private lazy var networkController: NetworkController = {
        let sessionDelegate = NetworkSessionDelegate(delegate: self)
        let mockSession = URLSession(configuration: URLSessionConfiguration.default, delegate: sessionDelegate, delegateQueue: sessionDelegate.operationQueue)
        
        //let controller = NetworkController(configuration: URLSessionConfiguration.default, description: "NetworkControllerDelegateTests", delegate: self, sessionProtocol: mockSession)
        
        let controller = NetworkController(sessionProtocol: mockSession, sessionDelegate: sessionDelegate)
        
        return controller
    }()
    
    
    private var expectation: XCTestExpectation?
    
//    private var mockSession = URLSession()//MockSession
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
//    override init() {
//        super.init()
//
//        let sessionDelegate = NetworkSessionDelegate(delegate: self)
//        mockSession = URLSession(configuration: URLSessionConfiguration.default, delegate: sessionDelegate, delegateQueue: sessionDelegate.operationQueue)
//
//    }
    
    func testDelegateDidFinishAllEvents() {
        expectation = self.expectation(withDescription: "Network request")
        
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(error)")
            case .success(let statusCode, let responseData):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                let expectedData = DataHelper.data(for: .posts1)
                let expectedJSON = try! expectedData.json()
                let recievedJSON = try? responseData!.json()
                
                XCTAssert(recievedJSON != nil && recievedJSON! == expectedJSON, "Unexpected data found")
                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")
                
                DispatchQueue.main.after(when: DispatchTime.now() + 0.1, execute: {
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                })
            }
        }
        
        task.resume()
        waitForExpectations(withTimeout: 20, handler: nil)
    }
}

extension NetworkControllerDelegateTests: NetworkControllerDelegate {
    func networkControllerDidFinishAllEvents(networkController: NetworkController) {
        expectation?.fulfill()
    }
    
    func networkController(networkController: NetworkController, task: Task, didFinishCollecting metrics: URLSessionTaskMetrics) {
        print(metrics)
        expectation?.fulfill()
    }
}
