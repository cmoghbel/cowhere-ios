//
//  AnnotationServerBroadcaster.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnotationServerBroadcaster.h"
#import "SBJson.h"

@interface AnnotationServerBroadcaster ()

@end

@implementation AnnotationServerBroadcaster

@synthesize session = _session;
@synthesize username = _username;
@synthesize connectionId = _connectionId;
@synthesize messageSent = _messageSent;

- (void)broadcastMessage:(NSDictionary *)message
{
    // NSString *json = [message JSONRepresentation];
    NSLog(@"Message: %@", message);
    NSLog(@"Message JSON: %@", [message JSONRepresentation]);
    NSString *broadcastString = [NSString stringWithFormat:@"http://184.169.151.213/s/?s=%@&c=%@&b=%@", self.session, self.connectionId, [message JSONRepresentation]];
    broadcastString = [broadcastString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *broadcastURL = [[NSURL alloc] initWithString:broadcastString];
    NSMutableURLRequest *broadcastRequest = [[NSMutableURLRequest alloc] initWithURL:broadcastURL];
    [broadcastRequest setHTTPMethod:@"GET"];
    [broadcastRequest setCachePolicy:NSURLCacheStorageNotAllowed];
    [broadcastRequest setTimeoutInterval:60];
    
    NSLog(@"Trying to broadcast message string: %@", broadcastString);
    NSLog(@"Trying to broadcast message url: %@", broadcastURL);
    
    self.messageSent = NO;
    NSLog(@"Attempting to create a connection");
    NSLog(@"Is%@ main thread", ([NSThread isMainThread] ? @"" : @" NOT"));
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:broadcastRequest delegate:self startImmediately:NO];
    
    // TODO: Should really implement delegate and acknowledge status of request.
    
    [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Broadcast did receive data: %@", data);
    NSLog(@"...with message: %@", [data JSONValue]);
    self.messageSent = YES;    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"Broadcast did receive response: %@", response);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"ERROR: %@", error);
}

@end
