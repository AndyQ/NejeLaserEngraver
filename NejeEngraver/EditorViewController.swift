//
//  EditorViewController.swift
//  NejeEngraver
//
//  Created by Andy Qua on 23/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {

    @IBOutlet weak var scrollView: NSScrollView!
    
    var editorView : PixelEditingView!
    
    var onClose : (()->())?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .grooveBorder
        scrollView.contentView.copiesOnScroll = false
        scrollView.contentView.postsBoundsChangedNotifications = true

        // Create our view
        let dm = DataManager.instance
        editorView = PixelEditingView(frame:NSRect(x:0, y:0, width:dm.imageSize*10, height:dm.imageSize*10))
        scrollView.documentView = editorView
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.boundsDidChange(_:)), name: NSView.boundsDidChangeNotification, object: scrollView.contentView)

    }
    
    override func viewWillDisappear() {
        onClose?()
    }
    
    @objc func boundsDidChange( _ notification : NSNotification ) {
        print( "Change - \(scrollView.contentView.bounds)" )
        scrollView.documentView?.setNeedsDisplay(scrollView.contentView.bounds)
    }
    
    override func mouseDown(with event: NSEvent) {
        let p = self.view.convert(event.locationInWindow, to: editorView)
        if p.x < 0 || p.y < 0 || p.x > editorView.frame.width || p.y > editorView.frame.height {
            return
        }
        
        editorView.touchedAt( p: p )
    }
    
    override func mouseDragged(with event: NSEvent) {
        let p = self.view.convert(event.locationInWindow, to: editorView)
        if p.x < 0 || p.y < 0 || p.x > editorView.frame.width || p.y > editorView.frame.height {
            return
        }
        
        editorView.draggedAt( p:p )
    }

    
    var mag : CGFloat = 0.0
    override func magnify(with event: NSEvent) {        
        mag += event.magnification
//        Swift.print( "Mag - \(mag)")
        if mag >= 0.1 {
            mag -= 0.1
            editorView.zoom(1)
        } else if mag <= -0.1 {
            mag += 0.1
            editorView.zoom(-1)
        }
    }
}
