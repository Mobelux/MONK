//
//  SecTrust+CertsKeys.swift
//  MONK
//
//  Created by Jerry Mayers on 7/19/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

extension SecTrust {
    func certificates() -> [SecCertificate] {
        var certs = [SecCertificate]()
        
        for index in 0 ..< SecTrustGetCertificateCount(self) {
            if let certificate = SecTrustGetCertificateAtIndex(self, index) {
                certs.append(certificate)
            }
        }
        return certs
    }
    
    func publicKeys() -> [SecKey] {
        let publicKeys = certificates().flatMap { $0.publicKey() }
        return publicKeys
    }
    
    var isValid: Bool {
        var trustResult = SecTrustResultType.invalid
        if SecTrustEvaluate(self, &trustResult) == errSecSuccess {
            return trustResult == .unspecified || trustResult == .proceed
        } else {
            return false
        }
    }
}

func SecCertificateCreateWithData(fileData: FileDataType) -> SecCertificate? {
    guard let data = try? fileData.readData() else { return nil }
    return SecCertificateCreateWithData(nil, data as CFData)
}

extension SecCertificate {
    func publicKey() -> SecKey? {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(self, SecPolicyCreateBasicX509(), &trust)
        guard let validTrust = trust, status == errSecSuccess else { return nil }
        
        return SecTrustCopyPublicKey(validTrust)
    }
}
