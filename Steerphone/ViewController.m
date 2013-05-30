//
//  ViewController.m
//  Steerphone
//
//  Created by Marin Usalj on 4/20/13.
//  Copyright (c) 2013 mneorr.com. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "SocketIO+Singleton.h"

@interface ViewController ()<SocketIODelegate>
@property (strong, nonatomic) IBOutlet UILabel *connectionStatus;
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
    [[SocketIO sharedInstance] setDelegate:self];
    self.queue = [[NSOperationQueue alloc] init];
    [self connectToSocket];
    [self listenToDeviceMotions];
}

#pragma mark - Private

- (void)connectToSocket {
    [[SocketIO sharedInstance] connectToHost:@"db.whoapi.com" onPort:666];
}

- (void)maintainConnection {
    if ([SocketIO sharedInstance].isConnected || [SocketIO sharedInstance].isConnecting) return;
    
    [self performSelector:@selector(connectToSocket) withObject:nil afterDelay:1];
}

- (void)listenToDeviceMotions {
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setDeviceMotionUpdateInterval:UPDATE_INTERVAL];
    [self.motionManager setGyroUpdateInterval:UPDATE_INTERVAL];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:self.queue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        self.wheelValue = @(180.0f / M_PI * motion.attitude.pitch * -1);
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
    
    [[SocketIO sharedInstance] sendEvent:@"mobile-input" withData:defaultParams];
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
    [[SocketIO sharedInstance] sendEvent:@"device-add" withData:nil];
    self.connectionStatus.textColor = [UIColor colorWithRed:.2 green:.8 blue:.3 alpha:1];
}
- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"SocketIO did disconnect!: %@", error);
    self.connectionStatus.textColor = [UIColor colorWithRed:.8 green:.2 blue:.3 alpha:1];
    [self maintainConnection];
}

- (void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"SocketIO error: %@", error);
    self.connectionStatus.textColor = [UIColor colorWithRed:.8 green:.2 blue:.3 alpha:1];
    [self maintainConnection];
}

#pragma mark - Compatibility

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft;
}

@end
