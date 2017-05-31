//
//  SecTrust+CertsKeys.swift
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
