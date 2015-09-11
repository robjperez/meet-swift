//
//  StatsView.swift
//  meet-swift
//
//  Created by Roberto Perez Cubero on 11/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import Foundation

class StatsView : UIView {
    @IBOutlet weak var cpu: UILabel?
    @IBOutlet weak var memory: UILabel?
    @IBOutlet weak var battery: UILabel?
    @IBOutlet var view: UIView!
    
    var refreshTimer : NSTimer?
    
    var initialBattery : Float?
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        NSBundle.mainBundle().loadNibNamed("StatsViewer", owner: self, options: nil)
        self.addSubview(self.view)
        
        initialBattery = NSUserDefaults.standardUserDefaults().objectForKey(AppDelegate.kInitialBatteryKey)!.floatValue
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("updateStats:"), userInfo: nil, repeats: true)
        
        refreshTimer!.fire()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateStats(timer: NSTimer) {
        cpu?.text = "CPU: \(StatsUtil.cpuUsage())"
        memory?.text = "Memory: \(StatsUtil.memoryUsage())"
        battery?.text = "Battery: \(initialBattery! - UIDevice.currentDevice().batteryLevel)"
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
}