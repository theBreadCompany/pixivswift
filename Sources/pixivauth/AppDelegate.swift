//
//  AppDelegate.swift
//  pixivauth
//
//  Created by Fabio Mauersberger on 28.05.22.
//

import AppKit

//@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowDelegate: WindowDelegate?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600), styleMask: [.titled, .closable], backing: NSWindow.BackingStoreType.buffered, defer: false)
        windowDelegate = WindowDelegate()
        window.delegate = windowDelegate
        window.title = "pixivauth"
        window.contentViewController = ViewController()
        window.makeKeyAndOrderFront(window)
        window.center()
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}
