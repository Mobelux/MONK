//
//  Task+Default.swift
//  MONK
//
//  Created by Jerry Mayers on 6/28/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

public extension Task {
    public var state: TaskState {
        switch task.state {
        case .suspended:
            return .waiting
        case .running:
            return .running
        case .canceling:
            return .cancelled
        case .completed:
            if let error = task.error {
                return .failed(error: error)
            } else {
                return .completed
            }
        }
    }
    
    public func resume() {
        if let settings = request.settings, case .get = request.httpMethod, let task = self as? CompletableTask {
            switch settings.cachePolicy {
            case .neverExpires, .headerExpiration, .expireAt:
                task.didComplete(statusCode: nil, error: nil, cachedResponse: true)
            case .noAdditionalCaching:
                break
            }
        }
        task.resume()
    }
    
    public func suspend() {
        task.suspend()
    }
}

public extension DataTask {
    public var task: URLSessionTask { return dataTask }
}

public extension DownloadTask {
    public var request: Request { return downloadRequest }
    public var task: URLSessionTask { return downloadTask }
}
