//
//  OTKLogger.m
//  meet-swift
//
//  Created by Roberto Perez Cubero on 07/09/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

#import "OTKLogger.h"

@interface OpenTokObjC : NSObject
+ (void)setLogBlockQueue:(dispatch_queue_t)queue;
+ (void)setLogBlock:(void (^)(NSString* message, void* arg))logBlock;
@end

static dispatch_queue_t _logQueue;

@implementation OTKLogger
+ (void)initialize {
    _logQueue = dispatch_queue_create("log-queue", DISPATCH_QUEUE_SERIAL);
    [OpenTokObjC setLogBlockQueue:_logQueue];
    [OpenTokObjC setLogBlock:^(NSString *message, void *arg) {
        NSLog(@"%@", message);
    }];
}
@end
