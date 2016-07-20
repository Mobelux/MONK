//
//  UploadableData.swift
//  MONK
//
//  Created by Jerry Mayers on 7/11/16.
//  Copyright © 2016 Mobelux. All rights reserved.
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
