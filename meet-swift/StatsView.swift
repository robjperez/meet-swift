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
    
    var refreshTimer : Timer?
    
    var initialBattery : Float?
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        Bundle.main.loadNibNamed("StatsViewer", owner: self, options: nil)
        self.addSubview(self.view)
        
        initialBattery = (UserDefaults.standard.object(forKey: AppDelegate.kInitialBatteryKey)! as AnyObject).floatValue
        
        refreshTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(StatsView.updateStats(_:)), userInfo: nil, repeats: true)
        
        refreshTimer!.fire()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func updateStats(_ timer: Timer) {
        cpu?.text = "CPU: \(StatsUtil.cpuUsage())%"
        memory?.text = String(format:"Memory: %.2fMb", StatsUtil.memoryUsage())
        battery?.text = String(format:"Battery: %.2f%%",((initialBattery! - UIDevice.current.batteryLevel) * 100))
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
}
