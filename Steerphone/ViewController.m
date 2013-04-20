//
//  ViewController.m
//  Steerphone
//
//  Created by Marin Usalj on 4/20/13.
//  Copyright (c) 2013 mneorr.com. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "SocketIO.h"

@interface ViewController ()<SocketIODelegate>
@property (strong, nonatomic) IBOutlet UILabel *wheelValueLabel;
@property (strong, nonatomic) SocketIO *socketIO;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) CMMotionManager *motionManager;

#pragma mark - Control states
@property (atomic) BOOL brakeIsPressed;
@property (atomic) BOOL throttleIsPressed;
@property (atomic) NSNumber *wheelValue;
@end

static CGFloat const UPDATE_INTERVAL = 1.0f / 20.0f;

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.socketIO = [[SocketIO alloc] initWithDelegate:self];
    self.queue = [[NSOperationQueue alloc] init];
    [self connectToSocket];
    [self listenToGyroscope];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.socketIO = nil;
}


#pragma mark - Private

- (void)connectToSocket {
    [self.socketIO connectToHost:@"db.whoapi.com" onPort:666];
}

- (void)listenToGyroscope {
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setDeviceMotionUpdateInterval:UPDATE_INTERVAL];
    [self.motionManager setGyroUpdateInterval:UPDATE_INTERVAL];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:self.queue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        self.wheelValue = @(180.0f / M_PI * motion.attitude.pitch);
        NSLog(@"Current value: %@", self.wheelValue);
        [self pingServer];
    }];
}

- (IBAction)brakePressed:(id)sender {
    self.brakeIsPressed = YES;
    [self pingServer];
}

- (IBAction)brakeReleased:(id)sender {
    self.brakeIsPressed = NO;
    [self pingServer];
}

- (IBAction)throttlePressed:(id)sender {
    self.throttleIsPressed = YES;
    [self pingServer];
}

- (IBAction)throttleReleased:(id)sender {
    self.throttleIsPressed = NO;
    [self pingServer];
}

- (void)pingServer {
    NSMutableDictionary *defaultParams = @{ @"wheel": self.wheelValue }.mutableCopy;
    if (self.brakeIsPressed) defaultParams[@"brake"] = @(YES);
    if (self.throttleIsPressed) defaultParams[@"throttle"] = @(YES);
    
    [self.socketIO sendEvent:@"mobile-input" withData:defaultParams];
}

- (void)updateServerInBackground {
    __weak ViewController *weakSelf = self;
    [self.queue addOperationWithBlock:^{
        [weakSelf pingServer];
    }];
}

#pragma mark - SocketIO delegate

- (void)socketIODidConnect:(SocketIO *)socket {
    NSLog(@"SocketIO did connect! %@", socket);
}
- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"SocketIO did disconnect!: %@", error);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"SocketIO error: %@", error);
}

@end
