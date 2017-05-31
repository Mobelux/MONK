//
//  Task.swift
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

/**
    The state of a single `Task`
 
    - waiting:      The `Task` has been created, and is waiting for `resume()` to be called to start it. This is also the state of a task that has been paused with a call to `suspend()`
    - running:      The `Task` is actively being processed
    - completed:    The `Task` has finished without errors
    - failed:       The `Task` has finished, but with an error. The error is attached. This error is only for errors in starting the task and reaching the requested host. This error doesn't take into account "data errors" that the host may have with your request
    - cacnelled:    The `Task` has finished due to being cancelled
*/
public enum TaskState {
    case waiting
    case running
    case completed
    case failed(error: Error)
    case cancelled
}

/// Was this response from the cache?
///
/// - fromCache: Yep it was from the cache. The associated `Date` is when it was added to the cache
/// - updatedCache: This data just came from the API, and it was different from what was in the cache
/// - notCached: This data just came from the API, and there was not any cached data for this request
public enum CachedResponse {
    case fromCache(Date)
    case updatedCache
    case notCached
}

/**
 The result of a `DataTask`
 
 - success: The case when a `Task's` `state == .complete`. `statusCode`: the HTTP status code from the server. `responseData`: The data returned from the server (if any). `cached` indicates if this result was from the cache or not
 - failure: The case when a `Task's` `state == .failed`. This `error` is only for errors in reaching the server. Not for errors that the server might be thrown
 */
public enum TaskResult {
    case success(statusCode: Int, responseData: Data?, cached: CachedResponse)
    case failure(error: Error?)
}

/**
 The result of a `DownloadTask`
 
 - success: The case when a `Task's` `state == .complete`. `statusCode`: the HTTP status code from the server. `localURL`: The URL on the client's disk where the download file is now accessable
 - failure: The case when a `Task's` `state == .failed`. This `error` is for errors in reaching the server as well as errors in downloading the file and moving it to the requested `localURL`
 */
public enum DownloadTaskResult {
    case success(statusCode: Int, localURL: URL)
    case failure(error: Error?)
}

/**
    The byte progress of a `Task`.
 
    - parameter totalBytes:     The total bytes that the system expects to transfer. For uploads this is always known, but for downloads the server may not say. If that is the case then this will be -1
    - parameter completeBytes:  The number of bytes that has transfered so far. This will always be correct
    - parameter progress:       Progress is optional, because if `totalBytes == -1`, then we can't calculate progress. If not `nil` then it will always be between 0 and 1.0
*/
public typealias BytesProgress = (totalBytes: Int64, completeBytes: Int64, progress: Double?)

/// A handler that will be called when `BytesProgress` changes
public typealias BytesProgressHandler = (_ progress: BytesProgress) -> Void

/// A handler that will be called when a `DataTask` completes
public typealias CompletionHandler = (_ result: TaskResult) -> Void

/// A handler that will be called when a `DownloadTask` completes
public typealias DownloadCompletionHandler = (_ result: DownloadTaskResult) -> Void


/// Basic task that defines the shared interface for a network task
public protocol Task: class {
    
    /// The request that was used to create this task
    var request: Request { get }
    
    /// The underlying system task. You should NEVER use `task.cancel()` on this task or your app will leak memory. Instad call `cancel()` on the `Task`
    var task: URLSessionTask { get }

    /// The cache that this task will use, if the `CachePolicy` dictates
    var cache: Cache { get }
    
    /// The current state of this task
    var state: TaskState { get }
    
    /// The progress of downloading the response from the server
    var downloadProgress: BytesProgress? { get }
    
    /**
        Add a handler to be notified about download progress changes
     
        The `handler` will be called on the main queue, and after the task completes, the handler will be released.
     
        - parameter handler: A handler that will be called after `downloadProgress` changes.
    */
    func addProgress(handler: @escaping BytesProgressHandler)
    
    /// This will take a task that is in the `waiting` state, and move it into the `running` state, allowing it to do it's thing
    func resume()
    
    /// This will take a task that is in the `running` state, and move it into the `waiting` state, pausing it. Call `resume()` to unpause
    func suspend()
    
    /// This will take a task and perimiantly cancel it. `state == .cancelled`. You should ALWAYS use this instead of `task.cancel()` on the underlying task or your app will leak memory.
    func cancel()
}

/// Data task that extends `Task` with upload & download of data
public protocol DataTask: Task {
    var result: TaskResult? { get }
    
    /// The progress of uploading the request to the server. This will only ever be `non-nil` if the `request.httpMethod` has a `non-nil bodyData`
    var uploadProgress: BytesProgress? { get }
    
    /**
     Add a handler to be notified about upload progress changes
     
     The `handler` will be called on the main queue, and after the task completes, the handler will be released.
     
     - parameter handler: A handler that will be called after `uploadProgress` changes.
     */
    func addUploadProgress(handler: @escaping BytesProgressHandler)
    
    /**
     Add a handler to be notified when the task is complete
     
     The `handler` will be called on the `NetworkController's` private queue, and after that the handler will be released.
     
     - parameter handler: A handler that will be called when the task completes
     */
    func addCompletion(handler: @escaping CompletionHandler)
    
    /// The underlying system data task. Since `URLSessionDataTask` is a superclass of `URLSessionUploadTask`, this property and `uploadTask` may point to the same task. `task` will also point to the same task as this
    var dataTask: URLSessionDataTask { get }
    
    /// The underlying system upload task if, this task is uploading data. Since `URLSessionDataTask` is a superclass of `URLSessionUploadTask`, this property `task` and `dataTask` point to the same task when this is not `nil`
    var uploadTask: URLSessionUploadTask? { get }
}

/// Download task that extends `Task` and downloads files to disk
public protocol DownloadTask: Task {
    var result: DownloadTaskResult? { get }
    
    /**
     Add a handler to be notified when the task is complete
     
     The `handler` will be called on the `NetworkController's` private queue, and after that the handler will be released.
     
     - parameter handler: A handler that will be called when the task completes
     */
    func addCompletion(handler: @escaping DownloadCompletionHandler)
    
    /// The request that was used to create this task, this will be a duplicate of `request` but with additional download specific stuff added
    var downloadRequest: DownloadRequestType { get }
    
    /// The underlying system download task. Since `URLSessionTask` is a superclass of `URLSessionDownloadTask`, this property and `task` point to the same task
    var downloadTask: URLSessionDownloadTask { get }
}
