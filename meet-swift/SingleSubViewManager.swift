//
//  SingleSubViewManager.swift
//  meet-swift
//
//  Created by Roberto Perez Cubero on 11/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import Foundation
import OpenTok

class SingleSubViewManager : ViewManager {
    @IBOutlet weak var previousSub : UIButton?
    @IBOutlet weak var nextSub : UIButton?
    
    var selectedSubscriber : String?
    
    required init!(frame: CGRect, rootView: UIView) {
        super.init(frame: frame, rootView: rootView)
        NSBundle.mainBundle().loadNibNamed("SingleView", owner: self, options: nil)
        self.addSubview(self.view)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func toggleSubsButtons() {
        if self.subscribers.count > 1 {
            self.previousSub?.hidden = false
            self.nextSub?.hidden = false
        } else {
            self.previousSub?.hidden = true
            self.nextSub?.hidden = true
        }
    }
    
    @IBAction func nextSubPresseed(sender: AnyObject?) {
        if self.subscribers.count <= 1 { return }
        
        let sortedKeys = Array(self.subscribers.keys).sorted(<)
        let currentIndex = find(sortedKeys, self.selectedSubscriber!)
        let nextIndex = (currentIndex! + 1) % self.subscribers.count
        let nextKey = sortedKeys[nextIndex]
        
        self.performSubscriberAnimation(self.subscribers[nextKey]!.stream.streamId)
    }
    
    @IBAction func prevSubPresseed(sender: AnyObject) {
        if self.subscribers.count <= 1 { return }
        
        let sortedKeys = Array(self.subscribers.keys).sorted(<)
        let currentIndex = find(sortedKeys, self.selectedSubscriber!)
        var nextIndex = 0
        if currentIndex == 0 { nextIndex = self.subscribers.count - 1}
        else { nextIndex = currentIndex! - 1 }
        let nextKey = sortedKeys[nextIndex]
        
        self.performSubscriberAnimation(self.subscribers[nextKey]!.stream.streamId)
    }
    
    override func addSubscriber(sub: OTSubscriber, streamKey: String) {
        super.addSubscriber(sub, streamKey: streamKey)
        
        let subView = sub.view;
        self.selectedSubscriber = streamKey
        
        if self.subscribers.count > 1 && self.selectedSubscriber != nil {
            self.performSubscriberAnimation(streamKey)
        } else {
            ViewUtils.addViewFill(subView, rootView: self.view)
        }
        
        toggleSubsButtons()
    }
    
    override func removeSubscriber(streamKey: String) {
        
        super.removeSubscriber(streamKey)
        toggleSubsButtons()
    }
    
    private func performSubscriberAnimation(subId: String) {
        if selectedSubscriber == subId { return }
        
        let previousSubscriber = self.subscribers[self.selectedSubscriber!]
        let newSubscriber = self.subscribers[subId]!
        
        newSubscriber.view.alpha = 0.0
        ViewUtils.addViewFill(newSubscriber.view, rootView: self.view)
        
        previousSubscriber?.subscribeToVideo = false
        newSubscriber.subscribeToVideo = true
        
        UIView.animateWithDuration(0.4,
            animations: { () -> Void in
                previousSubscriber?.view.alpha = 0.0
                newSubscriber.view.alpha = 1.0
            },
            completion: { (finished) -> Void in
                self.selectedSubscriber = subId
                previousSubscriber?.view.removeFromSuperview()
        })
    }
    
    override func onEnterBackground () {
        if let subId = self.selectedSubscriber {
            let sub = self.subscribers[subId]
            if let videoEnabled = sub?.subscribeToVideo {
                self.wasSubscribingToVideo = videoEnabled
            }
            
            sub?.subscribeToVideo = false
        }
    }
    
    override func onEnterForeground() {
        if let subId = self.selectedSubscriber {
            let sub = self.subscribers[subId]
            sub?.subscribeToVideo = self.wasSubscribingToVideo
        }
    }
}