//
//  AnnotationServerBroadcaster.h
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnnotationServerBroadcaster : NSObject <NSURLConnectionDataDelegate>

@property NSString *session;
@property NSString *username;
@property NSString *connectionId;

@property BOOL messageSent;

- (void)broadcastMessage:(NSDictionary *)message;

@end
