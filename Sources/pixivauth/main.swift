//
//  main.swift
//  pixivauth
//
//  Created by theBreadCompany on 30.05.22.
//

#if os(macOS)
import Cocoa

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
#else
import Foundation
NSLog("Sorry, pixivauth is not available right now.")
#endif
