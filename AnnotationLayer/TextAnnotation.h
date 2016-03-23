//
//  TextAnnotation.h
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TextAnnotation : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSNumber *startX;
@property (nonatomic, strong) NSNumber *startY;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSNumber *page;

@end
