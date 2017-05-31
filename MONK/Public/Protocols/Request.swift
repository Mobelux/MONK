//
//  Request.swift
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
