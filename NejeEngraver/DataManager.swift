//
//  DataManager.swift
//  NejeEngraver
//
//  Created by Andy Qua on 23/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

class DataManager {
    
    var image : NSImage!
    var pixels : [CellState]!
    var imageSize = 512

    var renderingStyle : RenderingStyle = .AveragePixelSampling
    
    static let instance = DataManager ()

    private init() {
        self.pixels = Array(repeating: .off, count: imageSize*imageSize)
        
        // See if we have a cached image
        let path = Utils.cacheFolder()
        let imageCacheURL = URL(fileURLWithPath: "\(path)/lastImage.tiff")
        
        if !loadImage( fromUrl:imageCacheURL) {
            self.image = NSImage(size: NSSize(width: imageSize, height: imageSize))
        }
    }

    func clearImage() {
        pixels = pixels.map { $0 != .off ? .off : $0 }
        self.image = NSImage(size: NSSize(width: imageSize, height: imageSize))

    }
    
    func getNumberOfSelectedPixels() -> Int {
        var nrOnPixels = 0
        pixels.forEach { if $0 == .on {nrOnPixels += 1} }
            
        return nrOnPixels
    }
    

    func resetPixelColors() {
        pixels = pixels.map { $0 == .printed ? .on : $0 }
    }

    func loadImage( fromUrl url: URL ) -> Bool {
        
        // Read in image
        if let i = NSImage(contentsOf: url) {
            image = i
            
            // Convert image to 500x500 black and white
            if Int(image.size.width) != imageSize && Int(image.size.height) != imageSize {
                image = image.resizeImage(imageSize, imageSize)
            }
            
            convertImage( colorThreshold:127)
            return true
        }
        return false
    }
    
    func convertImage(colorThreshold:Float) {
        if renderingStyle == .FloydSteinbergDithering {
            imageToDots2(colorThreshold:colorThreshold)
        } else {
            imageToDots(colorThreshold:CGFloat(colorThreshold/255.0))
        }
        _ = Utils.createMonoBitmap(pixels: pixels)
        
        saveImage()
    }
    
    func imageToDots( colorThreshold:CGFloat ) {
        if let tiff = image.tiffRepresentation,
            let imageRep = NSBitmapImageRep(data: tiff) {
            let imageWidth = Int(image.size.width)
            let imageHeight = Int(image.size.height)
            
            for y in  0 ..< imageHeight {
                for x in 0 ..< imageWidth {
                    pixels[x + y*imageWidth] = .off
                    if let color = imageRep.colorAt(x: x, y: y) {
                        if color.redComponent < colorThreshold && color.alphaComponent == 1 {
                            pixels[x + y*imageWidth] = .on
                        }
                    }
                }
            }
        }
    }
    
    func dotsToImage() {
        
        let imageWidth = 512
        let imageHeight = 512
        if let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 512, pixelsHigh: 512, bitsPerSample: 16, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) {
            
            for y in  0 ..< imageHeight {
                for x in 0 ..< imageWidth {
                    if let color = (pixels[x + y*imageWidth] == .off ? NSColor.white : NSColor.black).usingColorSpaceName(.calibratedRGB) {
                        imageRep.setColor(color, atX: x, y: y)
                    }
                }
            }
            
            image = NSImage(size: CGSize(width:imageWidth, height:imageHeight))
            image.addRepresentation(imageRep)
        }
    }
    
    func imageToDots2( colorThreshold:Float ) {
        
        var tmpImage : NSImage = image 
        if let imageRep = image.representations[0].binaryRepresentation(Int(colorThreshold), renderingStyle:renderingStyle) {
            tmpImage = NSImage(size: CGSize(width:imageRep.pixelsWide, height:imageRep.pixelsHigh))
            tmpImage.addRepresentation(imageRep)
        }

        // load image into bytes (By this time it is black and white image
        let pixelData = tmpImage.pixelData()
        for row in 0 ..< imageSize {
            for col in 0 ..< imageSize {
                let c = pixelData[col + row*imageSize]
                if row >= 500 {
                    pixels[col + row*imageSize] = .disabled
                } else if c.r == 255 {
                    pixels[col + row*imageSize] = .off
                } else {
                    pixels[col + row*imageSize] = .on
                }
            }
        }
    }
    
    func saveImage() {
        // Store image in cache
        // an alternative to the NSTemporaryDirectory
        let path = Utils.cacheFolder()
        
        let fm = FileManager.default
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [:])
            
            
            if let data = image.tiffRepresentation {
                let fileURL = URL(fileURLWithPath: "\(path)/lastImage.tiff")
                
                try data.write(to: fileURL)
            }
        } catch let error {
            print( "Failed to write cache files - \(error)")
        }
    }
}
