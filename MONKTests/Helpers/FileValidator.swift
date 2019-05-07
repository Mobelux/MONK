//
//  FileValidator.swift
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
@testable import MONK

struct FileValidator {
    
    /// Validates files we upload are the same as the ones in the response from HTTPBin.org
    static func validate(files: [UploadableData.FileData], response: JSON) -> Bool {
        guard let responseFiles = response["files"] as? [String : String], responseFiles.count == files.count else { return false }
        
        for file in files {
            guard let responseFile = responseFiles[file.name]?.fileData(),
                let expectedData = try? file.data.readData() else { return false }
            
            if file.mimeType.rawValue != responseFile.mimeType || expectedData != responseFile.data {
                return false
            }
        }
        return true
    }
    
    static func validate(uploadedData: UploadableData, response: JSON) -> Bool {
        guard let responseData = (response["data"] as? String)?.fileData() else { return false }
        
        switch uploadedData {
        case .data(let data, let contentType):
            guard let sentHeaders = response["headers"] as? JSON, let sentContentTypeHeader = sentHeaders["Content-Type"] as? String else { return false }
            return data == responseData.data && responseData.mimeType == "application/octet-stream" && sentContentTypeHeader == contentType.rawValue
        case .files, .json, .jsonAndFiles:
            fatalError("This function only validates original data")
        }
    }
}


private extension String {
    func fileData() -> (mimeType: String, data: Data)? {
        guard let dataRange = range(of: "data:"),
            let semiColonRange = range(of: ";"),
            let base64Range = range(of: "base64,") else { return nil }

        let mimeType = self[dataRange.upperBound..<semiColonRange.lowerBound]
        
        let dataString = self[base64Range.upperBound...]
        guard let data = Data(base64Encoded: String(dataString)) else { return nil }
        
        return (String(mimeType), data)
    }
}
