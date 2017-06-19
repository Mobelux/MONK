//
//  RequestSettings.swift
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

/// More advanced configuration settings for a `Request`
public struct RequestSettings {
    /// The network service type provides a hint to the operating system about what the underlying traffic is used for. This hint enhances the system's ability to prioritize traffic, determine how quickly it needs to wake up the cellular or Wi-Fi radio, and so on. By providing accurate information, you improve the ability of the system to optimally balance battery life, performance, and other considerations
    public let networkServiceType: URLRequest.NetworkServiceType

    /// How should this request be cached. For any of the options OTHER then `noAdditionalCaching`, if cached response is found the task's completion will be called immeadiately with the cached data, then the API will be hit (if reachable). The task's completion will then be called again with the API's response ONLY if the API's response data is different then the cached data.
    ///
    /// - noAdditionalCaching: MONK does no caching, specify `NSURLSession` only
    /// - neverExpires: The cached resource will never expire, but can still be purged manually or by the OS
    /// - expireAt: Expire the cached resource at a fixed date/time.
    /// - headerExpiration: Uses the response header's `max-age` to determine expiration. If no `max-age` or if header says `no-cache` then falls back to `noAdditionalCaching(.useProtocolCachePolicy)` behavior.
    public enum CachePolicy {
        case noAdditionalCaching(NSURLRequest.CachePolicy)
        case neverExpires
        case expireAt(Date)
        case headerExpiration // if header says no-cache or doesn't say then we won't cache it
    }

    /// The cache policy of the receiver.
    public let cachePolicy: CachePolicy
    
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
    public init(additionalHeaders: [String : String]? = nil, allowsCellularAccess: Bool = true, networkServiceType: URLRequest.NetworkServiceType = .default, cachePolicy: CachePolicy = .noAdditionalCaching(.useProtocolCachePolicy)) {
        self.additionalHeaders = additionalHeaders
        self.allowsCellularAccess = allowsCellularAccess
        self.networkServiceType = networkServiceType
        self.cachePolicy = cachePolicy
    }
}
