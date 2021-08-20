//
//  utils.swift
//  SwiftyPixiv
//
//  Created by Fabio Mauersberger on 16.04.21.
//

import Foundation
import CryptoKit
    import CommonCrypto

public enum PixivError: Error {
    
    case RateLimitError
    case badProgramming(misstake: String)
    case targetNotFound(target: String)
    public enum AuthErrors: Error {
        case missingAuth(String?)
        case authFailed(String)
    }
    case unknownException(String)
}

public enum Publicity: String, Codable {
    case `public`, `private`
}

extension String {
    var MD5: String {
        if #available(macOS 10.15, *) {
        let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
        return computed.map { String(format: "%02hhx", $0) }.joined()
        } else {
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
