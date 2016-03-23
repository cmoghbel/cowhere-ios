//
//  AnnotationView.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnotationView.h"

@interface AnnotationView ()
@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSMutableDictionary *cachedImages;
@end

@implementation AnnotationView

@synthesize points = _points;
@synthesize toolColor = _toolColor;
@synthesize cachedImages = _cachedImages;
@synthesize currentPage = _currentPage;
@synthesize toolWidth = _toolWidth;

- (NSMutableArray *)points
{
    if (!_points) _points = [[NSMutableArray alloc] init];
    return _points;
}

- (UIColor *)toolColor
{
    if (!_toolColor)
    {
        _toolColor = [UIColor redColor];
    }
    return _toolColor;
}

- (NSMutableDictionary *)cachedImages
{
    if (!_cachedImages) _cachedImages = [[NSMutableDictionary alloc] init];
    return _cachedImages;
}

- (int)currentPage
{
    if (_currentPage == 0) _currentPage = 1;
    return _currentPage;
}

- (void)setup
{
    self.contentMode = UIViewContentModeRedraw;
    self.toolWidth = 10.0;
    //[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        NSValue *val = [[NSValue valueWithCGPoint:[touch locationInView:self]] init];
        NSLog(@"%@", val);
        [self.points addObject:val];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint point = [touch locationInView:self];
        NSValue *val = [[NSValue valueWithCGPoint:point] init];
        NSLog(@"%@", val);
        [self.points addObject:val];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint point = [touch locationInView:self];
        NSValue *val = [[NSValue valueWithCGPoint:point] init];
        NSLog(@"%@", val);
        [self.points addObject:val];
    }

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    NSLog(@"drawRect called!");
    // Open a new image context.
    UIGraphicsBeginImageContext(self.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set drawing parameters.
    CGContextSetLineWidth(context, self.toolWidth);
    CGContextSetAlpha(context, 1.0);
    [self.toolColor setStroke];
    
    // Draw the cached image onto the image context.
    NSString *pageNum = [NSString stringWithFormat:@"%d", self.currentPage];
    UIImage *cachedImage = [self.cachedImages objectForKey:pageNum];
    if (!cachedImage) cachedImage = [[UIImage alloc] init];
    [cachedImage drawAtPoint:CGPointZero];
    
    // Convert an array of NSValues wrapping CGPoints to a C array of CGPoints.
    NSUInteger numPoints = [self.points count];
    CGPoint *pointsArrayInC = malloc(numPoints * sizeof(CGPoint));
    for (int i=0; i < numPoints; ++i) {
        pointsArrayInC[i] = [((NSValue *) [self.points objectAtIndex:i]) CGPointValue];
    }
    
    // Draw new points onto image context (aka add new line to image).
    CGContextAddLines(context, pointsArrayInC, numPoints);
    CGContextStrokePath(context);
    
    // Replace cached image with new image.
    cachedImage = UIGraphicsGetImageFromCurrentImageContext();
    [self.cachedImages setValue:cachedImage forKey:pageNum];
    UIGraphicsEndImageContext();
    
    // Remember to free the C array we needed to allocate.
    free(pointsArrayInC);
    
    //...And remove the points we just drew.
    [self.points removeAllObjects];
    
    // Finally, draw the new image on the screen.
    context = UIGraphicsGetCurrentContext();
    [cachedImage drawAtPoint:CGPointZero];
}

@end
