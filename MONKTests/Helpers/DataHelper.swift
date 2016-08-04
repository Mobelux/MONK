//
//  DataHelper.swift
//  MONK
//
//  Created by Jerry Mayers on 7/5/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation
import MONK

enum DataJSON: String {
    case posts1 = "posts1"
    case photos = "photos"
}

enum DataImage: String {
    case compiling = "compiling"
}

private class Dummy { }

struct DataHelper {
    static func data(for json: DataJSON) -> Data {
        let bundle = Bundle(for: Dummy.self)
        let url = bundle.url(forResource: json.rawValue, withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return data
    }
    
    static func imageURL(for image: DataImage) -> URL {
        let bundle = Bundle(for: Dummy.self)
        let url = bundle.url(forResource: image.rawValue, withExtension: "png")
        return url!
    }
    
    static func imageData(for image: DataImage) -> Data {
        let url = imageURL(for: image)
        return try! Data(contentsOf: url)
    }
}

extension Data {
    var jsonString: String {
        return String(data: self, encoding: .utf8)!
    }
}

func ==(lhs: JSON, rhs: JSON) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}
