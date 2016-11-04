//
//  AppDelegate.swift
//  NejeEngraver
//
//  Created by Andy Qua on 22/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


    @IBAction func testModeToggled(_ sender: Any) {
        if let menu = sender as? NSMenuItem {
            menu.state = menu.state == 1 ? 0 : 1
            
            NotificationCenter.default.post(name: NSNotification.Name("TestMode"), object: nil, userInfo: ["on":menu.state == 1 ? true : false])
        }
    }
}

