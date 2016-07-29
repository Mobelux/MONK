//
//  FileDataType.swift
//  MONK
//
//  Created by Jerry Mayers on 7/19/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/**
An enum that defines how to access some data

- file: The data is on disk, and should be accessed via `url`
- data: The data is in memory, and should be accessed via `data`
*/
public enum FileDataType {
    case file(url: URL)
    case data(data: Data)
}
