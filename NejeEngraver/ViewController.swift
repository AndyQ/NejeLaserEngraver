//
//  ViewController.swift
//  NejeEngraver
//
//  Created by Andy Qua on 22/10/2016.
//  Copyright © 2016 Andy Qua. All rights reserved.
//

import Cocoa

@available(OSX 10.13, *)
class ViewController: NSViewController {
    
    @IBOutlet weak var burnTextFeld: NumberTextField!
    @IBOutlet weak var connectedBtn: NSButton!
    @IBOutlet weak var refreshBtn: NSButton!
    @IBOutlet weak var uploadBtn: NSButton!
    @IBOutlet weak var startBtn: NSButton!
    @IBOutlet weak var pauseBtn: NSButton!
    @IBOutlet weak var initBtn: NSButton!
    @IBOutlet weak var ResetBtn: NSButton!
    @IBOutlet weak var moveOriginBtn: NSButton!
    @IBOutlet weak var moveCenterBtn: NSButton!
    @IBOutlet weak var previewBtn: NSButton!
    @IBOutlet weak var upBtn: NSButton!
    @IBOutlet weak var downBtn: NSButton!
    @IBOutlet weak var leftBtn: NSButton!
    @IBOutlet weak var rightBtn: NSButton!
    @IBOutlet weak var setBurnBtn: NSButton!
    @IBOutlet weak var clearBtn: NSButton!
    @IBOutlet weak var editBtn: NSButton!
    @IBOutlet weak var invertBtn: NSButton!
    
    @IBOutlet weak var serialDeviceCombo: NSComboBox!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var imageDarknessThreshold: NSSlider!

    @IBOutlet weak var testModeLabel: NSTextField!
    @IBOutlet weak var imageThresholdText: NSTextField!
    @IBOutlet weak var printTimeText : NSTextField!

    @IBOutlet var grid : ImageView!
    
    @IBOutlet weak var barProgress: NSTextField!

//    @IBOutlet weak var barBarItem: NSCustomTouchBarItem!
    
    var printTimer : Timer!
    
    var serialHandler : SerialHandler!
    var dm = DataManager.instance
    
    var startPrintTime : CFAbsoluteTime!
    
    
    var dataBuffer = [UInt8]()
    var serialDevices = [String]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let progressBar = NSProgressIndicator(frame: NSRect(x:0, y:0, width:100, height:44))
//        barBarItem.view = progressBar

        if barProgress != nil {
            barProgress.stringValue = ""
        }
        // Do any additional setup after loading the view.
        serialHandler = SerialHandler()
        serialHandler.portOpenCallback = { [weak self] in
            self?.serialPortOpened()
        }

        serialHandler.portCloseCallback = { [weak self] in
            self?.serialPortClosed()
        }

        serialHandler.readPrintDataCallback = { [weak self] (data) in
            self?.serialPortReadData( data:data )
        }
        
        serialHandler.imageUploadedCallback = { [weak self] () in
            self?.enableButtons(enabled: true)
        }
        
        enableButtons(enabled: false)
        uploadBtn.isEnabled = false
        startBtn.isEnabled = false
        initBtn.isEnabled = false
        pauseBtn.isEnabled = false
        ResetBtn.isEnabled = false

        // Get the list of serial devices
        refreshSerialPorts( autoConnectIfPossible:true)
        
        UserDefaults.standard.register(defaults: ["BurnTime" : "60"])
        if let val = UserDefaults.standard.string(forKey: "BurnTime") {
            self.burnTextFeld.stringValue = "\(val)"
        }

