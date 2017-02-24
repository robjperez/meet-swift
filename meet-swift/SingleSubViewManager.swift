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
        Bundle.main.loadNibNamed("SingleView", owner: self, options: nil)
        self.addSubview(self.view)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    fileprivate func toggleSubsButtons() {
        if self.subscribers.count > 1 {
            self.previousSub?.isHidden = false
            self.nextSub?.isHidden = false
        } else {
            self.previousSub?.isHidden = true
            self.nextSub?.isHidden = true
        }
    }
    
    @IBAction func nextSubPresseed(_ sender: AnyObject?) {
        if self.subscribers.count <= 1 { return }
        
        let sortedKeys = Array(self.subscribers.keys).sorted(by: <)
        let currentIndex = sortedKeys.index(of: self.selectedSubscriber!)
        let nextIndex = (currentIndex! + 1) % self.subscribers.count
        let nextKey = sortedKeys[nextIndex]
        
        self.performSubscriberAnimation(self.subscribers[nextKey]!.stream!.streamId)
    }
    
    @IBAction func prevSubPresseed(_ sender: AnyObject) {
        if self.subscribers.count <= 1 { return }
        
        let sortedKeys = Array(self.subscribers.keys).sorted(by: <)
        let currentIndex = sortedKeys.index(of: self.selectedSubscriber!)
        var nextIndex = 0
        if currentIndex == 0 { nextIndex = self.subscribers.count - 1}
        else { nextIndex = currentIndex! - 1 }
        let nextKey = sortedKeys[nextIndex]
        
        self.performSubscriberAnimation(self.subscribers[nextKey]!.stream!.streamId)
    }
    
    override func addSubscriber(_ sub: OTSubscriber, streamKey: String) {
        super.addSubscriber(sub, streamKey: streamKey)
        
        guard let subView = sub.view else {
            return
        }
        
        self.selectedSubscriber = streamKey
        
        if self.subscribers.count > 1 && self.selectedSubscriber != nil {
            self.performSubscriberAnimation(streamKey)
        } else {
            ViewUtils.addViewFill(subView, rootView: self.view)
        }
        
        toggleSubsButtons()
    }
    
    override func removeSubscriber(_ streamKey: String) {
        
        super.removeSubscriber(streamKey)
        toggleSubsButtons()
    }
    
    fileprivate func performSubscriberAnimation(_ subId: String) {
        if selectedSubscriber == subId { return }
        
        let previousSubscriber = self.subscribers[self.selectedSubscriber!]
        let newSubscriber = self.subscribers[subId]!
        
        newSubscriber.view?.alpha = 0.0
        ViewUtils.addViewFill(newSubscriber.view!, rootView: self.view)
        
        previousSubscriber?.subscribeToVideo = false
        newSubscriber.subscribeToVideo = true
        
        UIView.animate(withDuration: 0.4,
            animations: { () -> Void in
                previousSubscriber?.view?.alpha = 0.0
                newSubscriber.view?.alpha = 1.0
            },
            completion: { (finished) -> Void in
                self.selectedSubscriber = subId
                previousSubscriber?.view?.removeFromSuperview()
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
