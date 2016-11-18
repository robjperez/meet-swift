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
        Bundle.main.loadNibNamed("MultiView", owner: self, options: nil)
        self.addSubview(self.view)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func addSubscriber(_ sub: OTSubscriber, streamKey: String) {
        super.addSubscriber(sub, streamKey: streamKey)
        
        if let _ = selectedSubscriber {
            self.addSubscriberToScroll(sub)
        } else {
            self.selectedSubscriber = streamKey
            self.addSubscriberToBigView(sub)
        }
    }
    
    override func removeSubscriber(_ streamKey: String) {
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
    
    func addSubscriberToScroll(_ sub: OTSubscriber) {
        subsInScroll.insert(sub)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MultiSubViewManager.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        sub.view.addGestureRecognizer(tapGesture)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(MultiSubViewManager.handleSwipe(_:)))
        swipeGesture.direction = UISwipeGestureRecognizerDirection.up
        sub.view.addGestureRecognizer(swipeGesture)
        
        updateScrollView()
        
        sub.preferredResolution = sub.view.frame.size
        sub.preferredFrameRate = 15
    }
    
    func updateScrollView() {
        let viewWidth = self.scrollView!.frame.size.height * 1.3
        let padding : CGFloat = 20
        
        for (index,sub) in subsInScroll.enumerated() {
            sub.view.removeFromSuperview()
            sub.view.frame = CGRect(x: CGFloat(index) * (viewWidth + padding), y: 0,
                width: viewWidth, height: self.scrollView!.frame.size.height)
            
            sub.view.tag = Array(subscribers.keys).index(of: (sub.stream?.streamId)!)!
            
            self.scrollView?.addSubview(sub.view)
        }
        
        self.scrollView?.contentSize = CGSize(width: CGFloat(subsInScroll.count) * (viewWidth + padding), height: self.scrollView!.frame.size.height)
    }
    
    func removeSubscriberFromScroll(_ sub: OTSubscriber) {
        subsInScroll.remove(sub)
        updateScrollView()
    }
    
    func addSubscriberToBigView(_ sub: OTSubscriber) {
        sub.view.frame = CGRect(x: 0, y: 0, width: self.bigView!.frame.size.width, height: self.bigView!.frame.size.height)
        self.bigView!.addSubview(sub.view)
        sub.preferredResolution = self.bigView!.frame.size
        sub.preferredFrameRate = 30
    }
    
    func handleSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        if let subIndex = gestureRecognizer.view?.tag,
            let sub = subscribers[Array(subscribers.keys)[subIndex]],
            let selectedSub = subscribers[self.selectedSubscriber!]
        {
            selectedSub.view.removeFromSuperview()
            addSubscriberToScroll(selectedSub)
            
            promoteSubToBigView(sub)
        }
    }
    
    func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if let subIndex = gestureRecognizer.view?.tag,
            let sub = subscribers[Array(subscribers.keys)[subIndex]]
        {
            sub.subscribeToVideo = !sub.subscribeToVideo
        }
    }
    
    func promoteSubToBigView(_ sub: OTSubscriber) {
        removeSubscriberFromScroll(sub)
        addSubscriberToBigView(sub)
        
        selectedSubscriber = sub.stream?.streamId
    }    
}

