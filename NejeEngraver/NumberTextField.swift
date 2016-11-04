//
//  NumberTextField.swift
//  NejeEngraver
//
//  Created by Andy Qua on 23/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

class NumberTextField: NSTextField {
    
    var lastValue : Int32 = 15
    override func textDidChange(_ notification: Notification) {
        var val = self.intValue
        val = min( val, 241)
        val = max( val, 0)
        if val == 0 || val == 241 {
            val = lastValue
        }
        self.intValue = val
        lastValue = val

        super.textDidChange( notification)
    }

    override func textDidEndEditing(_ notification: Notification) {
        var val = self.intValue
        val = min( val, 240)
        val = max( val, 1)
        self.intValue = val
        
        super.textDidEndEditing(notification)
    }
    
}
