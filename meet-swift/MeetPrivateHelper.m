//
//  MeetPrivateHelper.m
//  meet-swift
//
//  Created by jaoo on 28/2/17.
//  Copyright © 2017 tokbox. All rights reserved.
//

#import "MeetPrivateHelper.h"

@interface OpenTokObjC: NSObject
+ (void)enableH264Codec;
@end


@implementation MeetPrivateHelper
+ (void)enableH264Codec {
    [OpenTokObjC enableH264Codec];
}
@end
