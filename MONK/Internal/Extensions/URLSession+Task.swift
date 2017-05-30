//
//  URLSession+Task.swift
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

extension URLSession {
    
    /**
        Gets a `URLSessionDataTask` or a subclass of it, from the session
        
        - parameter request: The request to create a task for
     
        - returns: Based on the `request.httpMethod` and any `bodyData` it might have, this will return either a `URLSessionDataTask` or a `URLSessionUploadTask` that is ready to start
    */
    func dataTask(with request: Request) -> URLSessionDataTask {
        switch request.httpMethod {
        case .delete, .get:
            return dataTask(with: request.urlRequest())
        case .post(let bodyData), .put(let bodyData), .patch(let bodyData):
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
