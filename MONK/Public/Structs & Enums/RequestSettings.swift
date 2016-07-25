//
//  RequestSettings.swift
//  MONK
//
//  Created by Jerry Mayers on 7/11/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/// More advanced configuration settings for a `Request`
public struct RequestSettings {
    /// The network service type provides a hint to the operating system about what the underlying traffic is used for. This hint enhances the system's ability to prioritize traffic, determine how quickly it needs to wake up the cellular or Wi-Fi radio, and so on. By providing accurate information, you improve the ability of the system to optimally balance battery life, performance, and other considerations
    public let networkServiceType: URLRequest.NetworkServiceType
    
    /// The cache policy of the receiver.
    public let cachePolicy: NSURLRequest.CachePolicy
    
    /// `true` if the receiver is allowed to use the built in cellular radios to satify the request, `false` otherwise.
    public let allowsCellularAccess: Bool
    
    /// These headers will be appended to any headers set in the `URLSessionConfiguration`, but if both places set different values for the same key, then the value from this dict, will be the one used.
    public let additionalHeaders: [String : String]?
    
    /**
        Create a `RequestSettings`
     
        - parameter additionalHeaders:      Any headers that you want to add to those from the `URLSessionConfiguration` or that you want to override from there. Default = `nil`
        - parameter allowsCellularAccess:   Allow this request to use the cellular radio. Default = `true`
        - parameter networkServiceType:     Provides a hint to the system about what this request is used for. This helps it prioritize traffic. Defaults = `.default`
        - parameter cachePolicy:            How the system should handle this request in respect to the cache
    */
    public init(additionalHeaders: [String : String]? = nil, allowsCellularAccess: Bool = true, networkServiceType: URLRequest.NetworkServiceType = .default, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.additionalHeaders = additionalHeaders
        self.allowsCellularAccess = allowsCellularAccess
        self.networkServiceType = networkServiceType
        self.cachePolicy = cachePolicy
    }
}
