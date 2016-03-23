//
//  AnnotationView.h
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnnotationView : UIView

@property (nonatomic) int currentPage;
@property (nonatomic, strong) UIColor *toolColor;
@property (nonatomic) double toolWidth;
@end
