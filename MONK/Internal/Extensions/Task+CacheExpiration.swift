//
//  Task+CacheExpiration.swift
//  MONK
//
//  Created by Jerry Mayers on 4/25/17.
//  Copyright © 2017 Mobelux. All rights reserved.
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
