//
//  SocketIO+Singleton.m
//  Steerphone
//
//  Created by Marin Usalj on 4/20/13.
//  Copyright (c) 2013 mneorr.com. All rights reserved.
//

#import "SocketIO+Singleton.h"

@implementation SocketIO (Singleton)

#pragma mark - Singleton
static SocketIO *singleton;

+ (instancetype)sharedInstance {
    static dispatch_once_t singletonToken;
    dispatch_once(&singletonToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}


@end
