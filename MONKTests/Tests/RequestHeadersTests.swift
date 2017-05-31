//
//  RequestHeadersTests.swift
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

class RequestHeadersTests: XCTestCase {

    private var networkController = NetworkController(serverTrustSettings: nil)
    
    override func tearDown() {
        super.tearDown()
        networkController.cancelAllTasks()
    }
    
    func testAdditionalHeaders() {
        networkController = NetworkController(serverTrustSettings: nil, configuration: URLSessionConfiguration.default, description: "Tests", delegate: nil)
        
        let expectation = self.expectation(description: "Network request")
        let additionalHeaders: [String : String] = ["DummyKey" : "DummyValue"]
        let settings = RequestSettings(additionalHeaders: additionalHeaders, allowsCellularAccess: true, networkServiceType: .default)
        
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
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, _, _):
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
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testAdditionalHeadersOverridingSessionHeaders() {
        networkController = NetworkController(serverTrustSettings: nil, configuration: URLSessionConfiguration.mobeluxDefault, description: "Tests", delegate: nil)
        
        let expectation = self.expectation(description: "Network request")
        let additionalHeaders: [String : String] = ["Accept" : ContentType.plainText.rawValue]
        let settings = RequestSettings(additionalHeaders: additionalHeaders, allowsCellularAccess: true, networkServiceType: .default)
        
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
                XCTAssert(false, "Error found: \(String(describing: error))")
                expectation.fulfill()
            case .success(let statusCode, _, _):
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
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
}
