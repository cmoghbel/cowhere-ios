//
//  JoinSessionViewController.h
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JoinSessionViewController : UIViewController <NSURLConnectionDataDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sessionCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;

@end
