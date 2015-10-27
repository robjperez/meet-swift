//
//  OTCustomSession.h
//  meet-swift
//
//  Created by Roberto Perez Cubero on 27/10/15.
//  Copyright © 2015 tokbox. All rights reserved.
//

#import <OpenTok/OpenTok.h>

 @interface OTCustomSession : OTSession
 - (void)setApiRootURL:(NSURL*)aURL;
 @end
 