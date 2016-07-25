//
//  RequestHeadersTests.swift
//  MONK
//
//  Created by Jerry Mayers on 7/11/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class RequestHeadersTests: XCTestCase {

    private var networkController = NetworkController()
    
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
    func testAdditionalHeaders() {
        networkController = NetworkController(configuration: URLSessionConfiguration.default, description: "Tests", delegate: nil)
        
        let expectation = self.expectation(description: "Network request")
        let additionalHeaders: [String : String] = ["DummyKey" : "DummyValue"]
        let settings = RequestSettings(additionalHeaders: additionalHeaders, allowsCellularAccess: true, networkServiceType: .default, cachePolicy: .useProtocolCachePolicy)
        
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let task = networkController.data(with: request)
        
        let requestHeaders = task.dataTask.currentRequest?.allHTTPHeaderFields
        XCTAssertNotNil(requestHeaders, "Headers shouldn't be nil")
        if let requestHeaders = requestHeaders {
            // Before a task is started the `requestHeaders` will only contain the `additionalHeaders`, any any session specific headers.
            XCTAssert(requestHeaders == additionalHeaders, "Headers not equal")
        }
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(error)")
                expectation.fulfill()
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code found")
                
                let requestHeaders = task.dataTask.currentRequest?.allHTTPHeaderFields
                XCTAssertNotNil(requestHeaders, "Headers shouldn't be nil")
                if let requestHeaders = requestHeaders {
                    // After a task is started the `requestHeaders` will contain the `additionalHeaders` plus any headers configured on the `NetworkController` as controller defaults.
                    XCTAssert(requestHeaders != additionalHeaders, "Headers not equal")
                    for (key, value) in additionalHeaders {
                        XCTAssert(requestHeaders[key] == value, "Headers doesn't contain additionalHeaders")
                    }
                }
                
                expectation.fulfill()
            }
        }
        
        task.resume()
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testAdditionalHeadersOverridingSessionHeaders() {
        networkController = NetworkController(configuration: URLSessionConfiguration.mobeluxDefault, description: "Tests", delegate: nil)
        
        let expectation = self.expectation(description: "Network request")
        let additionalHeaders: [String : String] = ["Accept" : ContentType.plainText.rawValue]
        let settings = RequestSettings(additionalHeaders: additionalHeaders, allowsCellularAccess: true, networkServiceType: .default, cachePolicy: .useProtocolCachePolicy)
        
        let url = URL(string: "http://jsonplaceholder.typicode.com/posts/1")!
        let request = DataRequest(url: url, httpMethod: .get, settings: settings)
        let task = networkController.data(with: request)
        
        let requestHeaders = task.dataTask.currentRequest?.allHTTPHeaderFields
        XCTAssertNotNil(requestHeaders, "Headers shouldn't be nil")
        if let requestHeaders = requestHeaders {
            for (key, value) in additionalHeaders {
                XCTAssert(requestHeaders[key] == value, "Headers doesn't contain additionalHeaders")
            }
        }
        
        task.addCompletion { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(false, "Error found: \(error)")
                expectation.fulfill()
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code found")
                
                let requestHeaders = task.dataTask.currentRequest?.allHTTPHeaderFields
                XCTAssertNotNil(requestHeaders, "Headers shouldn't be nil")
                if let requestHeaders = requestHeaders {
                    // After a task is started the `requestHeaders` will contain the `additionalHeaders` plus any headers configured on the `NetworkController` as controller defaults
                    XCTAssert(requestHeaders != additionalHeaders, "Headers not equal")
                    for (key, value) in additionalHeaders {
                        XCTAssert(requestHeaders[key] == value, "Headers doesn't contain additionalHeaders")
                    }
                }
                
                expectation.fulfill()
            }
        }
        
        task.resume()
        waitForExpectations(timeout: 4, handler: nil)
    }
}
