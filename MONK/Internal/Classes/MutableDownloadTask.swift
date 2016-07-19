//
//  MutableDownloadTask.swift
//  MONK
//
//  Created by Jerry Mayers on 7/5/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// A `DownloadTask` that allows it's `result` and `downloadProgress` to be mutated, so that we can update a task as it recieves the file
final class MutableDownloadTask: DownloadTask, CompletableTask {
    let downloadRequest: DownloadRequestType
    let downloadTask: URLSessionDownloadTask
    
    var result: DownloadTaskResult?
    
    var downloadProgress: BytesProgress?
    var progressHandlers: [BytesProgressHandler] = []
    
    var completionHandlers: [DownloadCompletionHandler] = []
    
    init(request: DownloadRequestType, task: URLSessionDownloadTask) {
        downloadRequest = request
        downloadTask = task
    }
    
    func addProgress(handler: BytesProgressHandler) {
        progressHandlers.append(handler)
    }
    
    func addCompletion(handler: DownloadCompletionHandler) {
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
            if let path = downloadRequest.localURL.path, FileManager.default.fileExists(atPath: path) {
                let _ = try? FileManager.default.removeItem(at: downloadRequest.localURL)
            }
            try FileManager.default.moveItem(at: url, to: downloadRequest.localURL)
        } catch let error as NSError {
            self.result = .failure(error: error)
        }
    }
    
    func didComplete(statusCode: Int?, error: NSError?) {
        let result: DownloadTaskResult = {
            if let existingResult = self.result {
                // We could already have a failure result from trying to move the file from the temp URL to the localURL. If we do, preserve that result/error.
                return existingResult
            } else if let statusCode = statusCode {
                return .success(statusCode: statusCode, localURL: downloadRequest.localURL)
            } else {
                return .failure(error: error)
            }
        }()
        self.result = result
        completionHandlers.forEach { $0(result: result) }
        completionHandlers.removeAll()
        progressHandlers.removeAll()
    }
    
    func cancel() {
        downloadTask.cancel()
        
        progressHandlers.removeAll()
        completionHandlers.removeAll()
        
        let _ = try? FileManager.default.removeItem(at: downloadRequest.localURL)
    }
}
