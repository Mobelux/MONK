//
//  DownloadRequest.swift
//  MONK
//
//  Created by Jerry Mayers on 7/5/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// A `DownloadRequestType` that can be used to download a file
public struct DownloadRequest: DownloadRequestType {
    public let url: URL
    public let httpMethod: HTTPMethod
    public let localURL: URL
    public let settings: RequestSettings?
    
    public init(url: URL, httpMethod: HTTPMethod, localURL: URL, settings: RequestSettings? = nil) {
        self.url = url
        self.httpMethod = httpMethod
        self.localURL = localURL
        self.settings = settings
    }
}
