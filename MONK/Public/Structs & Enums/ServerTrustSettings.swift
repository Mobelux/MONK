//
//  ServerTrustSettings.swift
//  MONK
//
//  Created by Jerry Mayers on 7/19/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

public struct ServerTrustSettings {
    
    /**
        The trust policy to use for a specific host. Two policies are considered equal if they have the same case (associated values are not considered).
     
        - defaultPolicy:    Validates that the host matches the host entry on the certificate that the host sends
        - pinCertificates:  Validates that the certificate that the host sends, exactly matches a local copy of the certificate & validates that the host matches the host entry on the certificate that the host sends. Once the host's certificate expires, the app will fail to validate any replacement certs, until those certs are added to the app.
        - pinPublicKeys:    Validates that the public key on the certificate that the host sends, exactly matches the public key on the local copy of a certificate & validates that the host matches the host entry on the certificate that the host sends. This is a good option so that if the cert expires, and is renewed as long as the same public/private key pair is used in cert generation, the app will still validate the new certificate. This is the best balance of security, and conveinience.
        - custom:           A custom handler that will be called for all types of authentication methods, and gives you total control over the authentication
        - disabled:         Don't do any validation on the host/connection, always approve the connection
    */
    public enum ServerTrustPolicy: Equatable {
        case defaultPolicy
        case pinCertificates(certificates: [FileDataType])
        case pinPublicKeys(certificates: [FileDataType])
        case custom(handler: (challange: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)
        case disabled
    }
    
    public typealias Host = String
    private let policies: [Host : ServerTrustPolicy]
    
    /**
        Initialize a server trust settings
     
        - parameter policies:   A dictionary of policies that maps hosts, to the policy for that host. There are two primary ways to define a host. The first is a basic hostname: `mobelux.com`, this will only match exact host names, so `jobs.mobelux.com` won't match. The second way is wildcard host: `*.mobelux.com` which will then correctly match `jobs.mobelux.com`. Don't add multiple wildcard policies for the same host, as which one this will use is undefined. However it is valid to have multiple basic host policies, along with a single wildcard policy for that same host. The system will always prioritize an exact basic match before falling back to using a wildcard host. So if you register `jobs.mobelux.com` and `*.mobelux.com` then browse to `jobs.mobelux.com` the first policy will be used, but if you browse to `native.jobs.mobelux.com` then the wildcard policy will be used.
    */
    public init(policies: [Host : ServerTrustPolicy]) {
        self.policies = policies
    }
}

public func ==(lhs: ServerTrustSettings.ServerTrustPolicy, rhs: ServerTrustSettings.ServerTrustPolicy) -> Bool {
    switch (lhs, rhs) {
    case (.defaultPolicy, .defaultPolicy):
        return true
    case (.pinCertificates, .pinCertificates):
        return true
    case (.pinPublicKeys, .pinPublicKeys):
        return true
    case (.custom, .custom):
        return true
    case (.disabled, .disabled):
        return true
    default:
        return false
    }
}

extension ServerTrustSettings {
    
    /**
        Evaluates a server challange using any user supplied policies (if ones for this host are found)
     
        - parameter challange:          The challange that requires evaluation
        - parameter completionHandler:  The completion handler to call with the results of the evaluation
 
    */
    func evaluateChallange(challange: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let policy = policy(for: challange.protectionSpace.host) else {
            ServerTrustSettings.performDefaultHandling(completionHandler: completionHandler)
            return
        }
       
        switch policy {
        case .disabled:
            ServerTrustSettings.successHandling(completionHandler: completionHandler, serverTrust: challange.protectionSpace.serverTrust)
        case .defaultPolicy:
            ServerTrustSettings.evaluateChallange(challange: challange, forDefaultPolicyWithCompletionHandler: completionHandler)
        case .custom(let handler):
            handler(challange: challange, completionHandler: completionHandler)
        case .pinCertificates(let certificates):
            ServerTrustSettings.evaluateChallange(challange: challange, forCertificates: certificates, completionHandler: completionHandler)
        case .pinPublicKeys(let certificates):
            ServerTrustSettings.evaluateChallange(challange: challange, forPublicKeysInCertificates: certificates, completionHandler: completionHandler)
        }
    }

