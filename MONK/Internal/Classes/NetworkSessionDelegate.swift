//
//  NetworkSessionDelegate.swift
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

/// A delegate for all of the `URLSessionDelegate` calls for a single `NetworkController`
final class NetworkSessionDelegate: NSObject {
    
    /// The queue that backs the `operationQueue`
    let queue: DispatchQueue
    
    /// The operation queue used by the `URLSession` for all delegate callbacks
    let operationQueue: OperationQueue
    
    /// The active `Tasks` managed by this object. Any access to this should be done when on the `queue`
    let tasks: ActiveTasks
    
    fileprivate let serverTrustSettings: ServerTrustSettings?
    
    fileprivate weak var delegate: NetworkControllerDelegate?
    
    /// The `NetworkController` that this is the delegate for
    weak var networkController: NetworkController?
    
    /**
        Initialize the `NetworkSessionDelegate`
     
        - parameter serverTrustSettings:    The settings to use to evaluate server trust, if you want none default settings.
        - parameter delegate:               The delegate that should be notified about things like metrics being gathered
    */
    init(serverTrustSettings: ServerTrustSettings?, delegate: NetworkControllerDelegate?) {
        self.serverTrustSettings = serverTrustSettings
        self.delegate = delegate
        
        let queueLabel = "com.mobelux.networkController.networkSessionDelegate"
        queue = DispatchQueue(label: queueLabel)
        
        operationQueue = OperationQueue()
        operationQueue.name = queueLabel
        operationQueue.underlyingQueue = queue
        
        tasks = ActiveTasks()
        
        super.init()
        tasks.delegate = self
    }
}

extension NetworkSessionDelegate: URLSessionDelegate {

    #if os(iOS) || os(watchOS) || os(tvOS)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let networkController = networkController, let delegate = delegate else { return }
        
        DispatchQueue.main.async { 
            delegate.networkControllerDidFinishAllEvents(networkController: networkController)
        }
    }
    #endif
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrustSettings = serverTrustSettings else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        serverTrustSettings.evaluateChallange(challange: challenge, completionHandler: completionHandler)
    }
}

typealias NetworkSessionTaskDelegate = NetworkSessionDelegate
extension NetworkSessionTaskDelegate: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let internalTask = tasks.task(fromURLTask: task) else { return }
        let statusCode: Int? = {
            let response = task.response as? HTTPURLResponse
            return response?.statusCode
        }()
        
        tasks.deactivate(task: internalTask)
        
        internalTask.didComplete(statusCode: statusCode, error: error, cachedResponse: false)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let internalTask = tasks.task(fromURLTask: task) as? MutableDataTask else { return }
        
        let percentProgress = Double(totalBytesSent).progress(of: Double(totalBytesExpectedToSend))
        
        internalTask.uploadProgress = (totalBytesExpectedToSend, totalBytesSent, percentProgress)
        for handler in internalTask.uploadProgressHandlers {
            handler((totalBytes: totalBytesExpectedToSend, completeBytes: totalBytesSent, progress: percentProgress))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    @objc(URLSession:task:didFinishCollectingMetrics:) func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let networkController = networkController, let delegate = delegate, let internalTask = tasks.task(fromURLTask: task) else { return }
        
        delegate.networkController(networkController: networkController, task: internalTask, didFinishCollecting: metrics)
    }
}

typealias NetworkSessionDataDelegate = NetworkSessionDelegate
extension NetworkSessionDataDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let task = tasks.dataTask(fromURLTask: dataTask) else { return }
        
        if var existingData = task.data {
            existingData.append(data)
            task.data = existingData
        } else {
            task.data = data
        }
        
        let percentProgress = Double(task.task.countOfBytesReceived).progress(of: Double(task.task.countOfBytesExpectedToReceive))
        task.downloadProgress = (task.task.countOfBytesExpectedToReceive, task.task.countOfBytesReceived, percentProgress)
        for handler in task.progressHandlers {
            handler((totalBytes: task.task.countOfBytesExpectedToReceive, completeBytes: task.task.countOfBytesReceived, progress: percentProgress))
        }
    }
}

typealias NetworkSessionDownloadDelegate = NetworkSessionDelegate
extension NetworkSessionDownloadDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let task = tasks.downloadTask(fromURLTask: downloadTask) else { return }
        
        let percentProgress = Double(totalBytesWritten).progress(of: Double(totalBytesExpectedToWrite))
        task.downloadProgress = (totalBytesExpectedToWrite, totalBytesWritten, percentProgress)
        for handler in task.progressHandlers {
            handler((totalBytes: totalBytesExpectedToWrite, completeBytes: totalBytesWritten, progress: percentProgress))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let task = tasks.downloadTask(fromURLTask: downloadTask) else { return }
        task.didFinishDownloading(to: location)
    }
}

typealias NetworkSessionActiveTasksDelegate = NetworkSessionDelegate
extension NetworkSessionActiveTasksDelegate: ActiveTasksDelegate {
    func activeTasks(_ activeTasks: ActiveTasks, didChangeCountTo count: Int) {
        guard let delegate = delegate, let networkController = networkController else { return }
        DispatchQueue.main.async {
            delegate.networkController(networkController: networkController, didChangeNumberOfActiveTasksTo: count)
        }
    }
}
