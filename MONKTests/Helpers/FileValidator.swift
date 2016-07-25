//
//  FileValidator.swift
//  MONK
//
//  Created by Jerry Mayers on 7/12/16.
//  Copyright © 2016 Mobelux. All rights reserved.
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
        
        let memeTypeRange = dataRange.upperBound..<semiColonRange.lowerBound
        let mimeType = substring(with: memeTypeRange)
        
        let dataString = substring(from: base64Range.upperBound)
        guard let data = Data(base64Encoded: dataString) else { return nil }
        
        return (mimeType, data)
    }
}
