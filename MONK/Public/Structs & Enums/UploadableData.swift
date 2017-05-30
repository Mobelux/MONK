//
//  UploadableData.swift
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
    A enum that defines all the ways that some data can be uploaded in a `Request`
 
    - data:         Take prepackaged data and upload it directly as the `bodyData` on the `Request`
    - json:         Take some `JSON` and upload it after converting it to `bodyData` on the `Request`
    - files:        Take some `FileData(s)` and upload it after converting it to multipart `bodyData` on the `Request`
    - jsonAndFiles: Take some `JSON` and `FileData(s)` and upload it after converting it to multipart `bodyData` on the `Request`
*/
public enum UploadableData {
    
    /// A struct that defines a single file to be uploaded
    public struct FileData {
        
        /// The name/key to be used for this file in the upload
        public let name: String
        
        /// The fileName to tell the server
        public let fileName: String
        
        /// The MIME type of this file
        public let mimeType: ContentType
        
        /// The link to the actual data (in memory or on disk)
        public let data: FileDataType

        /// Creates a new FileData
        ///
        /// - Parameters:
        ///   - name: The name/key to be used for this file in the upload
        ///   - fileName: The fileName to tell the server
        ///   - mimeType: The MIME type of this file
        ///   - data: The link to the actual data (in memory or on disk)
        public init(name: String, fileName: String, mimeType: ContentType, data: FileDataType) {
            self.name = name
            self.fileName = fileName
            self.mimeType = mimeType
            self.data = data
        }
    }
    
    case data(data: Data, contentType: ContentType)
    case json(json: JSON)
    case files(files: [FileData])
    case jsonAndFiles(json: JSON, files: [FileData])
    
    /// `true` if this `UploadableData` will cause a `Request` to become a multipart request
    public var isMultiPart: Bool {
        switch self {
        case .data, .json:
            return false
        case .files, .jsonAndFiles:
            return true
        }
    }
}
