//
//  DataHelper.swift
//  MONK
//
//  Created by Jerry Mayers on 7/5/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation
@testable import MONK

enum DataJSON: String {
    case posts1 = "posts1"
    case photos = "photos"
}

enum DataImage: String {
    case compiling = "compiling"
}

private class Dummy { }

struct DataHelper {
    static func data(for json: DataJSON) -> Data {
        let bundle = Bundle(for: Dummy.self)
        let url = bundle.urlForResource(json.rawValue, withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return data
    }
    
    static func imageURL(for image: DataImage) -> URL {
        let bundle = Bundle(for: Dummy.self)
        let url = bundle.urlForResource(image.rawValue, withExtension: "png")
        return url!
    }
    
    static func imageData(for image: DataImage) -> Data {
        let url = imageURL(for: image)
        return try! Data(contentsOf: url)
    }
}

extension Data {
    var jsonString: String {
        return String(data: self, encoding: .utf8)!
    }
}

func ==(lhs: JSON, rhs: JSON) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

public class MockSession : URLSessionProtocol {
    public var sessionDescription: String? = "com.mocksession.network_controller"
    
    public var delegate: URLSessionDelegate? 
    
    public func invalidateAndCancel() {
        
    }
    
    init(sessionDelegate: NetworkSessionDelegate) {
        self.delegate = sessionDelegate
    }
    
    public func dataTask(with request: Request) -> URLSessionDataTaskProtocol {
        let mockSessionDataTask = MockDataTask()
        
        return mockSessionDataTask
    }
    
    public func downloadTask(with request: DownloadRequestType) -> URLSessionDownloadTaskProtocol {
        let mockSessionDownloadTask = MockDownloadTask()
        return mockSessionDownloadTask
    }
    
    private func resumeTask(mockDataTask: MockDataTask){
        guard let dataToReceive = mockDataTask.dataToReceive, let delegate = delegate as? NetworkSessionDelegate else {
            mockDataTask.state = .completed
            mockDataTask.error = NSError(domain: "shooot", code: 1, userInfo: nil)
            return
        }
        
        mockDataTask.state = .running
        let numChunks = 3
        let chunkSize = dataToReceive.count / numChunks
        
        for byteIndex in stride(from: 0, to: dataToReceive.count, by: chunkSize) {
            let rangeEnd = max(byteIndex + chunkSize, dataToReceive.count)
            let range = byteIndex ..< rangeEnd as Range
            let chunk = dataToReceive.subdata(in: range)
            
            
            delegate.urlSession(self, dataTask: mockDataTask, didReceive: chunk)
        }
        
        mockDataTask.response = HTTPURLResponse(url: mockDataTask.currentRequest!.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        
        delegate.urlSession(self, task: mockDataTask, didCompleteWithError: nil)
    }
}

public class MockDataTask: URLSessionDataTaskProtocol {
    init() {
        countOfBytesReceived = 1
        countOfBytesExpectedToReceive = 1
        currentRequest = URLRequest(url: URL(string: "http://mobelux.com/datatask")!)
        state = .suspended
        taskIdentifier = 1
    }
    
    private var session: MockSession?
    
    public var response: URLResponse?
    
    public var countOfBytesExpectedToReceive: Int64
    public var countOfBytesReceived: Int64
    public var currentRequest: URLRequest?
    public var error: NSError?
    public var state: URLSessionTask.State
    public var taskIdentifier: Int
    
    public var dataToReceive: Data?
    
    public func suspend() {
        state = .suspended
    }
    public func cancel() {
        state = .canceling
    }
    public func resume() {
        session?.resumeTask(mockDataTask: self)
    }
}

public class MockDownloadTask: URLSessionDownloadTaskProtocol {
    init() {
        countOfBytesReceived = 1
        countOfBytesExpectedToReceive = 1
        currentRequest = URLRequest(url: URL(string: "http://mobelux.com/downloadtask")!)
        state = .suspended
        taskIdentifier = 1
    }
    
    public var response: URLResponse?

    public func cancel() {}
    public var countOfBytesExpectedToReceive: Int64
    public var countOfBytesReceived: Int64
    public var currentRequest: URLRequest?
    public var error: NSError?
    public func resume() {}
    public var state: URLSessionTask.State
    public func suspend() {}
    public var taskIdentifier: Int
}
