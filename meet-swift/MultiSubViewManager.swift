//
//  MultiSubViewManager.swift
//  meet-swift
//
//  Created by Roberto Perez Cubero on 11/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import Foundation
import OpenTok

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
        
        if let _ = selectedSubscriber {
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        tapGesture.numberOfTapsRequired = 2
        sub.view.addGestureRecognizer(tapGesture)
        
        updateScrollView()
        
        sub.preferredResolution = sub.view.frame.size
        sub.preferredFrameRate = 15
    }
    
    func updateScrollView() {
        let viewWidth = self.scrollView!.frame.size.height * 1.3
        let padding : CGFloat = 20
        
        for (index,sub) in subsInScroll.enumerate() {
            sub.view.removeFromSuperview()
            sub.view.frame = CGRectMake(CGFloat(index) * (viewWidth + padding), 0,
                viewWidth, self.scrollView!.frame.size.height)
            
            sub.view.tag = Array(subscribers.keys).indexOf(sub.stream.streamId)!
            
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
            sub = subscribers[Array(subscribers.keys)[subIndex]],
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