    /**
        Gets the policy (if there is one) for a host
     
        - parameter host:   The host that you want the policy for
     
        - returns:          The policy that matches the one configured for the `host`. If there are multiple policies for a host, it prefers the policy with an exact host match, falling back to a wildcard match if available
 
    */
    func policy(for host: Host) -> ServerTrustPolicy? {
        // If we have an exact match use that
        if let policy = policies[host] {
            return policy
        }
        
        // We didn't find an exact host match, so look for a wildcard match
        let wildcardPrefix = "*."
        let definesPolicyHosts: [Host] = policies.keys.flatMap({ return $0.hasPrefix(wildcardPrefix) ? $0 : nil })
        for definedHost in definesPolicyHosts {
            if let wildcardRange = definedHost.range(of: wildcardPrefix), definedHost.characters.count > 2 {
                let baseDefinedHost = definedHost.substring(from: wildcardRange.upperBound)
                if host.hasSuffix(".\(baseDefinedHost)") {
                    return policies[definedHost]
                }
            }
        }

        return nil
    }
    
    private static func performDefaultHandling(completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
    
    private static func successHandling(completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void, serverTrust: SecTrust?) {
        let credential: URLCredential? = {
            if let serverTrust = serverTrust {
                return URLCredential(trust: serverTrust)
            } else {
                return nil
            }
        }()
        completionHandler(.useCredential, credential)
    }
    
    private static func failureHandling(completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    private static func evaluateHost(host: Host, serverTrust: SecTrust) -> Bool {
        let secPolicy = SecPolicyCreateSSL(true, host)
        SecTrustSetPolicies(serverTrust, secPolicy)
        
        return serverTrust.isValid
    }
    
    private static func evaluateChallange(challange: URLAuthenticationChallenge, forDefaultPolicyWithCompletionHandler completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challange.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challange.protectionSpace.serverTrust else {
            performDefaultHandling(completionHandler: completionHandler)
            return
        }
        
        if evaluateHost(host: challange.protectionSpace.host, serverTrust: serverTrust) {
            successHandling(completionHandler: completionHandler, serverTrust: serverTrust)
        } else {
            failureHandling(completionHandler: completionHandler)
        }
    }
    
    private static func evaluateChallange(challange: URLAuthenticationChallenge, forCertificates certificatesFileData: [FileDataType], completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challange.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challange.protectionSpace.serverTrust else {
            performDefaultHandling(completionHandler: completionHandler)
            return
        }
        
        guard evaluateHost(host: challange.protectionSpace.host, serverTrust: serverTrust) else {
            failureHandling(completionHandler: completionHandler)
            return
        }
        
        let pinnedCertificates = certificates(for: certificatesFileData)
        
        SecTrustSetAnchorCertificates(serverTrust, pinnedCertificates)
        SecTrustSetAnchorCertificatesOnly(serverTrust, true)
        if serverTrust.isValid {
            successHandling(completionHandler: completionHandler, serverTrust: serverTrust)
        } else {
            failureHandling(completionHandler: completionHandler)
        }
    }
    
    private static func evaluateChallange(challange: URLAuthenticationChallenge, forPublicKeysInCertificates certificatesFileData: [FileDataType], completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challange.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challange.protectionSpace.serverTrust else {
            performDefaultHandling(completionHandler: completionHandler)
            return
        }
        
        guard evaluateHost(host: challange.protectionSpace.host, serverTrust: serverTrust) else {
            failureHandling(completionHandler: completionHandler)
            return
        }
        
        let pinnedCertificates = certificates(for: certificatesFileData)
        let pinnedPublicKeys: [SecKey] = pinnedCertificates.map({ $0.publicKey() }).flatMap { $0 }
        
        for publicKey in serverTrust.publicKeys() {
            for pinnedPublicKey in pinnedPublicKeys {
                if let pinnedPublicKeyData = SecKeyCopyExternalRepresentation(pinnedPublicKey, nil), let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil), pinnedPublicKeyData == publicKeyData {
                    successHandling(completionHandler: completionHandler, serverTrust: serverTrust)
                    return
                }
            }
        }
        
        failureHandling(completionHandler: completionHandler)
    }
    
    private static func certificates(for fileData: [FileDataType]) -> [SecCertificate] {
        let certs = fileData.flatMap { SecCertificateCreateWithData(fileData: $0) }
        return certs
    }
}
