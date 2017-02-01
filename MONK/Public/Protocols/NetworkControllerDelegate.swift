//
//  NetworkControllerDelegate.swift
//  MONK
//
//  Created by Jerry Mayers on 7/6/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

public protocol NetworkControllerDelegate: class {

    /// Called when an event is started or finishes. Useful if you wish to show/hide the network activity indicator or something similar
    ///
    /// - Parameters:
    ///   - networkController: The controller who's number of active tasks has changed
    ///   - numberOfActiveTasks: The new number of active tasks
    func networkController(networkController: NetworkController, didChangeNumberOfActiveTasksTo numberOfActiveTasks: Int)

    /**
     - discussion: In iOS, when a background transfer completes or requires credentials, if your app is no longer running, your app is automatically relaunched in the background, and the app’s `UIApplicationDelegate` is sent an `application(_:handleEventsForBackgroundURLSession:completionHandler:)` message. This call contains the identifier of the session that caused your app to be launched. Your app should then store that completion handler before creating a background configuration object with the same identifier, and creating a session with that configuration. The newly created session is automatically reassociated with ongoing background activity.
     
        When your app later receives this `networkControllerDidFinishAllEvents` message, this indicates that all messages previously enqueued for this controller have been delivered, and that it is now safe to invoke the previously stored completion handler or to begin any internal updates that may result in invoking the completion handler. This call will happen on the main queue, since you should invoke the completeion handler on the main queue.
     
        This won't be called if the application is in the forground when the network controller finishes, or if you don't create a background `NetworkController` using the same identifier as the original one that started the request.
    */
    func networkControllerDidFinishAllEvents(networkController: NetworkController)
    
    /**
        Will be called once a task is complete and metrics are available. This will be called on the `NetworkController's` background queue.
    */
    @available(iOS 10, *)
    func networkController(networkController: NetworkController, task: Task, didFinishCollecting metrics: URLSessionTaskMetrics)
}
