//
//  CertificateHelper.swift
//  MONK
//
//  Created by Jerry Mayers on 7/19/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

enum CertificateHelper: String {
    case badSSLBase = "*.badssl.com"
    case google = "www.google.com"
    
    
    var certificateURL: URL {
        let bundle = Bundle(for: Dummy.self)
        return bundle.urlForResource(rawValue, withExtension: "cer")!
    }
}

private class Dummy { }
