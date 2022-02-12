//
//  utils.swift
//  pixivswift
//
//  Created by Fabio Mauersberger on 16.04.21.
//

import Foundation
import CryptoKit
import CommonCrypto

/// `Error`s that may occur when (trying to) interface with pixiv
public enum PixivError: Error {
    
    /// Occurs when the server receives to many requests in a too short time
    case RateLimitError
    /// Server doesn't know about this thing.
    case targetNotFound(String)
    /// Mostly Framework-internal error; occurs, when, well, no data
    case responseAcquirationFailed(String)
    /// `Errors` that may occur especially in the authorization process
    public enum AuthErrors: Error {
        /// tried to access the API without any authorization
        case missingAuth(String?)
        /// failed when trying to authorize
        case authFailed(String)
    }
    /// unknown/undefined situation
    case unknownException(String)
}

public enum Publicity: String, Codable {
    case `public`, `private`
}

public enum HttpMethod: String {
    case GET, POST, DELETE
}

extension String {
    var MD5: String {
        if #available(macOS 10.15,iOS 13, *) {
            let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
            return computed.map { String(format: "%02hhx", $0) }.joined()
        } else {
            // thanks to https://stackoverflow.com/a/55346435
            let length = Int(CC_MD5_DIGEST_LENGTH)
            var digest = [UInt8](repeating: 0, count: length)

            if let d = self.data(using: .utf8) {
                _ = d.withUnsafeBytes { body -> String in
                    CC_MD5(body.baseAddress, CC_LONG(d.count), &digest)
                    return ""
                }
            }

            return (0 ..< length).reduce("") {
                $0 + String(format: "%02x", digest[$1])
            }
        }
    }
}
