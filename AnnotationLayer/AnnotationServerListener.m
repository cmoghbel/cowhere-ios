//
//  ServerListener.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnotationServerListener.h"
#import "SBJson.h"

@interface AnnotationServerListener ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSString *session;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *connectionId;

@end

@implementation AnnotationServerListener

@synthesize delegate = _delegate;
@synthesize connection = _connection;
@synthesize session = _session;
@synthesize username = _username;
@synthesize connectionId = _connectionId;

- (void)joinSession:(NSString *)session withUsername:(NSString *)username
{
    NSLog(@"Trying to join a session...");
    NSString *joinString = [NSString stringWithFormat:@"http://184.169.151.213:80/r/?s=%@&u=%@", session, username];
    NSURL *joinURL = [[NSURL alloc] initWithString:joinString];
    NSMutableURLRequest *joinRequest = [[NSMutableURLRequest alloc] initWithURL:joinURL];
    [joinRequest setHTTPMethod:@"GET"];
    [joinRequest setCachePolicy:NSURLCacheStorageNotAllowed];
    [joinRequest setTimeoutInterval:10000000];
    
    NSLog(@"Attempting to create a connection");
//    NSLog(@"Is%@ main thread", ([NSThread isMainThread] ? @"" : @" NOT"));
    self.connection = [[NSURLConnection alloc] initWithRequest:joinRequest delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//    NSLog(@"%@", data);
    
    char *buf = malloc(1024);
    int counter = 0;
    for (int i = 0; i < [data length]; ++i)
    {
        char c = ((char *)data.bytes)[i];
        if (c != '\n')
        {
            buf[counter] = c;
            counter += 1;
        }
        else
        {
//            NSLog(@"Buf: %s", buf);
            NSData *messageData = [NSData dataWithBytes:buf length:counter];
            NSDictionary* message = [messageData JSONValue];
            NSLog(@"JSON Message %@", message);
            if (message) [self.delegate receivedMessage:message];
            
            free(buf);
            buf = malloc(1024);
            counter = 0;
        }
    }
    free(buf);

//    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];    
//    NSDictionary *json = [jsonParser objectWithData:data];
////    NSLog(@"JSON: %@", json);
//    if (json) [self.delegate receivedMessage:json];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (response)
    {
        NSLog(@"Response: %@", response);
        NSLog(@"Response: %@", response.URL);
        NSLog(@"Response: %@", response.MIMEType);
    }
    else
    {
        NSLog(@"Response is nil!");
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Connection %@", connection);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"ERROR: %@", error);
}

@end
