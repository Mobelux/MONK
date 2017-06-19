//
//  DataHelper.swift
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
