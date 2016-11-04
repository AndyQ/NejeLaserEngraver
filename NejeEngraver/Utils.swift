    //
//  Utils.swift
//  NejeEngraver
//
//  Created by Andy Qua on 23/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

enum CellState {
    case on
    case off
    case printed
    case disabled
    
}

class Utils: NSObject {
    
    class func cacheFolder() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        var path = ""
        if paths.count > 0 {
            if let bundleName = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String{
                path = paths[0].appending("/\(bundleName)")
            } else {
                path = paths[0].appending("/NEJEEngraver")
            }
        }
        
        return path
    }
    
    class func createMonoBitmap( pixels: [CellState] ) -> [UInt8] {
        let bmpHeader : [UInt8] = [0x42,0x4D,0x3E,0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x3E,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x01,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF,0xFF,0x00]
        
        // We could hardcode 512 here (as thats what we are always working with but 
        // lets not - BUT we are assuming that the image is square - width=height!
        let imageDimension = Int(sqrt(Double(pixels.count)))

        
        var buffer = [UInt8](repeating: 0, count: pixels.count / 8)
        
        for row in 0 ..< imageDimension {
            for col in 0 ..< imageDimension {
                let index = col + row*imageDimension
                
                // Set a white pixel if the pixel is OFF || disabled
                if pixels[index] == .off || pixels[index] == .disabled {
                    setPixel( buffer: &buffer, x: col, y: row, imageDimesion:imageDimension )
                } else {
                }
            }
        }
        
        let ret = bmpHeader + buffer
        
        let path = Utils.cacheFolder() + "/mono.bmp"
        if let outputStream = OutputStream(toFileAtPath: path, append: false) {
            outputStream.open()
            outputStream.write(ret, maxLength: ret.count)
            outputStream.close()
        }
        return ret
    }
    
    class func setPixel( buffer: inout [UInt8], x:Int, y:Int, imageDimesion: Int) {
        let index = (y * imageDimesion + x)
        let byteIndex = index / 8
        let byteOffset = index % 8
        buffer[byteIndex] |= UInt8(128 >> byteOffset)
    }

}
