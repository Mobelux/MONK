//
//  MutableDataTask.swift
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

import Foundation

/// A `DataTask` that allows it's `data`, `result`, `downloadProgress` and `uploadProgress` to be mutated, so that we can update a task as it sends/recieves data
final class MutableDataTask: DataTask, CompletableTask {
    let request: Request
    let dataTask: URLSessionDataTask
    let uploadTask: URLSessionUploadTask?
    
    var data: Data?
    var cache: Cache
    var result: TaskResult?
    
    var downloadProgress: BytesProgress?
    var progressHandlers: [BytesProgressHandler] = []
    
    var uploadProgress: BytesProgress?
    var uploadProgressHandlers: [BytesProgressHandler] = []
    
    var completionHandlers: [CompletionHandler] = []
    
    init(request: Request, task: URLSessionDataTask, cache: Cache) {
        dataTask = task
        uploadTask = nil
        self.request = request
        self.cache = cache
    }
    
    init(request: Request, task: URLSessionUploadTask, cache: Cache) {
        self.request = request
        uploadTask = task
        dataTask = task
        self.cache = cache
    }
    
    
    func addProgress(handler: @escaping BytesProgressHandler) {
        progressHandlers.append(handler)
    }
    
    func addUploadProgress(handler: @escaping BytesProgressHandler) {
        uploadProgressHandlers.append(handler)
    }
    
    func addCompletion(handler: @escaping CompletionHandler) {
        completionHandlers.append(handler)
    }
    
    func didComplete(statusCode: Int?, error: Error?, cachedResponse: Bool) {
        let taskResult: TaskResult

        if cachedResponse {
            guard let cachedData = cache.cachedObject(for: request.url) else { return }
            taskResult = .success(statusCode: cachedData.statusCode, responseData: cachedData.data, cached: .fromCache(cachedData.cachedAt))
        } else if let statusCode = statusCode {
            if let cachedData = cache.cachedObject(for: request.url) {
                if let data = data, cachedData.data == data {
                    // The cached data matches the API's data, so no need to call the handlers again
                    removeHandlers()
                    taskResult = .success(statusCode: statusCode, responseData: data, cached: .updatedCache)
                } else {
                    // The data was cached, but this data is different so it's an update
                    taskResult = .success(statusCode: statusCode, responseData: data, cached: .updatedCache)
                }
            } else {
                // The data was never in the cache
                taskResult = .success(statusCode: statusCode, responseData: data, cached: .notCached)
            }
            // Always cache the response even if it's the same as the current cached version, because it will update the expiration and createdAt dates
            if let data = data, let settings = request.settings, case .get = request.httpMethod {
                switch settings.cachePolicy {
                case .expireAt, .headerExpiration, .neverExpires:
                    cache.add(object: data, url: request.url, statusCode: statusCode, expiration: cacheExpiration())
                case .noAdditionalCaching:
                    break
                }
            }
        } else {
            taskResult = .failure(error: error)
        }

        result = taskResult
        completionHandlers.forEach { $0(taskResult) }
        if !cachedResponse {
            removeHandlers()
        }
    }
    
    func cancel() {
        dataTask.cancel()
        
        removeHandlers()
    }
    
    private func removeHandlers() {
        progressHandlers.removeAll()
        uploadProgressHandlers.removeAll()
        completionHandlers.removeAll()
    }
}
