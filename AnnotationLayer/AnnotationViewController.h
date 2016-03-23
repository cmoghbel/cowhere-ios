//
//  AnnotationViewController.h
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDFScrollView.h"
#import "AnnotationServerListener.h"

@interface AnnotationViewController : UIViewController <AnnotationServerListenerDelegate,
                                                        AnnotationDelegate>

@property NSString *session;
@property NSString *username;

@end
