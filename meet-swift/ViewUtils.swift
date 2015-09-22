//
//  ViewUtils.swift
//  meet-swift
//
//  Created by Roberto Perez Cubero on 10/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import Foundation

class ViewUtils {
    static func addViewFill (view: UIView, rootView: UIView) {
//        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        rootView.insertSubview(view, atIndex: 0)
        
        let constraints = [
            NSLayoutConstraint(
                item:rootView,
                attribute:NSLayoutAttribute.Left,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view,
                attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: rootView,
                attribute:NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view,
                attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: rootView,
                attribute:NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view,
                attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: rootView,
                attribute:NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view,
                attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        ];
        
        rootView.addConstraints(constraints)
    }
}