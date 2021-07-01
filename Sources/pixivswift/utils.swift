//
//  utils.swift
//  SwiftyPixiv
//
//  Created by Fabio Mauersberger on 16.04.21.
//

import Foundation
import CryptoKit

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

extension String {
    var MD5: String {
        let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
        return computed.map { String(format: "%02hhx", $0) }.joined()
    }
}
