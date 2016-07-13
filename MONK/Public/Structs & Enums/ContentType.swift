//
//  ContentType.swift
//  MONK
//
//  Created by Jerry Mayers on 7/11/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/**
    A set of common content/MIME types
 
    - plainText:        text/plain
    - json:             application/json
    - multipartForm:    multipart/form-data; charset=utf-8; boundary=<your boundary here>
    - jpeg:             image/jpg
    - png:              image/png
    - custom:           <your mimeType here>
*/
public enum ContentType {
    case plainText
    case json
    case multipartForm(boundary: String)
    case jpeg
    case png
    case custom(mimeType: String)

    public var rawValue: String {
        switch self {
        case .plainText:
            return "text/plain"
        case .json:
            return "application/json"
        case .multipartForm(let boundary):
            return "multipart/form-data; charset=utf-8; boundary=\(boundary)"
        case .jpeg:
            return "image/jpg"
        case .png:
            return "image/png"
        case .custom(let mimeType):
            return mimeType
        }
    }
}
