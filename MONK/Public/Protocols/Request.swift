//
//  Request.swift
//  MONK
//
//  Created by Jerry Mayers on 6/27/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// A network request
public protocol Request {
    
    /// The URL that the network request should hit
    var url: URL { get }
    
    /// The `HTTPMethod` that should be used for this request
    var httpMethod: HTTPMethod { get }
    
    /// Optional additional settings
    var settings: RequestSettings? { get }
}

extension Request {
    /**
        Creates a `URLRequest` configured from the recieving `Request`
     
        - returns: A `URLRequest` configured with all of the settings contained in the recieving `Request`
    */
    func urlRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        if let settings = settings {
            request.networkServiceType = settings.networkServiceType
            switch settings.cachePolicy {
            case .noAdditionalCaching(let cachePolicy):
                request.cachePolicy = cachePolicy
            case .neverExpires, .headerExpiration, .expireAt:
                request.cachePolicy = .useProtocolCachePolicy
            }
            request.allHTTPHeaderFields = settings.additionalHeaders
            request.allowsCellularAccess = settings.allowsCellularAccess
        }
        return request
    }
}

/// A file download network request
public protocol DownloadRequestType: Request {
    
    /// The URL on the local system to store the file once downloading completes
    var localURL: URL { get }
}
