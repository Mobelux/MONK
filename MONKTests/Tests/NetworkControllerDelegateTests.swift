//
//  NetworkControllerDelegateTests.swift
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

class NetworkControllerDelegateTests: XCTestCase {
    
    private lazy var networkController: NetworkController = NetworkController(serverTrustSettings: nil, configuration: URLSessionConfiguration.default, description: "NetworkControllerDelegateTests", delegate: self)
    fileprivate var expectation: XCTestExpectation?
    fileprivate var expectationNumberOfTasks: XCTestExpectation?

    fileprivate var maximumNumberOfTasks: Int = 0
    
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
    func testDelegateDidFinishAllEvents() {
        expectation = self.expectation(description: "Network request")
        
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
            case .success(let statusCode, let responseData, let cached):
                XCTAssert(statusCode == 200, "Invalid status code found")
                XCTAssertNotNil(responseData, "Data was nil")
                switch cached {
                case .notCached:
                    break
                case .fromCache, .updatedCache:
                    XCTAssert(false, "We should not have used the cache")
                }
                let expectedData = DataHelper.data(for: .posts1)
                let expectedJSON = try! expectedData.json()
                let recievedJSON = try? responseData!.json()
                
                XCTAssert(recievedJSON != nil && recievedJSON! == expectedJSON, "Unexpected data found")
                XCTAssert(self.networkController.activeTasksCount == 0, "Tasks still active")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { 
                    let mutableTask = task as! MutableDataTask
                    XCTAssert(mutableTask.completionHandlers.count == 0, "Completion handlers aren't dealocated")
                    XCTAssert(mutableTask.progressHandlers.count == 0, "Progress handlers aren't dealocated")
                })
            }
        }
        
        task.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }

    func testNumberOfTasks() {
        expectationNumberOfTasks = self.expectation(description: "Network request")

        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        task.resume()

        maximumNumberOfTasks = 2
        let task2 = networkController.data(with: request)
        task2.resume()
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
}

extension NetworkControllerDelegateTests: NetworkControllerDelegate {
    func networkControllerDidFinishAllEvents(networkController: NetworkController) {
        expectationNumberOfTasks?.fulfill()
    }
    
    func networkController(networkController: NetworkController, task: Task, didFinishCollecting metrics: URLSessionTaskMetrics) {
        print(metrics)
        expectation?.fulfill()
    }

    func networkController(networkController: NetworkController, didChangeNumberOfActiveTasksTo numberOfActiveTasks: Int) {
        guard let expectationNumberOfTasks = expectationNumberOfTasks else { return }
        XCTAssert(numberOfActiveTasks <= maximumNumberOfTasks, "Number of tasks doesn't match expected")
        if numberOfActiveTasks == 0 {
            expectationNumberOfTasks.fulfill()
        }
    }
}
