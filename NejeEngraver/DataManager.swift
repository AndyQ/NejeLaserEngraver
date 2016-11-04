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

    var renderingStyle : RenderingStyle = .FloydSteinbergDithering
    
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
        var ret = false
        
        // Read in image
        if let i = NSImage(contentsOf: url) {
            image = i
            
            // Convert image to 500x500 black and white
            if Int(image.size.width) != imageSize && Int(image.size.height) != imageSize {
                image = image.resizeImage(imageSize, imageSize)
            }
            
            
            imageToDots( colorThreshold:127 )
            
            _ = Utils.createMonoBitmap(pixels: pixels)
            ret = true
            
            saveImage()
        }
        
        return ret
    }
    
    func imageToDots( colorThreshold:Float ) {
        
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
