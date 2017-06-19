//
//  HTTPMethod.swift
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
