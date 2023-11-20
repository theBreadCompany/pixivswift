//
//  utils.swift
//  pixivswiftWrapper
//
//  Created by theBreadCompany on 06.05.21.
//

import Foundation

public extension FileManager {

    func directoryExists(_ atPath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: atPath, isDirectory:&isDirectory)
        return exists && isDirectory.boolValue
    }
}

public extension Int {
    /// Returns the higher of the two values
    static func >>(lhs: Int, rhs: Int) -> Int {
        return (lhs > rhs) ? lhs : rhs
    }
    
    /// Returns the lower of the two values
    static func <<(lhs: Int, rhs: Int) -> Int {
        return (lhs < rhs) ? lhs : rhs
    }
}