        grid.layer?.backgroundColor = NSColor.blue.cgColor
        progressBar.doubleValue = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.testModeToggled(_:)), name: Notification.Name("TestMode"), object: nil)
    }
    
    @objc func testModeToggled( _ notification : NSNotification ) {
        if let on = notification.userInfo?["on"] as? Bool {
            serialHandler.testMode = on
            testModeLabel.isHidden = !on

            if on && serialHandler.isOpen {
                return
            }

            enableButtons(enabled: on)
            
            startBtn.isEnabled = on
            pauseBtn.isEnabled = on
            ResetBtn.isEnabled = on
        }
    }
    
    
    func refreshSerialPorts( autoConnectIfPossible: Bool = false ) {
        serialDevices = serialHandler.getUSBSerialDevices()
        serialDeviceCombo.removeAllItems()
        serialDeviceCombo.addItems(withObjectValues: serialDevices)
        serialDeviceCombo.stringValue = ""
        
        // If we have a wchusbserial14xxx device connected then open that otherwise don't
        let filteredStrings = serialDevices.filter({(item: String) -> Bool in
            return item.lowercased().contains("wchusbserial14".lowercased())
        })
        
        if filteredStrings.count > 0 {
            let device = filteredStrings[0]
            let index = serialDevices.index(of: device)!
            serialDeviceCombo.selectItem(at: index)
            
            if autoConnectIfPossible {
                serialHandler.open( device: device)
            }
        }

    }
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? EditorViewController {
            vc.onClose = { [weak self] () in
                self?.grid.setNeedsDisplay(self!.grid.bounds)
                self?.dm.dotsToImage()
                self?.dm.saveImage()
            }
        }
    }
    
    func secondsToHoursMinutesSeconds (_ seconds : Int) -> String {
        return String(format:"%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    @IBAction func imageProcessingSelected(_ sender: AnyObject) {
        guard let button = sender as? NSButton else { return }
        if button.title == "Black and White" {
            dm.renderingStyle = .BlackAndWhite
        } else if button.title == "Dithering" {
            dm.renderingStyle = .FloydSteinbergDithering
        } else {
            dm.renderingStyle = .AveragePixelSampling
        }

        dm.convertImage( colorThreshold:Float(imageDarknessThreshold.doubleValue) )
        grid.setNeedsDisplay(grid.bounds)
    }
    
    
    @IBAction func connectPressed(_ sender: AnyObject) {
        if self.connectedBtn.title == "Connect" {
            serialHandler.open(device:serialDeviceCombo.stringValue)
        } else {
            serialHandler.close()
        }
    }
    
    @IBAction func uploadPressed(_ sender: AnyObject) {
        dm.resetPixelColors()
        serialHandler.send( "upload", data: dm.pixels)
    }
    
    @IBAction func startPressed(_ sender: AnyObject) {
        
        dm.resetPixelColors()
        self.grid.setNeedsDisplay(grid.bounds)

        let pixelCount = dm.getNumberOfSelectedPixels()
        self.progressBar.minValue = 0
        self.progressBar.maxValue = Double(pixelCount)
        self.progressBar.doubleValue = 0
        
        pauseBtn.isEnabled = true
        startBtn.isEnabled = false
        uploadBtn.isEnabled = false

        enableButtons(enabled:false, printing: true)
        serialHandler.send( "start" )
        startPrintTime = CFAbsoluteTimeGetCurrent()
        
        printTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block:{ [weak self] (timer) in
            guard let `self` = self else { return }
            self.handleTimer()
        })
    }
    
    @objc func handleTimer() {
        let now = CFAbsoluteTimeGetCurrent()
        let timeTaken = self.secondsToHoursMinutesSeconds(Int(now - self.startPrintTime))
        self.printTimeText.stringValue = "Print time: \(timeTaken)"
    }
    
    @IBAction func pausePressed(_ sender: AnyObject) {
        serialHandler.send( "pause")
        printTimer.invalidate()
        
        pauseBtn.isEnabled = false
        startBtn.isEnabled = true
    }

    @IBAction func initPressed(_ sender: AnyObject) {
        serialHandler.send( "init")
    }

    @IBAction func resetPressed(_ sender: AnyObject) {
        serialHandler.send( "reset")
        printTimer.invalidate()

        DispatchQueue.main.asyncAfter(deadline: .now()+0.25, execute: { [weak self] in
            self?.dm.resetPixelColors()
            self?.enableButtons(enabled:true)
            self?.pauseBtn.isEnabled = false
            self?.startBtn.isEnabled = true
            self?.uploadBtn.isEnabled = true
        })
    }

    @IBAction func originPressed(_ sender: AnyObject) {
        serialHandler.send( "origin")
    }

    @IBAction func CenterPressed(_ sender: AnyObject) {
        serialHandler.send( "previewcenter")
    }

    @IBAction func previewPressed(_ sender: AnyObject) {
        serialHandler.send( "preview")
    }


    @IBAction func upPressed(_ sender: AnyObject) {
        serialHandler.send( "move up")
    }

    @IBAction func downPressed(_ sender: AnyObject) {
        serialHandler.send( "move down")
    }

    @IBAction func leftPressed(_ sender: AnyObject) {
        serialHandler.send( "move left")
    }

    @IBAction func rightPressed(_ sender: AnyObject) {
        serialHandler.send( "move right")
    }

    @IBAction func burnTimePressed(_ sender: AnyObject) {
        let val = burnTextFeld.intValue
        serialHandler.send( "burn", data:val)
        // Save burn time to user defaults
        UserDefaults.standard.set("\(val)", forKey: "BurnTime")
    }
    
    @IBAction func clearPressed(_ sender: AnyObject) {
        dm.clearImage()
        self.grid.setNeedsDisplay(self.grid.bounds)
    }
    
    @IBAction func refreshSerialPortsPressed(_ sender: AnyObject) {
        
        refreshSerialPorts()

    }
    
    @IBAction func darknessThresholdChanged(_ sender: Any) {
        if let slider = sender as? NSSlider {
            dm.convertImage( colorThreshold:Float(slider.doubleValue) )
            grid.setNeedsDisplay(grid.bounds)
            
            imageThresholdText.stringValue = "\(Int(slider.doubleValue))"
        }

    }
    
    
    func enableButtons( enabled :Bool, printing: Bool = false ) {
        burnTextFeld.isEnabled = enabled
        setBurnBtn.isEnabled = enabled
        moveOriginBtn.isEnabled = enabled
        moveCenterBtn.isEnabled = enabled
        previewBtn.isEnabled = enabled
        upBtn.isEnabled = enabled
        downBtn.isEnabled = enabled
        leftBtn.isEnabled = enabled
        rightBtn.isEnabled = enabled
    }
    
    // MARK: serialManager callbacks
    func serialPortOpened() {
        enableButtons(enabled: true)
        
        uploadBtn.isEnabled = true
        startBtn.isEnabled = true
        initBtn.isEnabled = true
        pauseBtn.isEnabled = false
        ResetBtn.isEnabled = true

        self.connectedBtn.title = "Disconnect"

        if let val = UserDefaults.standard.string(forKey: "BurnTime") {
            serialHandler.send( "burn", data:val)
        }

    }
    
    func serialPortClosed() {
        self.connectedBtn.title = "Connect"
        self.connectedBtn.isEnabled = true
        
        refreshSerialPorts()
        enableButtons(enabled: false)


    }
    
    func serialPortReadData( data : Data ) {
        let arr = data.withUnsafeBytes {
            Array(UnsafeBufferPointer<UInt8>(start: $0, count: data.count/MemoryLayout<UInt8>.size))
        }
        self.dataBuffer += arr
        
        // data is in one of the following formats:
        // 0xff c1 c2 r1 r2 - drawn point
        // 0x66 - printing complete
        //
        // Drawn point format is:
        // 0xff - block id
        // c1 - hundreds column byte
        // c2 - tens byte column byte
        // r1 - hundreds row byte
        // r2 - tens byte row byte
        //
        // the actual column number is c1 * 100 + c2
        // the actual row number is c1 * 100 + c2
        //
        // e.g. if c1 -> 0x02 and c2 -> 0x54
        //         c1 -> 2 and c2 -> 84
        //         the column is 284
        // Same for the row
        //
        while self.dataBuffer.count > 0 {
            if self.dataBuffer[0] == 0xff {
                
                // If we have all the data
                if self.dataBuffer.count > 5 {
                    let c1 = self.dataBuffer[1]
                    let c2 = self.dataBuffer[2]
                    let r1 = self.dataBuffer[3]
                    let r2 = self.dataBuffer[4]
                    let col = Int(c1) * 100 + Int(c2)
                    let row = Int(r1) * 100 + Int(r2)
                    if col < 0 || col >= dm.imageSize || row < 0 || row >= dm.imageSize {
                        // Invalid row/col
                        self.dataBuffer.removeFirst(5)
                        continue
                    }
                    
                    //print( "Read - col - \(col), row - \(row)")
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.grid.printPixel( row: Int(row), col:Int(col) )
                        self.progressBar.increment(by: 1)
                        
                        if self.barProgress != nil {
                            let percent = Int((self.progressBar.doubleValue / self.progressBar.maxValue)*100)
                            self.barProgress.stringValue = "Print progress: \(percent)%"
                        }

                    }
                    self.dataBuffer.removeFirst(5)
                } else {
                    break
                }
            } else if self.dataBuffer[0] == 0x66 {
                // Finished
                self.dataBuffer.removeAll()
                
                enableButtons(enabled: true)
                uploadBtn.isEnabled = true
                startBtn.isEnabled = true
                initBtn.isEnabled = true
                pauseBtn.isEnabled = false
                ResetBtn.isEnabled = true

                // Get Time Taken
                let end = CFAbsoluteTimeGetCurrent()
                let timeTaken = secondsToHoursMinutesSeconds(Int(end - startPrintTime))
                
                self.printTimeText.stringValue = "Print time: \(timeTaken)"
                printTimer.invalidate()

                if self.barProgress != nil {
                    self.barProgress.stringValue = "Print completed in \(timeTaken)"
                }

                break
            } else {
                self.dataBuffer.removeFirst()
            }
        }
    }

    
}

