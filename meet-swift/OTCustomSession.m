//
//  OTCustomSession.m
//  meet-swift
//
//  Created by Roberto Perez Cubero on 27/10/15.
//  Copyright © 2015 tokbox. All rights reserved.
//

#import "OTCustomSession.h"

@interface OTSession ()
 - (void)setApiRootURL:(NSURL*)aURL;
@end

@implementation OTCustomSession
- (id)init {
    self = [super init];
    return self;
}

- (void)setApiRootURL:(NSURL *)aURL {
    [super setApiRootURL:aURL];
}
@end
