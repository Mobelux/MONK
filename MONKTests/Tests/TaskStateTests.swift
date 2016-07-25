//
//  TaskStateTests.swift
//  MONK
//
//  Created by Jerry Mayers on 7/13/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class TaskStateTests: XCTestCase {
    
    private let networkController = NetworkController()
    
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
                XCTAssert(false, "Error found: \(error)")
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
        
        waitForExpectations(timeout: 4, handler: nil)
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
        
        waitForExpectations(timeout: 4, handler: nil)
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
