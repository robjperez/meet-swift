//
//  ViewManager.swift
//  meet-swift
//
//  Created by Roberto Perez Cubero on 09/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import Foundation
import OpenTok

class ViewManager : UIView {
    var rootView: UIView?
    var subscribers = Dictionary<String, OTSubscriber>()
    var wasSubscribingToVideo = false
    
    @IBOutlet var view: UIView!
    
    required init!(frame: CGRect, rootView: UIView) {
        super.init(frame: frame)
        self.rootView = rootView
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubscriber(sub: OTSubscriber, streamKey: String) {
        subscribers[streamKey] = sub
    }
    
    func removeSubscriber(streamKey: String) {
        self.subscribers.removeValueForKey(streamKey)
    }
    
    func onEnterBackground () {
    }
    
    func onEnterForeground() {
    }
}