//
//  PixelEditingView.swift
//  NejeEngraver
//
//  Created by Andy Qua on 23/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

class PixelEditingView: NSView {
    let gridWidth : CGFloat
    var cellWidth : CGFloat = 0

    var dm = DataManager.instance
    
    var lastX : Int = -1
    var lastY : Int = -1
    
    var adding = CellState.on

    required init?(coder: NSCoder) {
        gridWidth = CGFloat(DataManager.instance.imageSize)

        super.init(coder:coder)
        cellWidth = self.bounds.width / gridWidth
        
    }
    
    override init(frame frameRect: NSRect) {
        gridWidth = CGFloat(DataManager.instance.imageSize)

        super.init(frame:frameRect)

        cellWidth = self.bounds.width / gridWidth
    }
    
    override func viewDidEndLiveResize() {
        cellWidth = self.bounds.width / gridWidth
        self.setNeedsDisplay(self.bounds)
    }
    
    func zoom( _ amt : Int) {
        cellWidth += CGFloat(amt)
        
        let width = gridWidth * cellWidth
        let height = gridWidth * cellWidth
        
        setFrameSize(CGSize(width:width, height:height))
        self.setNeedsDisplay(self.bounds)
    }
    
    func touchedAt( p: CGPoint ) {
        let cx = Int(p.x/cellWidth)
        let cy = Int(p.y/cellWidth)
        let index = cx + (511-cy)*Int(gridWidth)
        
        if cx < 0 || cx >= dm.imageSize || cy < 0 || cy >= dm.imageSize {
            return
        }
        
        lastX = cx
        lastY = cy
        
        if dm.pixels[index] == .off {
            adding = .on
        } else {
            adding = .off
        }
        
        dm.pixels[index] = adding
        setNeedsDisplay(bounds)
    }
    
    func draggedAt( p: CGPoint ) {
        let cx = Int(p.x/cellWidth)
        let cy = Int(p.y/cellWidth)
        
        if cx < 0 || cx >= dm.imageSize || cy < 0 || cy >= dm.imageSize {
            return
        }

        if cx != lastX || cy != lastY {
            print( "Dragging at \(cx),\(cy)  lx-\(lastX), ly-\(lastY)")
            let index = cx + (511-cy)*Int(gridWidth)
            
            dm.pixels[index] = adding
            
            setNeedsDisplay(bounds)
        }
        
        lastX = cx
        lastY = cy
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let visibleRect = self.frame.intersection(superview!.bounds)
        
        if let ctx = NSGraphicsContext.current?.cgContext{
            let cellW = cellWidth
//            print( "VisibleRect - \(visibleRect)")


            let startX = Int(visibleRect.origin.x / cellWidth)
            let endX = Int((visibleRect.origin.x + visibleRect.size.width) / cellWidth) + 1
            let startY = Int(visibleRect.origin.y / cellWidth)
            let endY = Int((visibleRect.origin.y + visibleRect.size.height) / cellWidth) + 2
            
            for cx in startX ..< endX {
                for cy in startY ..< endY {
                    if cx < dm.imageSize && cy < dm.imageSize {
                        
                        let c : NSColor
                        switch dm.pixels[Int(cx) + (511-Int(cy))*Int(gridWidth)] {
                        case .on:
                            c = .black
                        case .off:
                            c = .white
                        case .printed:
                            c = .red
                        case .disabled:
                            c = .blue
                        }
                        ctx.setFillColor( c.cgColor )
                        ctx.fill(CGRect(x: CGFloat(cx)*cellW, y: CGFloat(cy)*cellW, width: cellW, height: cellW))
                    }
                }
            }


            if cellWidth > 2 {

                let border = NSColor.lightGray
                ctx.setStrokeColor(border.cgColor)
                
                let gridW = CGFloat(gridWidth)

                // Draw borders
                for row in 0 ..< Int(gridWidth) {
                    let y = CGFloat(row)*cellW
                    if y >= dirtyRect.origin.y && y <= dirtyRect.origin.y + dirtyRect.size.height {
                        ctx.move(to: CGPoint(x:0, y:y))
                    
                        ctx.addLine(to: CGPoint(x:gridW*cellW, y:y))
                    }
                }
                
                for col in 0 ..< Int(gridWidth) {
                    let x = CGFloat(col)*cellW

                    if x >= dirtyRect.origin.x && x <= dirtyRect.origin.x + dirtyRect.size.width {
                        ctx.move(to: CGPoint(x:x, y:0))
                    
                        ctx.addLine(to: CGPoint(x:x, y:gridW*cellW ))
                    }
                }
                ctx.strokePath()
            }
        }
    }

}
