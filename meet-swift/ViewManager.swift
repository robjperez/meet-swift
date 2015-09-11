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

class MultiSubViewManager : ViewManager {
    @IBOutlet weak var bigView: UIView?
    @IBOutlet weak var scrollView: UIScrollView?
    
    var selectedSubscriber : String?
    
    var subsInScroll = Set<OTSubscriber>()
    
    required init!(frame: CGRect, rootView: UIView) {
        super.init(frame: frame, rootView: rootView)
        NSBundle.mainBundle().loadNibNamed("MultiView", owner: self, options: nil)
        self.addSubview(self.view)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func addSubscriber(sub: OTSubscriber, streamKey: String) {
        super.addSubscriber(sub, streamKey: streamKey)
        
        let subView = sub.view;
        
        if let selSub = selectedSubscriber {
            self.addSubscriberToScroll(sub)
        } else {
            self.selectedSubscriber = streamKey
            self.addSubscriberToBigView(sub)
        }
    }
    
    override func removeSubscriber(streamKey: String) {
        if let sub = subscribers[streamKey] {
            super.removeSubscriber(streamKey)
            
            if selectedSubscriber == streamKey {
                sub.view.removeFromSuperview()
                if let newSelectedSub = subsInScroll.first {
                    promoteSubToBigView(newSelectedSub)
                }
            } else {
                removeSubscriberFromScroll(sub)
            }
        }
    }
    
    func addSubscriberToScroll(sub: OTSubscriber) {
        subsInScroll.insert(sub)
        
        var tapGesture = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        tapGesture.numberOfTapsRequired = 2
        sub.view.addGestureRecognizer(tapGesture)
        
        updateScrollView()
        
        sub.preferredResolution = sub.view.frame.size
        sub.preferredFrameRate = 15
    }
    
    func updateScrollView() {
        let viewWidth = self.scrollView!.frame.size.height * 1.3
        let padding : CGFloat = 20
        
        for (index,sub) in enumerate(subsInScroll) {
            sub.view.removeFromSuperview()
            sub.view.frame = CGRectMake(CGFloat(index) * (viewWidth + padding), 0,
                viewWidth, self.scrollView!.frame.size.height)
            
            sub.view.tag = find(subscribers.keys.array, sub.stream.streamId)!
            
            self.scrollView?.addSubview(sub.view)
        }
        
        self.scrollView?.contentSize = CGSizeMake(CGFloat(subsInScroll.count) * (viewWidth + padding), self.scrollView!.frame.size.height)
    }
    
    func removeSubscriberFromScroll(sub: OTSubscriber) {
        subsInScroll.remove(sub)
        updateScrollView()
    }
    
    func addSubscriberToBigView(sub: OTSubscriber) {
        sub.view.frame = CGRectMake(0, 0, self.bigView!.frame.size.width, self.bigView!.frame.size.height)
        self.bigView!.addSubview(sub.view)
        sub.preferredResolution = self.bigView!.frame.size
        sub.preferredFrameRate = 30
    }
    
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        if let subIndex = gestureRecognizer.view?.tag,
            sub = subscribers[subscribers.keys.array[subIndex]],
            selectedSub = subscribers[self.selectedSubscriber!]
        {
            selectedSub.view.removeFromSuperview()
            addSubscriberToScroll(selectedSub)
            
            promoteSubToBigView(sub)
        }
    }
    
    func promoteSubToBigView(sub: OTSubscriber) {
        removeSubscriberFromScroll(sub)
        addSubscriberToBigView(sub)
        
        selectedSubscriber = sub.stream.streamId
    }
    
}
