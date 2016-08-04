//
//  URLSessionConfiguration+Default.swift
//  MONK
//
//  Created by Jerry Mayers on 7/12/16.
//  Copyright © 2016 Mobelux. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

public extension URLSessionConfiguration {
    
    /**
        Returns a newly created default session configuration object. This is just a simple wrapper around `default` that calls `configureMobeluxAdditionalHeaders()` before returning
     
        The default session configuration uses a persistent disk-based cache (except when the result is downloaded to a file) and stores credentials in the user’s keychain. It also stores cookies (by default) in the same shared cookie store as the NSURLConnection and NSURLDownload classes.
     
        Modifying the returned session configuration object does not affect any configuration objects returned by future calls to this method, and does not change the default behavior for existing sessions. It is therefore always safe to use the returned object as a starting point for additional customization.
    */
    public static var mobeluxDefault: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.configureMobeluxAdditionalHeaders()
        return config
    }
    
    /**
        Returns a session configuration object that allows HTTP and HTTPS uploads or downloads to be performed in the background. This is just a simple wrapper around `background(withIdentifier:)` that calls `configureMobeluxAdditionalHeaders()` before returning
     
        Use this method to initialize a configuration object suitable for transferring data files while the app runs in the background. A session configured with this object hands control of the transfers over to the system, which handles the transfers in a separate process. In iOS, this configuration makes it possible for transfers to continue even when the app itself is suspended or terminated.
     
        If an iOS app is terminated by the system and relaunched, the app can use the same identifier to create a new configuration object and session and retrieve the status of transfers that were in progress at the time of termination. This behavior applies only for normal termination of the app by the system. If the user terminates the app from the multitasking screen, the system cancels all of the session’s background transfers. In addition, the system does not automatically relaunch apps that were force quit by the user. The user must explicitly relaunch the app before transfers can begin again.
     
        You can configure an background session to schedule transfers at the discretion of the system for optimal performance using the `isDiscretionary` property. When transferring large amounts of data, you are encouraged to set the value of this property to `true`.
     
        - parameter identifier: The unique identifier for the configuration object. This parameter must not be `nil` or an empty string.
     
        - returns:  A configuration object that causes upload and download tasks to be performed by the system in a separate process, with `configureMobeluxAdditionalHeaders()` applied to the configuration object.
    */
    public static func mobeluxBackground(withIdentifier identifier: String) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.configureMobeluxAdditionalHeaders()
        return config
    }
    
    /**
        Sets the `httpAdditionalHeaders` to the default values for `Accept`, `Accept-Language`, `Accept-Encoding`, and `User-Agent`. 
     
        - descussion: The user agent will be set to `<appName> v<appVersion> (<appBuild#>) - (<deviceModelName>, <displayScale>x, <osVersionAndBuild>)`.
    */
    public func configureMobeluxAdditionalHeaders() {
        httpAdditionalHeaders = ["Accept" : ContentType.json.rawValue,
                                 "Accept-Language" : "en",
                                 "Accept-Encoding" : "gzip",
                                 "User-Agent" : userAgent]
    }
}

private var userAgent: String = {
    let osVersionAndBuild = ProcessInfo.processInfo.operatingSystemVersionString
    let bundle = Bundle.main
    let deviceInfo = "(\(modelName()), \(displayScale()), \(osVersionAndBuild))"
    
    guard let info = bundle.infoDictionary,
        let appName = info["CFBundleDisplayName"],
        let appVersion = info["CFBundleShortVersionString"],
        let appBuild = info[kCFBundleVersionKey as String] else {
        
            return "Mobelux NetworkKit - \(deviceInfo)"
    }
    
    return "\(appName) v\(appVersion) (\(appBuild)) - \(deviceInfo)"
}()

private func modelName() -> String {
    var systemInfo = utsname()
    let _  = uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
}

private func displayScale() -> String {
    var scale: CGFloat = 1
    #if os(iOS) || os(watchOS) || os(tvOS)
        scale = UIScreen.main.scale
    #elseif os(OSX)
        if let screens = NSScreen.screens() {
            for screen in screens {
                if screen.backingScaleFactor > scale {
                    scale = screen.backingScaleFactor
                }
            }
        }
    #endif
    
    return String(format: "%0.1fx", scale)
}
