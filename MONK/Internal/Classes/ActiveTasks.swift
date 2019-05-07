//
//  ActiveTasks.swift
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

protocol ActiveTasksDelegate: class {
    /// Anytime the count of tasks changes, this will be called on the queue for this ActiveTasks object
    ///
    /// - Parameters:
    ///   - activeTasks: The object who's task count changes
    ///   - count: The new count of tasks
    func activeTasks(_ activeTasks: ActiveTasks, didChangeCountTo count: Int)
}

/// Object that keeps track of all of the active `Tasks` for a single `NetworkController` and provides conveinence finding of specifc `Tasks`
final class ActiveTasks {

    weak var delegate: ActiveTasksDelegate?

    /// All `DataTasks` that are active
    private(set) var dataTasks = [MutableDataTask]() {
        didSet {
            delegate?.activeTasks(self, didChangeCountTo: count)
        }
    }
    
    /// All `DownloadTasks` that are active
    private(set) var downloadTasks = [MutableDownloadTask]() {
        didSet {
            delegate?.activeTasks(self, didChangeCountTo: count)
        }
    }
    
    /// The number of active data & download tasks for this instance
    var count: Int {
        return dataTasks.count + downloadTasks.count
    }
    
    /**
        Activates a task
     
        Activation doesn't really change the task, it just adds it to the `dataTasks` array so we can keep track of the fact that it is now active
     
        - parameter task:   The task to activate
    */
    func activate(task: MutableDataTask) {
        dataTasks.append(task)
    }
    
    /**
     Activates a task
     
     Activation doesn't really change the task, it just adds it to the `downloadTasks` array so we can keep track of the fact that it is now active
     
     - parameter task:   The task to activate
     */
    func activate(task: MutableDownloadTask) {
        downloadTasks.append(task)
    }
    
    /**
     Deactivates a task
     
     Deactivation doesn't really change the task, it just removes it from the `dataTasks` & `downloadTasks` arrays so we can keep track of the fact that it is now not active
     
     - parameter task:   The task to deactivate
     */
    func deactivate(task: Task) {
        let dataTasks = self.dataTasks.filter { $0.task == task.task }
        let downloadTasks = self.downloadTasks.filter { $0.task == task.task }
        
        for task in dataTasks {
            let index = self.dataTasks.firstIndex(where: { (innerTask) -> Bool in
                innerTask.task == task.task
            })
            
            if let index = index {
                self.dataTasks.remove(at: index)
            }
        }
        
        for task in downloadTasks {
            let index = self.downloadTasks.firstIndex(where: { (innerTask) -> Bool in
                innerTask.task == task.task
            })
            
            if let index = index {
                self.downloadTasks.remove(at: index)
            }
        }
    }
    
    /**
        Finds a `DataTask` that matches the `urlTask` if there is one
     
        - parameter urlTask: The `URLSessionDataTask` that we want to find the matching `DataTask`
     
        - returns: The active `MutableDataTask` that corrisponds to the `urlTask` if there is one
    */
    func dataTask(fromURLTask urlTask: URLSessionDataTask) -> MutableDataTask? {
        let tasks = dataTasks.filter { $0.dataTask == urlTask }
        return tasks.first
    }
    
    /**
     Finds a `DownloadTask` that matches the `urlTask` if there is one
     
     - parameter urlTask: The `URLSessionDownloadTask` that we want to find the matching `DownloadTask`
     
     - returns: The active `MutableDownloadTask` that corrisponds to the `urlTask` if there is one
     */
    func downloadTask(fromURLTask urlTask: URLSessionDownloadTask) -> MutableDownloadTask? {
        let tasks = downloadTasks.filter { $0.downloadTask == urlTask }
        return tasks.first
    }
    
    /**
     Finds a `CompletableTask` that matches the `urlTask` if there is one
     
     - parameter urlTask: The `URLSessionTask` that we want to find the matching `CompletableTask`
     
     - returns: The active `CompletableTask` that corrisponds to the `urlTask` if there is one either in the `downloadTasks` or `dataTasks` arrays
     */
    func task(fromURLTask urlTask: URLSessionTask) -> CompletableTask? {
        let dataTasks = self.dataTasks.filter { $0.task == urlTask }
        guard dataTasks.count == 0 else {
            return dataTasks.first
        }
        
        let downloadTasks = self.downloadTasks.filter { $0.task == urlTask }
        return downloadTasks.first
    }
}
