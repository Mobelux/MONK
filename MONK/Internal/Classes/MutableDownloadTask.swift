//
//  MutableDownloadTask.swift
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

/// A `DownloadTask` that allows it's `result` and `downloadProgress` to be mutated, so that we can update a task as it recieves the file
final class MutableDownloadTask: DownloadTask, CompletableTask {
    let downloadRequest: DownloadRequestType
    let downloadTask: URLSessionDownloadTask
    
    var result: DownloadTaskResult?
    var cache: Cache
    
    var downloadProgress: BytesProgress?
    var progressHandlers: [BytesProgressHandler] = []
    
    var completionHandlers: [DownloadCompletionHandler] = []
    
    init(request: DownloadRequestType, task: URLSessionDownloadTask, cache: Cache) {
        downloadRequest = request
        downloadTask = task
        self.cache = cache
    }
    
    func addProgress(handler: @escaping BytesProgressHandler) {
        progressHandlers.append(handler)
    }
    
    func addCompletion(handler: @escaping DownloadCompletionHandler) {
        completionHandlers.append(handler)
    }
    
    /**
        Finalize moving the just downloaded file from the session's temporary location, to the `downloadRequest.localURL`
     
        This should be called from `urlSession(_, downloadTask:, didFinishDownloadingTo location)`
     
        - parameter url: The temporary `URL` that the session downloaded the file to
    */
    func didFinishDownloading(to url: URL) {
        do {
            // incoming URL is a temporary location decided by URLSession. We have to move it to our final destination before the end of `urlSession(_, downloadTask:, didFinishDownloadingTo location)` or else the system will delete it out from under us
            if FileManager.default.fileExists(atPath: downloadRequest.localURL.path) {
                let _ = try? FileManager.default.removeItem(at: downloadRequest.localURL)
            }
            try FileManager.default.moveItem(at: url, to: downloadRequest.localURL)
        } catch let error as NSError {
            self.result = .failure(error: error)
        }
    }
    
    func didComplete(statusCode: Int?, error: Error?, cachedResponse: Bool) {
        // Download tasks aren't cached
        guard !cachedResponse else { return }
        let taskResult: DownloadTaskResult = {
            if let existingResult = self.result {
                // We could already have a failure result from trying to move the file from the temp URL to the localURL. If we do, preserve that result/error.
                return existingResult
            } else if let statusCode = statusCode {
                return .success(statusCode: statusCode, localURL: downloadRequest.localURL)
            } else {
                return .failure(error: error)
            }
        }()
        result = taskResult
        completionHandlers.forEach { $0(taskResult) }
        removeHandlers()
    }
    
    func cancel() {
        downloadTask.cancel()
        
        completionHandlers.forEach { $0(.failure(error: nil)) }
        removeHandlers()
        
        let _ = try? FileManager.default.removeItem(at: downloadRequest.localURL)
    }
    
    private func removeHandlers() {
        progressHandlers.removeAll()
        completionHandlers.removeAll()
    }
}
