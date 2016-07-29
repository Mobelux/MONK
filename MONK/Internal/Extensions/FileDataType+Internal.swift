//
//  FileDataType+Internal.swift
//  MONK
//
//  Created by Jerry Mayers on 7/19/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

extension FileDataType {
    
    /**
     Reads the `Data` from the `FileDataType`
     
     - returns: a `Data` containing the desired data, or passes along the `throw` that `Data(contentsOf:)` throws
     */
    func readData() throws -> Data {
        switch self {
        case .data(let data):
            return data
        case .file(let url):
            return try Data(contentsOf: url)
        }
    }
}
