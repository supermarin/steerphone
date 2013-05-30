//
//  SocketIO+Singleton.h
//  Steerphone
//
//  Created by Marin Usalj on 4/20/13.
//  Copyright (c) 2013 mneorr.com. All rights reserved.
//

#import "SocketIO.h"

@interface SocketIO (Singleton)

+ (instancetype)sharedInstance;

@end
