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
print("Sorry, pixivauth is not available on non-Apple platforms right now.")
#endif
