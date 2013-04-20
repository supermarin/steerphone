//
//  ViewController.m
//  Steerphone
//
//  Created by Marin Usalj on 4/20/13.
//  Copyright (c) 2013 mneorr.com. All rights reserved.
//

#import "ViewController.h"
#import "SocketIO.h"

@interface ViewController ()<SocketIODelegate>
@property (strong, nonatomic) SocketIO *socketIO;
@property (weak, nonatomic) IBOutlet UILabel *wheelValueLabel;
@property (atomic) BOOL brakeIsPressed;
@property (atomic) BOOL throttleIsPressed;
@end

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.socketIO = [[SocketIO alloc] initWithDelegate:self];
    [self connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.socketIO = nil;
}


#pragma mark - Private

- (void)connect {
    [self.socketIO connectToHost:@"db.whoapi.com" onPort:666];
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
    [self pingServer];
}

- (NSNumber *)wheelValue {
    return @(42);
}

#pragma mark - SocketIO delegate

- (void)socketIODidConnect:(SocketIO *)socket {
    NSLog(@"SocketIO did connect! %@", socket);
    [NSTimer scheduledTimerWithTimeInterval:1/20 target:self selector:@selector(updateServerInBackground) userInfo:nil repeats:YES];
}
- (void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"SocketIO did disconnect!: %@", error);
}
- (void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    NSLog(@"SocketIO : %@", packet);
}
- (void)socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    NSLog(@"SocketIO: %@", packet);
}
- (void)socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    NSLog(@"SocketIO: %@", packet);
}
- (void)socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    NSLog(@"SocketIO: %@", packet);
}
- (void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"SocketIO: %@", error);
}

@end
