//
//  CompleteableTask.swift
//  MONK
//
//  Created by Jerry Mayers on 7/13/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

protocol CompletableTask: Task {
    
    /**
     Finish out the task, and set it's `result`
     
     - parameter statusCode: If the task finished successfully then a `non-nil` HTTP status code
     - parameter error:      If the task finished without successfully connecting to the server, then a hopefully `non-nil` error
     - parameter cachedResponse: True if this call is triggered for a cached response, or false if this is the final API response
    */
    func didComplete(statusCode: Int?, error: Error?, cachedResponse: Bool)
}
