//
//  ImageView.swift
//  NejeEngraver
//
//  Created by Andy Qua on 22/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa


class ImageView: NSView {
    
    var cellWidth : CGFloat = 4
    
    var dm = DataManager.instance
    
    var acceptableTypes: Set<String> { return [NSURLPboardType,NSFilenamesPboardType] }
    let filteringOptions = [NSPasteboardURLReadingContentsConformToTypesKey:NSImage.imageTypes()]
    
    
    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }
    required init?(coder: NSCoder) {
        
        super.init(coder:coder)
        
        cellWidth = self.bounds.width / CGFloat(dm.imageSize)
        
        register(forDraggedTypes: Array(acceptableTypes))
    }
    
    
    func printPixel( row: Int, col: Int ) {
        dm.pixels[col + (row*dm.imageSize)] = .printed
        self.setNeedsDisplay(bounds)
    }
    
    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        
        var canAccept = false
        
        let pasteBoard = draggingInfo.draggingPasteboard()
        
        if pasteBoard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) {
            canAccept = true
        }
        return canAccept
        
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isReceivingDrag = false
        let pasteBoard = sender.draggingPasteboard()
        
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: [:]) as? [URL], urls.count > 0 {
            dump( "Found URLs - \(urls)")
            
            // Load first URL
            _ = dm.loadImage( fromUrl:urls[0] )
            setNeedsDisplay(bounds)
            return true
        }
        
        return false
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isReceivingDrag {
            NSColor.selectedControlColor.set()
            
            let path = NSBezierPath(rect:bounds)
            path.lineWidth = 2
            path.stroke()
        }
        
        if let ctx = NSGraphicsContext.current()?.cgContext{
            // Drawing code here.
            for row in 0 ..< dm.imageSize {
                for col in 0 ..< dm.imageSize {
                    let c : NSColor
                    switch dm.pixels[col + (row*dm.imageSize)] {
                    case .on:
                        c = .black
                    case .off:
                        c = .white
                    case .printed:
                        c = .red
                    case .disabled:
                        c = .blue
                    }
                    
                    let x = CGFloat( col ) * cellWidth
                    let y = CGFloat(511-row) * cellWidth
                    ctx.setFillColor( c.cgColor )
                    ctx.fill(CGRect(x: x, y: y, width: cellWidth, height: cellWidth))
                }
            }
        }
    }
    
}
