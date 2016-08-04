//
//  URLSession+Task.swift
//  MONK
//
//  Created by Jerry Mayers on 6/27/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

extension URLSession {
    
    /**
        Gets a `URLSessionDataTask` or a subclass of it, from the session
        
        - parameter request: The request to create a task for
     
        - returns: Based on the `request.httpMethod` and any `bodyData` it might have, this will return either a `URLSessionDataTask` or a `URLSessionUploadTask` that is ready to start
    */
    func dataTask(with request: Request) -> URLSessionDataTask {
        switch request.httpMethod {
        case .delete, .get, .patch:
            return dataTask(with: request.urlRequest())
        case .post(let bodyData), .put(let bodyData):
            do {
                return try uploadTask(with: request, bodyData: bodyData)
            } catch {
                return dataTask(with: request.urlRequest())
            }
        }
    }
    
    private func uploadTask(with request: Request, bodyData: UploadableData?) throws -> URLSessionUploadTask {
        guard let bodyData = bodyData else { throw UploadableData.UploadError.noBodyData }
        
        var urlRequest = request.urlRequest()
        let data = try bodyData.bodyData()
        urlRequest.addValue(data.contentTypeHeader.rawValue, forHTTPHeaderField: "Content-Type")
        return uploadTask(with: urlRequest, from: data.bodyData)
    }
    
    /**
        Conveinence wrapper to create a `URLSessionDownloadTask` from a `DownloadRequestType`
     
        - parameter request: The request to create a task for
     
        - returns: A `URLSessionDownloadTask` ready to start
    */
    func downloadTask(with request: DownloadRequestType) -> URLSessionDownloadTask {
        return downloadTask(with: request.urlRequest())
    }
}
