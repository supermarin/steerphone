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
@property (weak, nonatomic) IBOutlet UILabel *wheelValueLabel;
@property (strong, nonatomic) SocketIO *socketIO;
@property (strong, nonatomic) NSOperationQueue *queue;

#pragma mark - Control states
@property (atomic) BOOL brakeIsPressed;
@property (atomic) BOOL throttleIsPressed;
@end

static CGFloat const UPDATE_INTERVAL = 1 / 20;

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.socketIO = [[SocketIO alloc] initWithDelegate:self];
    self.queue = [[NSOperationQueue alloc] init];
    [self connectToSocket];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.socketIO = nil;
}


#pragma mark - Private

- (void)connectToSocket {
    [self.socketIO connectToHost:@"db.whoapi.com" onPort:666];
}

- (void)listenToGyroscope {
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    [manager setGyroUpdateInterval:UPDATE_INTERVAL];
    [manager startGyroUpdatesToQueue:self.queue withHandler:^(CMGyroData *gyroData, NSError *error) {
       // ovdje do the math
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
    NSMutableDictionary *defaultParams = @{ @"wheel": [self wheelValue] }.mutableCopy;
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

- (NSNumber *)wheelValue {
    return @(42);
}

#pragma mark - SocketIO delegate

- (void)socketIODidConnect:(SocketIO *)socket {
    NSLog(@"SocketIO did connect! %@", socket);
//    [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(updateServerInBackground) userInfo:nil repeats:YES];
}
- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"SocketIO did disconnect!: %@", error);
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"SocketIO error: %@", error);
}

@end
