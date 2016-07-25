//
//  ServerTrustTests.swift
//  MONK
//
//  Created by Jerry Mayers on 7/19/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import XCTest
@testable import MONK

class ServerTrustTests: XCTestCase {
    
    func testWildcardHostMatching() {
        let wildcardHost: ServerTrustSettings.Host = "*.badssl.com"
        let baseHost: ServerTrustSettings.Host = "badssl.com"
        
        let wildcardPolicy = ServerTrustSettings.ServerTrustPolicy.defaultPolicy
        let basePolicy = ServerTrustSettings.ServerTrustPolicy.disabled
        
        let settings = ServerTrustSettings(policies: [wildcardHost : wildcardPolicy, baseHost : basePolicy])
        
        let policy0 = settings.policy(for: baseHost)
        XCTAssertNotNil(policy0, "Matching policy was not found, but was expected")
        if let policy0 = policy0 {
            XCTAssert(policy0 == basePolicy, "Policy not the expected policy")
        }
        
        let policy1 = settings.policy(for: "some.badssl.com")
        XCTAssertNotNil(policy1, "Matching policy was not found, but was expected")
        if let policy1 = policy1 {
            XCTAssert(policy1 == wildcardPolicy, "policy not the expeced policy")
        }
        
        let policy2 = settings.policy(for: "somebadssl.com")
        XCTAssertNil(policy2, "Matching policy was found, but was not expected")
    }
    
    func testPolicyEquality() {
        let defaultPolicy = ServerTrustSettings.ServerTrustPolicy.defaultPolicy
        let disabledPolicy = ServerTrustSettings.ServerTrustPolicy.disabled
        let customPolicy = ServerTrustSettings.ServerTrustPolicy.custom { (challange, completionHandler) in }
        let certPinPolicy = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [])
        let pkPinPolicy = ServerTrustSettings.ServerTrustPolicy.pinPublicKeys(certificates: [])
        
        XCTAssert(defaultPolicy == defaultPolicy, "Simple equals fail")
        XCTAssert(disabledPolicy == disabledPolicy, "Simple equals fail")
        XCTAssert(customPolicy == customPolicy, "Simple equals fail")
        XCTAssert(certPinPolicy == certPinPolicy, "Simple equals fail")
        XCTAssert(pkPinPolicy == pkPinPolicy, "Simple equals fail")
        
