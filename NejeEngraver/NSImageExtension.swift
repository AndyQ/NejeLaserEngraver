//
//  NSImageExtension.swift
//  NejeEngraver
//
//  Created by Andy Qua on 23/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import AppKit

func clamp( _ z: Int ) -> UInt8 {
    return UInt8(z > 255 ? 255 : z < 0 ? 0 : z)
}

enum RenderingStyle {
    case FloydSteinbergDithering
    case AveragePixelSampling
    case BlackAndWhite
}


extension NSImageRep {
    
    func binaryRepresentation( _ colorThreshold:Int, renderingStyle: RenderingStyle ) -> NSBitmapImageRep? {

        var rep : NSBitmapImageRep
        
        if renderingStyle == .AveragePixelSampling {
            guard let grayRep = self.blackAndWhiteRepresentation() else { return nil }
            rep = grayRep
        } else {
            guard let grayRep = self.greyRepresentation() else { return nil }
            rep = grayRep
        }
        
        let numberOfCols = rep.pixelsWide
        let numberOfRows = rep.pixelsHigh
    
        let newRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                      pixelsWide: numberOfCols,
                                      pixelsHigh: numberOfRows,
                                      bitsPerSample: 1,
                                      samplesPerPixel: 1,
                                      hasAlpha: false,
                                      isPlanar: false,
                                      colorSpaceName: NSColorSpaceName.calibratedWhite,
                                      bytesPerRow: 0,
                                      bitsPerPixel: 0)!
        
        guard let bitmapDataSource = rep.bitmapData else { return nil }

        // iterate over all pixels
        let grayBPR = rep.bytesPerRow
        let pWide = newRep.pixelsWide
        

        // Floyd-Steinberg Dithering

        if renderingStyle == .FloydSteinbergDithering {
            for row in 0 ..< numberOfRows-1 {
                let currentRowData = 0 + row * grayBPR
                let nextRowData = currentRowData + grayBPR
                
                for col in 1 ..< numberOfCols {
                    let origValue : UInt8 = bitmapDataSource[currentRowData+col];
                    let newValue : UInt8 = (origValue > UInt8(colorThreshold)) ? 255 : 0;
                    let error : Int = -(Int(newValue) - Int(origValue))

                    bitmapDataSource[col+currentRowData] = newValue
                    
                    bitmapDataSource[col+1+currentRowData] = clamp(Int(bitmapDataSource[col+1+currentRowData]) + (7 * error / 16))
                    bitmapDataSource[col-1+nextRowData] = clamp( Int(bitmapDataSource[col-1+nextRowData]) + (3 * error / 16))
                    bitmapDataSource[col+nextRowData] = clamp( Int(bitmapDataSource[col+nextRowData]) + (5 * error / 16))
                    bitmapDataSource[col+1+nextRowData] = clamp( Int(bitmapDataSource[col+1+nextRowData]) + (error / 16))
                }
            }
        } else if renderingStyle == .AveragePixelSampling {
            for row in 0 ..< numberOfRows {
                for col in 0 ..< pWide {
                    let gray = bitmapDataSource[col + row * grayBPR]
                    if  gray > UInt8(colorThreshold) {
                        bitmapDataSource[col + row * grayBPR] = 255
                    } else {
                        bitmapDataSource[col + row * grayBPR] = 0
                    }
                }
            }
        } else {
            for row in 0 ..< numberOfRows {
                for col in 0 ..< pWide {
                    let gray = bitmapDataSource[col + row * grayBPR]
                    if  gray > UInt8(colorThreshold) {
                        bitmapDataSource[col + row * grayBPR] = 255
                    } else {
                        bitmapDataSource[col + row * grayBPR] = 0
                    }
                }
            }
        }

        // Dummy files for testing conversion
        let file = URL( fileURLWithPath:Utils.cacheFolder() + "/black.png")
        print( "b&w file written to \(file)")
        try? rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])?.write(to: file)
        return rep
    }
    
    func greyRepresentation( ) -> NSBitmapImageRep? {

        let newRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: self.pixelsWide,
                                   pixelsHigh: self.pixelsHigh,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 1,
                                   hasAlpha: false,
                                   isPlanar: false,
                                   colorSpaceName: NSColorSpaceName.calibratedWhite,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        
        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext(bitmapImageRep: newRep)
        NSGraphicsContext.current = ctx

        self.draw(in: NSMakeRect(0, 0, CGFloat(newRep.pixelsWide), CGFloat(newRep.pixelsHigh)))
        
        NSGraphicsContext.restoreGraphicsState()

        let file = URL( fileURLWithPath:Utils.cacheFolder() + "/gray.png")
        print( "Greyfile written to \(file)")
        try? newRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])?.write(to: file)

        return newRep
    }
    
    func blackAndWhiteRepresentation( ) -> NSBitmapImageRep? {
        
        let newRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                      pixelsWide: self.pixelsWide,
                                      pixelsHigh: self.pixelsHigh,
                                      bitsPerSample: 1,
                                      samplesPerPixel: 1,
                                      hasAlpha: false,
                                      isPlanar: false,
                                      colorSpaceName: NSColorSpaceName.calibratedWhite,
                                      bytesPerRow: 0, bitsPerPixel: 0)!
        
        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext(bitmapImageRep: newRep)
        NSGraphicsContext.current = ctx
        
        self.draw(in: NSMakeRect(0, 0, CGFloat(newRep.pixelsWide), CGFloat(newRep.pixelsHigh)))
        
        NSGraphicsContext.restoreGraphicsState()
        
        let file = URL( fileURLWithPath:Utils.cacheFolder() + "/blackwhite.png")
        print( "Greyfile written to \(file)")
        try? newRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])?.write(to: file)
        
        return newRep
    }

}

