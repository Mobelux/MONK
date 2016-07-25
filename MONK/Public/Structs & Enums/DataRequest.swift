//
//  DataRequest.swift
//  MONK
//
//  Created by Jerry Mayers on 7/5/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// A `Request` that can be used for basic data uploads and downloads
public struct DataRequest: Request {
    public let url: URL
    public let httpMethod: HTTPMethod
    public let settings: RequestSettings?
    
    public init(url: URL, httpMethod: HTTPMethod, settings: RequestSettings? = nil) {
        self.url = url
        self.httpMethod = httpMethod
        self.settings = settings
    }
}
