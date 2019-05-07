//
//  JSON.swift
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

public typealias JSONKey = NSString
public typealias JSONValue = AnyObject
public typealias JSON = [JSONKey : JSONValue]

public enum JSONError: Error {
    case notValidJSON
    case couldNotCreateData
    case couldNotCreateJSON
}

public extension Dictionary where Key: JSONKey, Value: JSONValue {
    
    /**
        Creates a `Data` from some JSON
     
        - returns: a valid `Data` or throws a `JSONError`
    */
    func jsonData() throws -> Data {
        guard JSONSerialization.isValidJSONObject(self) else { throw JSONError.notValidJSON }
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else { throw JSONError.couldNotCreateData }
        return data
    }
}


public extension Data {
    
    /**
        Creates a `JSON` from some `Data`
     
        - returns: a valid `JSON` or throws a `JSONError.couldNotCreateJSON`
    */
    func json() throws -> JSON {
        guard let json = (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)) as? JSON else { throw JSONError.couldNotCreateJSON }
        return json
    }

    /// Creates an array of JSON dictionaries
    ///
    /// - Returns: An array of JSON dictionaries
    /// - Throws: A JSONError.couldNotCreateJSON if unable to get an array of JSON
    func arrayJSON() throws -> [JSON] {
        guard let jsonArray = (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)) as? [JSON] else { throw JSONError.couldNotCreateJSON }
        return jsonArray
    }
}
