//
//  UploadableData+Internal.swift
//  MONK
//
//  Created by Jerry Mayers on 7/13/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

extension UploadableData {
    enum Error: ErrorProtocol {
        case noFilesToUpload
        case couldNotReadDataFromURL
        case couldNotConvertStringToUTF8Data
        case noBodyData
    }
    
    /// The body data & content type header for that data
    typealias BodyData = (bodyData: Data, contentTypeHeader: ContentType)
    
    /**
        Gets the `BodyData` for a `DataTask` or throws an `UploadableData.Error` while trying
     
        - returns: the `BodyData`
    */
    func bodyData() throws -> BodyData {
        switch self {
        case .data(let data, let contentType):
            return (bodyData: data, contentTypeHeader: contentType)
        case .json(let json):
            return (bodyData: try json.jsonData(), contentTypeHeader: .json)
        case .files(let files):
            return try createBodyData(files: files, json: nil)
        case .jsonAndFiles(let json, let files):
            return try createBodyData(files: files, json: json)
        }
    }
    
    private func createBodyData(files: [FileData], json: JSON?) throws -> BodyData {
        guard files.count > 0 else { throw Error.noFilesToUpload }
        
        let newline = "\r\n"
        let boundary = "__Mobelux_Network_Kit_Boundary__"
        let boundaryStart = "--\(boundary)\(newline)"
        let boundaryEnd = "--\(boundary)--\(newline)"
        guard let boundaryStartData = boundaryStart.data(using: .utf8),
            let boundaryEndData = boundaryEnd.data(using: .utf8),
            let newlineData = newline.data(using: .utf8) else { throw Error.couldNotConvertStringToUTF8Data }
        
        let contentDeposition = "Content-Disposition: form-data;"
        
        var data = Data()
        
        if let json = json {
            for (key, value) in json {
                guard let jsonHeader = "\(contentDeposition) name=\"\(key)\"".data(using: .utf8) else { throw Error.couldNotConvertStringToUTF8Data }
                data.append(boundaryStartData)
                data.append(jsonHeader)
                data.append(newlineData)
                data.append(newlineData)
                if JSONSerialization.isValidJSONObject(value), let jsonData = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted) {
                    data.append(jsonData)
                    data.append(newlineData)
                } else {
                    guard let valueData = "\(value)".data(using: .utf8) else { throw Error.couldNotConvertStringToUTF8Data }
                    data.append(valueData)
                    data.append(newlineData)
                }
            }
        }
        
        for file in files {
            guard let fileHeader = "\(contentDeposition) name=\"\(file.name)\"; filename=\"\(file.fileName)\"".data(using: .utf8),
                let fileContentType = "Content-Type: \(file.mimeType.rawValue)".data(using: .utf8),
                let fileDataEnd = "\r\n".data(using: .utf8) else { throw Error.couldNotConvertStringToUTF8Data }
            
            guard let fileData = try? file.data.readData() else { throw Error.couldNotReadDataFromURL }
            
            data.append(boundaryStartData)
            data.append(fileHeader)
            data.append(newlineData)
            data.append(fileContentType)
            data.append(newlineData)
            data.append(newlineData)
            data.append(fileData)
            data.append(fileDataEnd)
        }
        
        if data.count > 0 {
            data.append(boundaryEndData)
            
            return (bodyData: data, contentTypeHeader: .multipartForm(boundary: boundary))
        } else {
            throw Error.noBodyData
        }
    }
}
