//
//  ContentType.swift
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
