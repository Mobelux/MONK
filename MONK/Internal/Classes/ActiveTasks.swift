//
//  ActiveTasks.swift
//  MONK
//
//  Created by Jerry Mayers on 6/30/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// Object that keeps track of all of the active `Tasks` for a single `NetworkController` and provides conveinence finding of specifc `Tasks`
final class ActiveTasks {

    /// All `DataTasks` that are active
    private(set) var dataTasks = [MutableDataTask]()
    
    /// All `DownloadTasks` that are active
    private(set) var downloadTasks = [MutableDownloadTask]()
    
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
            let index = self.dataTasks.index(where: { (innerTask) -> Bool in
                innerTask.task == task.task
            })
            
            if let index = index {
                self.dataTasks.remove(at: index)
            }
        }
        
        for task in downloadTasks {
            let index = self.downloadTasks.index(where: { (innerTask) -> Bool in
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
