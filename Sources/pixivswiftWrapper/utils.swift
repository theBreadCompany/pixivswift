//
//  utils.swift
//  pixivswiftWrapper
//
//  Created by Fabio Mauersberger on 06.05.21.
//

import Foundation

public extension FileManager {

    func directoryExists(_ atPath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: atPath, isDirectory:&isDirectory)
        return exists && isDirectory.boolValue
    }
}
