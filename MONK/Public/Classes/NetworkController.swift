//
//  NetworkController.swift
//  MONK
//
//  Created by Jerry Mayers on 6/27/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

extension URLSession : URLSessionProtocol {
    public func dataTask(with request: Request) -> URLSessionDataTaskProtocol {
        return dataTask(with: request) as URLSessionDataTask
    }
    
    public func downloadTask(with request: DownloadRequestType) -> URLSessionDownloadTaskProtocol {
        return downloadTask(with: request) as URLSessionDownloadTask
    }
}

public protocol URLSessionDataTaskProtocol : class, URLSessionTaskProtocol {
    
}

public protocol URLSessionDownloadTaskProtocol : class, URLSessionDataTaskProtocol {
    
}
public protocol URLSessionUploadTaskProtocol : class, URLSessionDataTaskProtocol {
    
}

public protocol URLSessionTaskProtocol : class {
    func cancel()
    func resume()
    func suspend()
    var response: URLResponse? { get }
    var countOfBytesReceived: Int64 { get }
    var countOfBytesExpectedToReceive: Int64 { get }
    var state: URLSessionTask.State { get }
    var error: NSError? { get }
    var currentRequest: URLRequest? { get }
    var taskIdentifier: Int { get }
}

extension URLSessionTask : URLSessionTaskProtocol {
    
}

extension URLSessionDataTask : URLSessionDataTaskProtocol {
    
}

extension URLSessionDownloadTask : URLSessionDownloadTaskProtocol {
    
}

extension URLSessionUploadTask : URLSessionUploadTaskProtocol {
    
}

public protocol URLSessionProtocol : class {
    var sessionDescription: String? { get set}
    func invalidateAndCancel()
    func dataTask(with request: Request) -> URLSessionDataTaskProtocol
    func downloadTask(with request: DownloadRequestType) -> URLSessionDownloadTaskProtocol
}

/// A simple networking controller. The goal isn't to handle all networking tasks, but to provide a very simple and safe controller that can be used in 95% of use cases.
public final class NetworkController {
    
    private let session: URLSessionProtocol
    private let sessionDelegate: NetworkSessionDelegate
    
    /// The number of tasks that are active on this network controller. This includes paused/suspended tasks.
    public var activeTasksCount: Int {
        return sessionDelegate.tasks.count
    }
    
    /**
        Create a `NetworkController` 
     
        - parameter configuration:  A `URLSessionConfiguration` who's settings will be used for all tasks created by this instance of the `NetworkController`. `.mobeluxDefault` is used as the default value, and is sufficient for most use cases. If you are wanting a `DownloadTask` that can keep running when your app is backgrounded, you use `.background(withIdentifier:)` or `.mobeluxBackground(withIdentifier:)`
        - parameter description:    A string to be used to label this controller. It will be handy when debugging since it is visible in the stack trace in Xcode.
        - parameter delegate:       An optional delegate that can recieve some basic notifications about metrics and things.
    */
    public init (configuration: URLSessionConfiguration = URLSessionConfiguration.mobeluxDefault, description: String = "com.mobelux.network_controller", delegate: NetworkControllerDelegate? = nil) {
        
        sessionDelegate = NetworkSessionDelegate(delegate: delegate)
        
        session = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: sessionDelegate.operationQueue)
        session.sessionDescription = description
        
        sessionDelegate.networkController = self
    }
    
    internal init (sessionProtocol: URLSessionProtocol, sessionDelegate: NetworkSessionDelegate) {
        session = sessionProtocol
        self.sessionDelegate = sessionDelegate
        
        sessionDelegate.networkController = self
    }
    
    deinit {
        // Not invalidating the session will cause it to retain it's delegate, and leak memory
        session.invalidateAndCancel()
    }
}

typealias NetworkControllerActions = NetworkController
public extension NetworkControllerActions {
    
    /// Cancels all currently active tasks for this controller.
    public func cancelAllTasks() {
        sessionDelegate.queue.async { 
            self.sessionDelegate.tasks.dataTasks.forEach { $0.cancel() }
            self.sessionDelegate.tasks.downloadTasks.forEach { $0.cancel() }
        }
    }
    
    /**
        Create a `DataTask` and configure it so it is ready to start. `DataTasks` are used for recieving basic data, as well as sending data. 
     
        This creates tasks that could be either a `URLSessionDataTask` or a `URLSessionUploadTask`. You really shouldn't care which one is used under the hood, but the rule is that if you have a `Request` who's `httpMethod` has a `bodyData`, then a `URLSessionUploadTask` will be used. This way you can get upload progress and other niceties that `URLSessionUploadTask` provides.
     
        - parameter request: A request that we should create a task for
     
        - returns: A `DataTask` that is ready to start. NOTE: You must call `task.resume()` before the task will start. You should register any progress/completion handlers before calling `resume()` so that you don't miss the completion call.
    */
    public func data(with request: Request) -> DataTask {
        let urlDataTask = session.dataTask(with: request)
        let task: MutableDataTask = {
            if let uploadTask = urlDataTask as? URLSessionUploadTaskProtocol {
                return MutableDataTask(request: request, task: uploadTask)
            } else {
                return MutableDataTask(request: request, task: urlDataTask)
            }
        }()
        sessionDelegate.queue.async { 
            self.sessionDelegate.tasks.activate(task: task)
        }
        return task
    }
    
    /**
     Create a `DownloadTask` and configure it so it is ready to start. `DownloadTask` are used for recieving a file (such as an image, or video).
     
     If you are wanting a `DownloadTask` that can keep running when your app is backgrounded, you need to make sure you initialized this `NetworkController` with `configuration: URLSessionConfiguration.background(withIdentifier:)`.
     
     - parameter request: A request that we should create a task for
     
     - returns: A `DownloadTask` that is ready to start. NOTE: You must call `task.resume()` before the task will start. You should register any progress/completion handlers before calling `resume()` so that you don't miss the completion call.
     */
    public func download(with request: DownloadRequestType) -> DownloadTask {
        let urlDownloadTask = session.downloadTask(with: request)
        let task = MutableDownloadTask(request: request, task: urlDownloadTask)
        sessionDelegate.queue.async { 
            self.sessionDelegate.tasks.activate(task: task)
        }
        return task
    }
}
