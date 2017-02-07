//
//  HTTPMethod.swift
//  MONK
//
//  Created by Jerry Mayers on 6/27/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

/**
    A basic enum that contains all the `HTTPMethod` options for a `Request`
 
    - get:      GET
    - post:     POST, if you supply a `bodyData` then that will be attched to the `Request's` body
    - put:      PUT, if you supply a `bodyData` then that will be attched to the `Request's` body
    - patch:    PATCH, if you supply a `bodyData` then that will be attched to the `Request's` body
    - delete:   DELETE
*/
public enum HTTPMethod {
    case get
    case post(bodyData: UploadableData?)
    case put(bodyData: UploadableData?)
    case patch(bodyData: UploadableData?)
    case delete
    
    var rawValue: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .patch:
            return "PATCH"
        case .delete:
            return "DELETE"
        }
    }
    
    /// `true` if a request sent with this `HTTPMethod` will be a multipart form message. This is wholy dependent on the contents of `bodyData` if there is any
    public var isMultiPart: Bool {
        switch self {
        case .get, .delete:
            return false
        case .post(let bodyData), .put(let bodyData), .patch(let bodyData):
            return bodyData?.isMultiPart ?? false
        }
    }
}