extension NSImage {
    func resizeImage(_ targetWidth: Int, _ targetHeight: Int, keepAspect: Bool = true) -> NSImage {
        
        
        // See if we want to keep the current aspect ratio
        let targetSize = NSSize(width:targetWidth, height:targetHeight)
        var scaledWidth = CGFloat(targetSize.width)
        var scaledHeight = CGFloat(targetSize.height)
        
        var originPoint = NSPoint.zero
        if keepAspect {
            let imageSize = self.size
            
            
            var scaleFactor : CGFloat = 0.0;
            
            if !imageSize.equalTo(targetSize)
            {
                let widthFactor = targetSize.width / imageSize.width
                let heightFactor = targetSize.height / imageSize.height
                
                if widthFactor < heightFactor {
                    scaleFactor = widthFactor
                } else {
                    scaleFactor = heightFactor
                }
                
                scaledWidth  = imageSize.width  * scaleFactor;
                scaledHeight = imageSize.height * scaleFactor;
                
                if widthFactor < heightFactor {
                    originPoint.y = (targetSize.height - scaledHeight) * 0.5
                } else if widthFactor > heightFactor {
                    originPoint.x = (targetSize.width - scaledWidth) * 0.5
                }
            }
        }
        
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: targetWidth,
                                   pixelsHigh: targetHeight,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: NSColorSpaceName.calibratedRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!

        NSGraphicsContext.saveGraphicsState()
        if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = ctx
            
            ctx.cgContext.setFillColor( NSColor.white.cgColor )
            ctx.cgContext.fill( CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            
            self.draw(in: NSMakeRect(originPoint.x, originPoint.y, CGFloat(scaledWidth), CGFloat(scaledHeight)), from: NSRect.zero, operation: .copy, fraction: 1)

            NSGraphicsContext.restoreGraphicsState()
        }
        
        let img = NSImage(size: CGSize(width:targetWidth, height:targetHeight))
        img.addRepresentation(rep)
        return img
    }
    
    
    func pixelData() -> [Pixel] {
        let rep = self.representations[0] as! NSBitmapImageRep
        var bmp : NSBitmapImageRep? = rep
        
        // I don't yet know enough to know why I can't convert a 1Bit B&W image to genericRGB but apparently yout can't!
        if rep.bitsPerPixel >= 8 {
            bmp = rep.converting(to: NSColorSpace.genericRGB, renderingIntent: NSColorRenderingIntent.default)
        }
        
        var data: UnsafeMutablePointer<UInt8> = bmp!.bitmapData!
        var r, g, b, a: UInt8
        var pixels: [Pixel] = []
        
        let width = bmp!.pixelsWide
        for row in 0..<bmp!.pixelsHigh {
            for col in 0..<bmp!.pixelsWide {
                // Handle 1 bit (black and white only) images
                if bmp?.bitsPerPixel == 1 {
                    r = bmp!.bitmapData![col + row*width]
                    g = r
                    b = r
                    a = 255
                } else {
                    r = data.pointee
                    data = data.advanced(by:1)
                    g = data.pointee
                    data = data.advanced(by:1)
                    b = data.pointee
                    data = data.advanced(by:1)
                    a = data.pointee
                    data = data.advanced(by:1)
                }
                pixels.append(Pixel(r: r, g: g, b: b, a: a, row:row, col:col))
            }
        }
        
        return pixels
    }
    
}

struct Pixel {
    
    var r: Float
    var g: Float
    var b: Float
    var a: Float
    var row: Int
    var col: Int
    
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8, row: Int, col: Int) {
        self.r = Float(r)
        self.g = Float(g)
        self.b = Float(b)
        self.a = Float(a)
        self.row = row
        self.col = col
    }
    
    var color: NSColor {
        return NSColor(red: CGFloat(r/255.0), green: CGFloat(g/255.0), blue: CGFloat(b/255.0), alpha: CGFloat(a/255.0))
    }
    
    func getAveragePixel() -> Float {
        return (r + g + b)/3.0
    }
    
    var description: String {
        return "RGBA(\(r), \(g), \(b), \(a))"
    }
    
}
