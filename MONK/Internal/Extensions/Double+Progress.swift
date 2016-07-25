//
//  Double+Progress.swift
//  MONK
//
//  Created by Jerry Mayers on 7/5/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

extension Double {
    
    /**
        Calculate a 0 to 1.0 progress
     
        - parameter total: The total number that would equal 1.0
     
        - returns:  A optional progress that will only be `nil` when `total == 0`. Otherwise it will be `self / total` clamped so that it's always between 0 and 1.0
    */
    func progress(of total: Double) -> Double? {
        guard total > 0 else { return nil }
        return max(0, min(1, self / total))
    }
}