        let customPolicy1 = ServerTrustSettings.ServerTrustPolicy.custom { (challange, completionHandler) in print("Hello") }
        let file = FileDataType.file(url: URL(string: "http://google.com")!)
        let certPinPolicy1 = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [file])
        let pkPinPolicy1 = ServerTrustSettings.ServerTrustPolicy.pinPublicKeys(certificates: [file])
        
        XCTAssert(customPolicy == customPolicy1, "Complex equals fail")
        XCTAssert(certPinPolicy == certPinPolicy1, "Complex equals fail")
        XCTAssert(pkPinPolicy == pkPinPolicy1, "Complex equals fail")
        
        XCTAssert(defaultPolicy != disabledPolicy, "Simple equals fail")
        XCTAssert(disabledPolicy != customPolicy, "Simple equals fail")
        XCTAssert(customPolicy != certPinPolicy, "Simple equals fail")
        XCTAssert(certPinPolicy != pkPinPolicy, "Simple equals fail")
        XCTAssert(pkPinPolicy != defaultPolicy, "Simple equals fail")
    }
    
    func testCustomEvaluationBasicAuth() {
        let expectation = self.expectation(description: "Custom server trust policy")
        
        let host: ServerTrustSettings.Host = "httpbin.org"
        let username = "andrew"
        let password = "mobelux"
        
        var customPolicyEvaluated = false
        let policy = ServerTrustSettings.ServerTrustPolicy.custom { (challange, completionHandler) in
            customPolicyEvaluated = true
            let foundHost = challange.protectionSpace.host
            XCTAssert(host == foundHost, "Host doesn't match")
            print(challange.protectionSpace)
            let credential = URLCredential(user: username, password: password, persistence: .none)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
        }
        let trustSettings = ServerTrustSettings(policies: [host : policy])
        
        let networkController = NetworkController(serverTrustSettings: trustSettings)
        let url = URL(string: "http://httpbin.org/digest-auth/auth/\(username)/\(password)")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            XCTAssert(customPolicyEvaluated, "Custom policy was not evaluated")
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testPolicyHostMismatchCertPin() {
        let expectation = self.expectation(description: "Custom server trust policy")
        
        let host: ServerTrustSettings.Host = "httpbin.org"
        let username = "andrew"
        let password = "mobelux"
        
        let policy = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [])
        let trustSettings = ServerTrustSettings(policies: [host : policy])
        
        let networkController = NetworkController(serverTrustSettings: trustSettings)
        let url = URL(string: "http://httpbin.org/digest-auth/auth/\(username)/\(password)")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode >= 400 && statusCode < 500, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testCustomEvaluationNotAllowed() {
        let expectation = self.expectation(description: "Custom server trust policy")
        let baseHost = "badssl.com"
        let host: ServerTrustSettings.Host = "*.\(baseHost)"
        var customPolicyEvaluated = false
        let policy = ServerTrustSettings.ServerTrustPolicy.custom { (challange, completionHandler) in
            customPolicyEvaluated = true
            let foundHost = challange.protectionSpace.host
            XCTAssert(foundHost.hasSuffix(baseHost), "Host doesn't match")
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
        }
        let trustSettings = ServerTrustSettings(policies: [host : policy])
        
        let networkController = NetworkController(serverTrustSettings: trustSettings)
        
        let url = URL(string: "https://expired.badssl.com/")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success:
                XCTAssert(false, "We succeeded, but shouldn't have")
            case .failure:
                break
            }
            XCTAssert(customPolicyEvaluated, "Custom policy was not evaluated")
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testDefaultPolicy() {
        let expectation = self.expectation(description: "Default server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let policy = ServerTrustSettings.ServerTrustPolicy.defaultPolicy
        let trustSettings = ServerTrustSettings(policies: [host : policy])
        
        let networkController = NetworkController(serverTrustSettings: trustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testDisablePolicy() {
        let expectation = self.expectation(description: "Disable server trust policy")
        let host: ServerTrustSettings.Host = "*.badssl.com"
        let policy = ServerTrustSettings.ServerTrustPolicy.disabled
        let trustSettings = ServerTrustSettings(policies: [host : policy])
        
        let networkController = NetworkController(serverTrustSettings: trustSettings)
        
        let url = URL(string: "https://expired.badssl.com/")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testSuccessfulCertificatePinningFromURL() {
        let expectation = self.expectation(description: "Certificate pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.badSSLBase.certificateURL
        
        let urlPolicy = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [.file(url: pinnedCertURL)])
        
        let urlTrustSettings = ServerTrustSettings(policies: [host : urlPolicy])
        
        let networkController = NetworkController(serverTrustSettings: urlTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testSuccessfulCertificatePinningFromData() {
        let expectation = self.expectation(description: "Certificate pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.badSSLBase.certificateURL
        let pinnedCertData = try! Data(contentsOf: pinnedCertURL)
        
        let dataPolicy = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [.data(data: pinnedCertData)])
        
        let dataTrustSettings = ServerTrustSettings(policies: [host : dataPolicy])
        
        let networkController = NetworkController(serverTrustSettings: dataTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUnsuccessfulCertificatePinningFromURL() {
        let expectation = self.expectation(description: "Certificate pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.google.certificateURL
        
        let urlPolicy = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [.file(url: pinnedCertURL)])
        
        let urlTrustSettings = ServerTrustSettings(policies: [host : urlPolicy])
        
        let networkController = NetworkController(serverTrustSettings: urlTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success:
                XCTAssert(false, "We succeeded, but we pinned a nonmatching certificate")
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUnsuccessfulCertificatePinningFromData() {
        let expectation = self.expectation(description: "Certificate pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.google.certificateURL
        let pinnedCertData = try! Data(contentsOf: pinnedCertURL)
        
        let dataPolicy = ServerTrustSettings.ServerTrustPolicy.pinCertificates(certificates: [.data(data: pinnedCertData)])
        
        let dataTrustSettings = ServerTrustSettings(policies: [host : dataPolicy])
        
        let networkController = NetworkController(serverTrustSettings: dataTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success:
                XCTAssert(false, "We succeeded, but we pinned a nonmatching certificate")
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testSuccessfulPublicKeyPinningFromURL() {
        let expectation = self.expectation(description: "PublicKey pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.badSSLBase.certificateURL
        
        let urlPolicy = ServerTrustSettings.ServerTrustPolicy.pinPublicKeys(certificates: [.file(url: pinnedCertURL)])
        
        let urlTrustSettings = ServerTrustSettings(policies: [host : urlPolicy])
        
        let networkController = NetworkController(serverTrustSettings: urlTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure(let error):
                print(error)
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testSuccessfulPublicKeyPinningFromData() {
        let expectation = self.expectation(description: "PublicKey pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.badSSLBase.certificateURL
        let pinnedCertData = try! Data(contentsOf: pinnedCertURL)
        
        let dataPolicy = ServerTrustSettings.ServerTrustPolicy.pinPublicKeys(certificates: [.data(data: pinnedCertData)])
        
        let dataTrustSettings = ServerTrustSettings(policies: [host : dataPolicy])
        
        let networkController = NetworkController(serverTrustSettings: dataTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success(let statusCode, _):
                XCTAssert(statusCode == 200, "Invalid status code")
            case .failure:
                XCTAssert(false, "We failed to process the task")
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUnsuccessfulPublicKeyPinningFromURL() {
        let expectation = self.expectation(description: "PublicKey pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.google.certificateURL
        
        let urlPolicy = ServerTrustSettings.ServerTrustPolicy.pinPublicKeys(certificates: [.file(url: pinnedCertURL)])
        
        let urlTrustSettings = ServerTrustSettings(policies: [host : urlPolicy])
        
        let networkController = NetworkController(serverTrustSettings: urlTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success:
                XCTAssert(false, "We succeeded, but we pinned a nonmatching certificate")
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
    
    func testUnsuccessfulPublicKeyPinningFromData() {
        let expectation = self.expectation(description: "PublicKey pinning server trust policy")
        let host: ServerTrustSettings.Host = "badssl.com"
        let pinnedCertURL = CertificateHelper.google.certificateURL
        let pinnedCertData = try! Data(contentsOf: pinnedCertURL)
        
        let dataPolicy = ServerTrustSettings.ServerTrustPolicy.pinPublicKeys(certificates: [.data(data: pinnedCertData)])
        
        let dataTrustSettings = ServerTrustSettings(policies: [host : dataPolicy])
        
        let networkController = NetworkController(serverTrustSettings: dataTrustSettings)
        
        let url = URL(string: "https://badssl.com")!
        let request = DataRequest(url: url, httpMethod: .get)
        let task = networkController.data(with: request)
        
        task.addCompletion { (result) in
            switch result {
            case .success:
                XCTAssert(false, "We succeeded, but we pinned a nonmatching certificate")
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        task.resume()
        
        waitForExpectations(timeout: TestConstants.testTimeout, handler: nil)
    }
}
