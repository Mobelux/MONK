//
//  MutableDataTask.swift
//  MONK
//
//  Created by Jerry Mayers on 6/27/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// A `DataTask` that allows it's `data`, `result`, `downloadProgress` and `uploadProgress` to be mutated, so that we can update a task as it sends/recieves data
final class MutableDataTask: DataTask, CompletableTask {
    let request: Request
    let dataTask: URLSessionDataTask
    let uploadTask: URLSessionUploadTask?
    
    var data: Data?
    
    var result: TaskResult?
    
    var downloadProgress: BytesProgress?
    var progressHandlers: [BytesProgressHandler] = []
    
    var uploadProgress: BytesProgress?
    var uploadProgressHandlers: [BytesProgressHandler] = []
    
    var completionHandlers: [CompletionHandler] = []
    
    init(request: Request, task: URLSessionDataTask) {
        dataTask = task
        uploadTask = nil
        self.request = request
    }
    
    init(request: Request, task: URLSessionUploadTask) {
        self.request = request
        uploadTask = task
        dataTask = task
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
    
    func didComplete(statusCode: Int?, error: Error?) {
        let taskResult: TaskResult = {
            if let statusCode = statusCode {
                return .success(statusCode: statusCode, responseData: data)
            } else {
                return .failure(error: error)
            }
        }()
        result = taskResult
        completionHandlers.forEach { $0(taskResult) }
        removeHandlers()
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
