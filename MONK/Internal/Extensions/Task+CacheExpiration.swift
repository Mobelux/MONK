//
//  Task+CacheExpiration.swift
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

extension Task {
    func cacheExpiration() -> Date? {
        guard let settings = request.settings else { return nil }

        switch settings.cachePolicy {
        case .expireAt(let date):
            return date
        case .neverExpires:
            return nil
        case .headerExpiration:
            guard let response = task.response as? HTTPURLResponse,
                let cacheControl = response.allHeaderFields["Cache-Control"] as? String,
                let maxAge = cacheControl.parseMaxCacheAge() else { return nil }

            // Technically the max age is based upon the time the request was made, but practically this is close enough, and simplifies things
            return Date(timeIntervalSinceNow: maxAge)
        case .noAdditionalCaching:
            return nil
        }
    }
}

extension String {
    func parseMaxCacheAge() -> TimeInterval? {
        let coreComponents = components(separatedBy: ",")
        for component in coreComponents {
            if component.contains("max-age") || component.contains("s-maxage") {
                let maxAgeComponents = component.components(separatedBy: "=")

                guard maxAgeComponents.count == 2,
                    let maxAgeNumberComponent = maxAgeComponents.last,
                    let maxAge = TimeInterval(maxAgeNumberComponent) else { return nil }
                return maxAge
            }
        }
        return nil
    }
}
