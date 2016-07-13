//
//  JSON.swift
//  MONK
//
//  Created by Jerry Mayers on 7/11/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

public typealias JSONKey = NSObject
public typealias JSONValue = AnyObject
public typealias JSON = [JSONKey : JSONValue]

public enum JSONError: ErrorProtocol {
    case notValidJSON
    case couldNotCreateData
    case couldNotCreateJSON
}

public extension Dictionary where Key: JSONKey, Value: JSONValue {
    
    /**
        Creates a `Data` from some JSON
     
        - returns: a valid `Data` or throws a `JSONError`
    */
    public func jsonData() throws -> Data {
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
    public func json() throws -> JSON {
        guard let json = (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)) as? JSON else { throw JSONError.couldNotCreateJSON }
        return json
    }
}
