//
//  NetworkController.swift
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

/// A simple networking controller. The goal isn't to handle all networking tasks, but to provide a very simple and safe controller that can be used in 95% of use cases.
public final class NetworkController {
    
    fileprivate let session: URLSession
    fileprivate let sessionDelegate: NetworkSessionDelegate
    public let cache: Cache
    
    /// The number of tasks that are active on this network controller. This includes paused/suspended tasks.
    public var activeTasksCount: Int {
        return sessionDelegate.tasks.count
    }
    
    /**
        Create a `NetworkController` 
        
        - parameter serverTrustSettings:    The settings to use to evaluate server trust, if you want none default settings.
        - parameter configuration:          A `URLSessionConfiguration` who's settings will be used for all tasks created by this instance of the `NetworkController`. `.mobeluxDefault` is used as the default value, and is sufficient for most use cases. If you are wanting a `DownloadTask` that can keep running when your app is backgrounded, you use `.background(withIdentifier:)` or `.mobeluxBackground(withIdentifier:)`
        - parameter description:            A string to be used to label this controller. It will be handy when debugging since it is visible in the stack trace in Xcode.
        - parameter delegate:               An optional delegate that can recieve some basic notifications about metrics and things.
    */
    public init(serverTrustSettings: ServerTrustSettings?, configuration: URLSessionConfiguration = URLSessionConfiguration.mobeluxDefault, description: String = "com.mobelux.network_controller", cacheBehavior: CacheBehavior = .purgeOnLowDiskSpace, delegate: NetworkControllerDelegate? = nil) {
        
        sessionDelegate = NetworkSessionDelegate(serverTrustSettings: serverTrustSettings, delegate: delegate)
        
        session = URLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: sessionDelegate.operationQueue)
        session.sessionDescription = description

        switch cacheBehavior {
        case .purgeOnLowDiskSpace:
            cache = Cache.purgableCache
        case .manualPurgeOrExpirationOnly:
            cache = Cache.persistantCache
        }

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
    func cancelAllTasks() {
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
    func data(with request: Request) -> DataTask {
        let urlDataTask = session.dataTask(with: request)
        let task: MutableDataTask = {
            if let uploadTask = urlDataTask as? URLSessionUploadTask {
                return MutableDataTask(request: request, task: uploadTask, cache: cache)
            } else {
                return MutableDataTask(request: request, task: urlDataTask, cache: cache)
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
    func download(with request: DownloadRequestType) -> DownloadTask {
        let urlDownloadTask = session.downloadTask(with: request)
        let task = MutableDownloadTask(request: request, task: urlDownloadTask, cache: cache)
        sessionDelegate.queue.async { 
            self.sessionDelegate.tasks.activate(task: task)
        }
        return task
    }
}
