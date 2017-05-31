//
//  TaskStateTests.swift
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

class TaskStateTests: XCTestCase {
    
    private let networkController = NetworkController(serverTrustSettings: nil)
    
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
    func testSuccessfulTaskState() {
        let expectation = self.expectation(description: "Network request")
        
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        if case .waiting = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't waiting")
        }
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success:
                if case .completed = task.state {
                    
                } else {
                    XCTAssert(false, "Task wasn't completed")
                }
                
                expectation.fulfill()
            }
        }
        
        task.resume()

        if case .running = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't running")
        }
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testCanceledTaskState() {
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        if case .waiting = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't waiting")
        }
        
        task.resume()
        
        if case .running = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't running")
        }
        
        task.cancel()
        
        if case .cancelled = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't cancelled")
        }
    }
    
    func testFailedTaskState() {
        let expectation = self.expectation(description: "Network request")
        
        let url = URL(string: "http://someInvalidURLToNonexistantHost.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        if case .waiting = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't waiting")
        }
        
        task.addCompletion { (result) in
            switch result {
            case .failure:
                if case .failed = task.state {
                    
                } else {
                    XCTAssert(false, "Task wasn't failed, even though it didn't succeed")
                }
                
                expectation.fulfill()
            case .success:
                XCTAssert(false, "Task completed, but we expected a failure")
                
                if case .completed = task.state {
                    
                } else {
                   XCTAssert(false, "Task wasn't completed")
                }
                
                expectation.fulfill()
            }
        }
        
        task.resume()
        
        if case .running = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't running")
        }
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testSuspendedTaskState() {
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        if case .waiting = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't waiting")
        }
        
        task.resume()
        
        if case .running = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't running")
        }
        
        task.suspend()
        
        if case .waiting = task.state {
            
        } else {
            XCTAssert(false, "Task wasn't suspended")
        }
    }
}
