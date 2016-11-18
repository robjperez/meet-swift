//
//  ViewUtils.swift
//  meet-swift
//
//  Created by Roberto Perez Cubero on 10/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import Foundation

class ViewUtils {
    static func addViewFill (_ view: UIView, rootView: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        rootView.insertSubview(view, at: 0)
        
        let constraints = [
            NSLayoutConstraint(
                item:rootView,
                attribute:NSLayoutAttribute.left,
                relatedBy: NSLayoutRelation.equal,
                toItem: view,
                attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: rootView,
                attribute:NSLayoutAttribute.top,
                relatedBy: NSLayoutRelation.equal,
                toItem: view,
                attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: rootView,
                attribute:NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: view,
                attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: rootView,
                attribute:NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: view,
                attribute: NSLayoutAttribute.height, multiplier: 1, constant: 0)
        ];
        
        rootView.addConstraints(constraints)
    }
}
