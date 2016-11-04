//
//  SerialHandler.swift
//  NejeEngraver
//
//  Created by Andy Qua on 22/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa
import CoreFoundation

import IOKit
import IOKit.serial

class SerialHandler : NSObject, ORSSerialPortDelegate {
    let standardInputFileHandle = FileHandle.standardInput
    var serialPort: ORSSerialPort?
    
    var portOpenCallback : (()->())?
    var portCloseCallback : (()->())?
    var readPrintDataCallback : ((Data)->())?
    var imageUploadedCallback : (()->())?
    
    var isOpen = false
    
    var testMode = false
    var testStopped = true
    var testPaused = true
    
    func getUSBSerialDevices() -> [String] {
        var portIterator: io_iterator_t = 0
        let kernResult = findSerialDevices(deviceType: kIOSerialBSDAllTypes, serialPortIterator: &portIterator)
        if kernResult == KERN_SUCCESS {
            
            return getSerialPaths(portIterator: portIterator)
        }
        
        return []
    }
    
    func findSerialDevices(deviceType: String,  serialPortIterator: inout io_iterator_t ) -> kern_return_t {
        var result: kern_return_t = KERN_FAILURE
        let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue)
        if var classesToMatchDict = (classesToMatch as! NSMutableDictionary) as NSDictionary as? [String: Any] {
            classesToMatchDict[kIOSerialBSDTypeKey] = deviceType
            let classesToMatchCFDictRef = (classesToMatchDict as NSDictionary) as CFDictionary
            result = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatchCFDictRef, &serialPortIterator);
            return result
        }
        
        return KERN_FAILURE
    }
    
    func getSerialPaths(portIterator: io_iterator_t) -> [String] {
        var devices = [String]()
        
        var serialService: io_object_t
        repeat {
            serialService = IOIteratorNext(portIterator)
            if (serialService != 0) {
                let key: CFString! = "IOCalloutDevice" as NSString
                let bsdPathAsCFtring: AnyObject? =
                    IORegistryEntryCreateCFProperty(serialService, key, kCFAllocatorDefault, 0).takeUnretainedValue()
                if let path = bsdPathAsCFtring as? String {
                    devices.append(path)
                }
            }
        } while serialService != 0;
        
        return devices
    }
    
    func open( device : String ) {
        
        if testMode {
            serialPort = ORSSerialPort(path:"")
            isOpen = true
        } else {
            self.serialPort = ORSSerialPort(path: device) // please adjust to your handle
            self.serialPort?.delegate = self
            self.serialPort?.baudRate = 57600
            self.serialPort?.rts = true
            self.serialPort?.dtr = true
            serialPort?.open()
        }
    }
    
    func close() {
        isOpen = false
        serialPort?.close()
    }
    
    func send(_ command: String, data : Any? = nil) {
        if !isOpen && !testMode { return }
        
        let string = command.lowercased()
        
        var b : [UInt8]?
        if string == "close" {
            close()
        } else if  string == "open" {
            open( device:"" )
        } else if string == "origin"  {
            b = [0xF3]
        } else if string == "preview"  {
            b = [0xF4]
        } else if string == "previewcenter"  {
            b = [0xFB]
        } else if string == "init"  {
            b = [0xF6]
        } else if string == "reset"  {
            b = [0xF9]
            
            if testMode {
                testStopped = true
                testPaused = false

            }
        } else if string == "pause"  {
            b = [0xF2]
            if testMode {
                testPaused = true
            }
        } else if string == "start"  {
            if !testMode {
                b = [0xF1]
            } else {
                testStopped = false
                testPaused = false
                DispatchQueue.global().async { [weak self] in
                    self?.testModeDataSender()
                }
            }
        } else if string == "burn" {
            if let time = data as? Int32 {
                let c = UInt8(min(time, 240))
                b = [c]
            }
        } else if string == "upload"  {
            if let pixels = data as? [CellState] {
                // Send 0xFE 8 times to erase old image
                let data = Data(bytes: [0xFE,0xFE,0xFE,0xFE,0xFE,0xFE,0xFE,0xFE])
                sendData(data:data)
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 3 , execute: { [weak self] in
                    guard let `self` = self else { return }
                    // Now upload image (BMP Monochrome format)
                    let data = Data(bytes:Utils.createMonoBitmap(pixels: pixels))
                    self.sendData(data:data)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.imageUploadedCallback?()
                    }
                })
            }
        } else if string.hasPrefix( "move" ) {
            if string.hasSuffix("origin") {
                b = [0xF3]
            } else if string.hasSuffix("up") {
                b = [0xF5,0x01]
            } else if string.hasSuffix("down") {
                b = [0xF5,0x02]
            } else if string.hasSuffix("left") {
                b = [0xF5,0x03]
            } else if string.hasSuffix("right") {
                b = [0xF5,0x04]
            }
        }

        if let b = b {
            let data = Data(bytes: b)
            sendData(data:data)
        }
    }
    
    func sendData( data : Data) {
        if !testMode {
            self.serialPort?.send(data)
        }
    }
    
    // ORSSerialPortDelegate
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        readPrintDataCallback?( data )
    }
    
    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
        self.serialPort = nil
        portCloseCallback?()
        print("Serial port (\(serialPort)) was removed")
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        self.serialPort = nil
        portCloseCallback?()
        print("Serial port (\(serialPort)) was closed")
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("Serial port (\(serialPort)) encountered error: \(error)")
        self.serialPort?.close()
        portCloseCallback?()
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        print("Serial port \(serialPort) was opened")
        portOpenCallback?()
        
        isOpen = true
    }
    
    
    func testModeDataSender() {
        let dm = DataManager.instance
        
        // Simulate sending data from the serial port
        if let pixels = dm.pixels {
            var i = 0
            for r in 0 ..< dm.imageSize {
                for c in 0 ..< dm.imageSize {
                    if pixels[i] == .on {
                        let bytes :[UInt8] = [0xff, UInt8(c/100), UInt8(c%100), UInt8(r/100), UInt8(r%100)]
                        let data = Data(bytes:bytes)
                        DispatchQueue.main.async { [weak self] in
                            self?.readPrintDataCallback?( data)
                        }
                        usleep(1000)
                    }
                    
                    i += 1
                    
                    while testPaused {
                        usleep(1000)
                    }
                    
                    if testStopped {
                        break
                    }
                }
                
                if testStopped {
                    break
                }
            }
        }
    }
}
