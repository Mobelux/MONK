//
//  UploadableData+Internal.swift
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

extension UploadableData {
    enum UploadError: Error {
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
        guard files.count > 0 else { throw UploadError.noFilesToUpload }
        
        let newline = "\r\n"
        let boundary = "__Mobelux_Network_Kit_Boundary__"
        let boundaryStart = "--\(boundary)\(newline)"
        let boundaryEnd = "--\(boundary)--\(newline)"
        guard let boundaryStartData = boundaryStart.data(using: .utf8),
            let boundaryEndData = boundaryEnd.data(using: .utf8),
            let newlineData = newline.data(using: .utf8) else { throw UploadError.couldNotConvertStringToUTF8Data }
        
        let contentDeposition = "Content-Disposition: form-data;"
        
        var data = Data()
        
        if let json = json {
            for (key, value) in json {
                guard let jsonHeader = "\(contentDeposition) name=\"\(key)\"".data(using: .utf8) else { throw UploadError.couldNotConvertStringToUTF8Data }
                data.append(boundaryStartData)
                data.append(jsonHeader)
                data.append(newlineData)
                data.append(newlineData)
                if JSONSerialization.isValidJSONObject(value), let jsonData = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted) {
                    data.append(jsonData)
                    data.append(newlineData)
                } else {
                    guard let valueData = "\(value)".data(using: .utf8) else { throw UploadError.couldNotConvertStringToUTF8Data }
                    data.append(valueData)
                    data.append(newlineData)
                }
            }
        }
        
        for file in files {
            guard let fileHeader = "\(contentDeposition) name=\"\(file.name)\"; filename=\"\(file.fileName)\"".data(using: .utf8),
                let fileContentType = "Content-Type: \(file.mimeType.rawValue)".data(using: .utf8),
                let fileDataEnd = "\r\n".data(using: .utf8) else { throw UploadError.couldNotConvertStringToUTF8Data }
            
            guard let fileData = try? file.data.readData() else { throw UploadError.couldNotReadDataFromURL }
            
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
            throw UploadError.noBodyData
        }
    }
}
