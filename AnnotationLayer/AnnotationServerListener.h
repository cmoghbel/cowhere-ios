//
//  ServerListener.h
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AnnotationServerListenerDelegate <NSObject>

- (void)receivedMessage:(NSDictionary *)json;

@end

@interface AnnotationServerListener : NSObject <NSURLConnectionDataDelegate,
                                                NSURLConnectionDelegate>

@property id <AnnotationServerListenerDelegate> delegate;

- (void)joinSession:(NSString *)session withUsername:(NSString *)username;

@end
