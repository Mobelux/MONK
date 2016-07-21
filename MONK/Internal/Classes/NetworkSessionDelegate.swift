//
//  NetworkSessionDelegate.swift
//  MONK
//
//  Created by Jerry Mayers on 6/27/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// A delegate for all of the `URLSessionDelegate` calls for a single `NetworkController`
final class NetworkSessionDelegate: NSObject {
    
    /// The queue that backs the `operationQueue`
    let queue: DispatchQueue
    
    /// The operation queue used by the `URLSession` for all delegate callbacks
    let operationQueue: OperationQueue
    
    /// The active `Tasks` managed by this object. Any access to this should be done when on the `queue`
    let tasks: ActiveTasks
    
    private weak var delegate: NetworkControllerDelegate?
    
    /// The `NetworkController` that this is the delegate for
    weak var networkController: NetworkController?
    
    /**
        Initialize the `NetworkSessionDelegate`
     
        - parameter delegate:   The delegate that should be notified about things like metrics being gathered
    */
    init(delegate: NetworkControllerDelegate?) {
        self.delegate = delegate
        
        let queueLabel = "com.mobelux.networkController.networkSessionDelegate"
        queue = DispatchQueue(label: queueLabel)
        
        operationQueue = OperationQueue()
        operationQueue.name = queueLabel
        operationQueue.underlyingQueue = queue
        
        tasks = ActiveTasks()
        
        super.init()
    }
}


extension NetworkSessionDelegate: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let networkController = networkController, let delegate = delegate else { return }
        
        DispatchQueue.main.async { 
            delegate.networkControllerDidFinishAllEvents(networkController: networkController)
        }
    }
    
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        
//    }
}

typealias NetworkSessionTaskDelegate = NetworkSessionDelegate
extension NetworkSessionTaskDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {        
        urlSession(session as URLSessionProtocol, task: task as URLSessionTaskProtocol, didCompleteWithError: error)
    }
    
    func urlSession(_ session: URLSessionProtocol, task: URLSessionTaskProtocol, didCompleteWithError error: NSError?) {
        guard let internalTask = tasks.task(fromURLTask: task) else { return }
        let statusCode: Int? = {
            let response = task.response as? HTTPURLResponse
            return response?.statusCode
        }()
        
        tasks.deactivate(task: internalTask)
        
        internalTask.didComplete(statusCode: statusCode, error: error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let internalTask = tasks.task(fromURLTask: task) as? MutableDataTask else { return }
        
        let percentProgress = Double(totalBytesSent).progress(of: Double(totalBytesExpectedToSend))
        let progress = (totalBytesExpectedToSend, totalBytesSent, percentProgress)
        internalTask.uploadProgress = progress
        for handler in internalTask.uploadProgressHandlers {
            handler(progress: progress)
        }
    }
    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        
//    }
    
    @objc(URLSession:task:didFinishCollectingMetrics:) func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let networkController = networkController, let delegate = delegate, let internalTask = tasks.task(fromURLTask: task) else { return }
        
        delegate.networkController(networkController: networkController, task: internalTask, didFinishCollecting: metrics)
    }
}


//extension Todd : Temp {
//    
//}
//
//public protocol Todd {
//    
//}
//
//
//public protocol Temp : URLSessionDataDelegateProtocol {
//    
//}
//
//
//public protocol URLSessionDataDelegateProtocol {
//    func urlSession(_ session: URLSessionProtocol, dataTask: URLSessionDataTaskProtocol, didReceive data: Data)
//}

typealias NetworkSessionDataDelegate = NetworkSessionDelegate
extension NetworkSessionDataDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        urlSession(session as URLSessionProtocol, dataTask: dataTask as URLSessionDataTaskProtocol, didReceive: data)
    }
    
    func urlSession(_ session: URLSessionProtocol, dataTask: URLSessionDataTaskProtocol, didReceive data: Data) {
        guard let task = tasks.dataTask(fromURLTask: dataTask) else { return }
        
        if var existingData = task.data {
            existingData.append(data)
            task.data = existingData
        } else {
            task.data = data
        }
        
        let percentProgress = Double(task.task.countOfBytesReceived).progress(of: Double(task.task.countOfBytesExpectedToReceive))
        let progress = (task.task.countOfBytesExpectedToReceive, task.task.countOfBytesReceived, percentProgress)
        task.downloadProgress = progress
        for handler in task.progressHandlers {
            handler(progress: progress)
        }
    }
}

typealias NetworkSessionDownloadDelegate = NetworkSessionDelegate
extension NetworkSessionDownloadDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let task = tasks.downloadTask(fromURLTask: downloadTask) else { return }
        
        let percentProgress = Double(totalBytesWritten).progress(of: Double(totalBytesExpectedToWrite))
        let progress = (totalBytesExpectedToWrite, totalBytesWritten, percentProgress)
        task.downloadProgress = progress
        for handler in task.progressHandlers {
            handler(progress: progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let task = tasks.downloadTask(fromURLTask: downloadTask) else { return }
        task.didFinishDownloading(to: location)
    }
}
