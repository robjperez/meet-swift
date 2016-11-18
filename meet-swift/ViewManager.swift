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
    let avatarImageTag = 100
    
    @IBOutlet var view: UIView!
    
    required init!(frame: CGRect, rootView: UIView) {
        super.init(frame: frame)
        self.rootView = rootView
        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubscriber(_ sub: OTSubscriber, streamKey: String) {
        subscribers[streamKey] = sub
    }
    
    func removeSubscriber(_ streamKey: String) {
        self.subscribers.removeValue(forKey: streamKey)
    }
    
    func subscriberVideoDisabled(_ streamKey: String) {
        if let sub = subscribers[streamKey] {
            let imageView = UIImageView(image: UIImage(named: "avatar.png"))
            imageView.tag = avatarImageTag
            imageView.frame = sub.view.frame
            sub.view.addSubview(imageView)
        }
    }
    
    func subscriberVideoEnabled(_ streamKey: String) {
        if let sub = subscribers[streamKey] {
            sub.view.viewWithTag(avatarImageTag)?.removeFromSuperview()
        }
    }
    
    func onEnterBackground () {
    }
    
    func onEnterForeground() {
    }
}
