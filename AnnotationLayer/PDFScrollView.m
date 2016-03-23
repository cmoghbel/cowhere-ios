//    File: PDFScrollView.m
//Abstract: UIScrollView subclass that handles the user input to zoom the PDF page.  This class handles swapping the TiledPDFViews when the zoom level changes.
// Version: 1.0
//
//Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//Inc. ("Apple") in consideration of your agreement to the following
//terms, and your use, installation, modification or redistribution of
//this Apple software constitutes acceptance of these terms.  If you do
//not agree with these terms, please do not use, install, modify or
//redistribute this Apple software.
//
//In consideration of your agreement to abide by the following terms, and
//subject to these terms, Apple grants you a personal, non-exclusive
//license, under Apple's copyrights in this original Apple software (the
//"Apple Software"), to use, reproduce, modify and redistribute the Apple
//Software, with or without modifications, in source and/or binary forms;
//provided that if you redistribute the Apple Software in its entirety and
//without modifications, you must retain this notice and the following
//text and disclaimers in all such redistributions of the Apple Software.
//Neither the name, trademarks, service marks or logos of Apple Inc. may
//be used to endorse or promote products derived from the Apple Software
//without specific prior written permission from Apple.  Except as
//expressly stated in this notice, no other rights or licenses, express or
//implied, are granted by Apple herein, including but not limited to any
//patent rights that may be infringed by your derivative works or by other
//works in which the Apple Software may be incorporated.
//
//The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//POSSIBILITY OF SUCH DAMAGE.
//
//Copyright (C) 2010 Apple Inc. All Rights Reserved.
//

#import "PDFScrollView.h"
#import "TiledPDFView.h"
#import <QuartzCore/QuartzCore.h>

@interface PDFScrollView ()

/*** PDF Stuff ***/
@property (nonatomic) CGPDFDocumentRef pdf;
@property (nonatomic) CGPDFPageRef page;
// current pdf zoom scale
@property (nonatomic) CGFloat pdfScale;
// A low res image of the PDF page that is displayed until the TiledPDFView
// renders its content.
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *oldBackgroundImageView;
// The TiledPDFView that is currently front most
@property (nonatomic, strong) TiledPDFView *pdfView;
// The old TiledPDFView that we draw on top of when the zooming stops
@property (nonatomic, strong) TiledPDFView *oldPDFView;

@property (nonatomic, strong) UIView *containerView;

/* Annotation Stuff */
//@property (nonatomic, strong) NSMutableOrderedSet *points;
@property (nonatomic, strong) NSMutableDictionary *userAnnotations;
@property (nonatomic, strong) NSMutableArray *xs;
@property (nonatomic, strong) NSMutableArray *ys;
@property (nonatomic, strong) NSMutableDictionary *cachedImages;
@property (nonatomic, strong) UIImageView *oldAnnotationImageView;
@property (nonatomic, strong) NSMutableDictionary *userPaths;
@property (nonatomic, strong) NSMutableDictionary *userTextAnnotations;
@property (nonatomic) int currentTool;
@property (nonatomic) float currentZoomScale;
@property (nonatomic, strong) NSValue *lastPoint;

@end

@implementation PDFScrollView

double const DEFAULT_HIGHLIGHTER_TOOL_WIDTH = 10.0;
double const DEFAULT_HIGHLIGHTER_TOOL_ALPHA = 0.25;
double const DEFAULT_PENCIL_TOOL_WIDTH = 2.0;
double const DEFAULT_PENCIL_TOOL_ALPHA = 1.0;
double const DEFAULT_ERASER_TOOL_WIDTH = 15.0;
double const DEFAULT_ERASER_TOOL_ALPHA = 1.0;

BOOL PAGE_HAS_CHANGED = YES;

/*** PDF Stuff ***/
@synthesize pdf = _pdf;
@synthesize page = _page;
@synthesize pdfScale = _pdfScale;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize oldBackgroundImageView = _oldBackgroundImageView;
@synthesize pdfView = _pdfView;
@synthesize oldPDFView = _oldPDFView;
@synthesize currentPage = _currentPage;
@synthesize lastPoint = _lastPoint;

@synthesize containerView = _containerView;

/*** Annotation Stuff ***/
@synthesize userAnnotations = _userAnnotations;
@synthesize userPaths = _userPaths;
//@synthesize points = _points;
@synthesize cachedImages = _cachedImages;
@synthesize toolColor = _toolColor;
@synthesize toolWidth = _toolWidth;
@synthesize toolAlpha = _toolAlpha;

@synthesize annotationToolColor = _annotationToolColor;
@synthesize annotationToolWidth = _annotationToolWidth;
@synthesize annotationToolAlpha = _annotationToolAlpha;

@synthesize oldAnnotationImageView = _oldAnnotationImageView;
@synthesize xs = _xs;
@synthesize ys = _ys;

@synthesize annotationDelegate = _annotationDelegate;
@synthesize idToIgnore = _idToIgnore;
@synthesize userTextAnnotations = _userTextAnnotations;
@synthesize currentTool;
@synthesize currentZoomScale = _currentZoomScale;
@synthesize continuation = _continuation;

/*************************************/
/*** Getters w/ Lazy Instantiation ***/
/*************************************/

//-(NSValue *)lastPoint
//{
//    if (!_lastPoint)
//    {
//        _lastPoint = [[NSValue alloc] init];
//    }
//    return _lastPoint;
//}

- (float)currentZoomScale
{
    if (_currentZoomScale < 1.0) return 1.0;
    return _currentZoomScale;
}

- (CGPDFDocumentRef)pdf
{
    if (!_pdf)
    {
        // Open the PDF document
//        NSURL *pdfURL = [[NSBundle mainBundle] URLForResource:@"51_4374_20120420_201423.pdf" withExtension:nil];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);    
        NSString *documentsDirectory = [paths objectAtIndex:0];	
        NSString *pdfPath = [documentsDirectory stringByAppendingPathComponent:@"temp.pdf"];
        NSURL *pdfurl = [[NSURL alloc] initFileURLWithPath:pdfPath];
        
//        _pdf = CGPDFDocumentCreateWithURL((__bridge_retained CFURLRef)pdfURL);
        _pdf = CGPDFDocumentCreateWithURL((__bridge_retained CFURLRef)pdfurl);
    }
    return _pdf;
}

- (CGPDFPageRef)page
{
    if (!_page)
    {
        // Get the PDF Page that we will be drawing
        _page = CGPDFDocumentGetPage(self.pdf, self.currentPage);
		CGPDFPageRetain(_page);
    }
    return _page;
}

- (int)currentPage
{
    if (_currentPage == 0) _currentPage = 1;
    return _currentPage;
}

- (UIImageView *)backgroundImageView
{
    if (!_backgroundImageView)
    {
        _backgroundImageView = [[UIImageView alloc] init];
    }
    return _backgroundImageView;
}

- (UIImageView *)oldBackgroundImageView
{
    if (!_oldBackgroundImageView)
    {
        _oldBackgroundImageView = [[UIImageView alloc] init];
    }
    return _oldBackgroundImageView;
}

//- (NSMutableOrderedSet *)points
//{
//    if (!_points) _points = [[NSMutableOrderedSet alloc] init];
//    return _points;
//}

- (NSMutableDictionary *)userAnnotations
{
    if (!_userAnnotations) _userAnnotations = [[NSMutableDictionary alloc] init];
    return _userAnnotations;
}

- (NSMutableDictionary *)userPaths
{
    if (!_userPaths) _userPaths = [[NSMutableDictionary alloc] init];
    return _userPaths;
}

- (NSMutableDictionary *)cachedImages
{
    if (!_cachedImages) _cachedImages = [[NSMutableDictionary alloc] init];
    return _cachedImages;
}

- (NSMutableDictionary *)userTextAnnotations
{
    if (!_userTextAnnotations) _userTextAnnotations = [[NSMutableDictionary alloc] init];
    return _userTextAnnotations;
}

- (UIColor *)toolColor
{
    if (!_toolColor)
    {
        _toolColor = [UIColor redColor];
    }
    return _toolColor;
}

- (UIColor *)annotationToolColor
{
    if (!_annotationToolColor)
    {
        _annotationToolColor = [UIColor redColor];
    }
    return _annotationToolColor;
}

- (UIImageView *)oldAnnotationImageView
{
    return _oldAnnotationImageView;
}

- (NSMutableArray *)xs
{
    if (!_xs) _xs = [[NSMutableArray alloc] init];
    return _xs;
}

- (NSMutableArray *)ys
{
    if (!_ys) _ys = [[NSMutableArray alloc] init];
    return _ys;
}


/**************************/
/*** Public API Methods ***/
/**************************/


- (void) goToNextPage
{
    if (self.currentPage + 1 <= CGPDFDocumentGetNumberOfPages(self.pdf))
    {
        [self changePageToPageNum:self.currentPage+1];
    }
}

- (void) goToPrevPage
{
    if (self.currentPage - 1 >= 1) [self changePageToPageNum:self.currentPage-1];
}

- (void)switchToHighlighterTool
{
    self.toolColor = [UIColor yellowColor];
    self.toolWidth = DEFAULT_HIGHLIGHTER_TOOL_WIDTH;
    self.toolAlpha = DEFAULT_HIGHLIGHTER_TOOL_ALPHA;
    self.scrollEnabled = NO;
}

- (void)switchToPencilTool
{
    self.toolColor = [UIColor blackColor];
    self.toolWidth = DEFAULT_PENCIL_TOOL_WIDTH;
    self.toolAlpha = DEFAULT_PENCIL_TOOL_ALPHA;
    self.scrollEnabled = NO;
}

- (void)switchToEraserTool
{
    self.toolColor = [UIColor whiteColor];
    self.toolWidth = DEFAULT_ERASER_TOOL_WIDTH;
    self.toolAlpha = DEFAULT_ERASER_TOOL_ALPHA;
    self.scrollEnabled = NO;
}

- (void) switchToHandTool
{
    self.toolAlpha = 0.0;
    self.scrollEnabled = YES;
}

- (void)annotate:(NSNumber *)page
   withToolSize:(NSNumber *)toolWidth
    andToolColor:(UIColor *)toolColor
    andToolAlpha:(NSNumber *)toolAlpha
           andXs:(NSArray *)xs
           andYs:(NSArray *)ys
       andUserId:(NSString *)userId
 andContinuation:(BOOL)continuation
{
//    NSLog(@"Got to annotate!");
    if (self.currentPage != page.intValue)
    {
        [self changePageToPageNum:page.intValue];
    }
    
    NSMutableArray *points = [self getAnnotationsForUser:userId];
    for (int i = 0; i < xs.count; ++i) {
        NSNumber *x = [xs objectAtIndex:i];
        NSNumber *y = [ys objectAtIndex:i];
        CGPoint point = CGPointMake(x.floatValue, y.floatValue);
        NSValue *val = [[NSValue valueWithCGPoint:point] init];

        [points addObject:val];
    }
    
    self.annotationToolWidth = toolWidth.intValue;
    self.annotationToolColor = toolColor;
    NSLog(@"Tool Alpha: %@", toolAlpha);
    self.annotationToolAlpha = toolAlpha.doubleValue;
//    self.continuation = continuation;
    
    [self setNeedsDisplay];
}

- (void)addTextAnnotation:(TextAnnotation *)textAnnotation
{
    NSLog(@"Let's add some text!");
    [self.userTextAnnotations setValue:textAnnotation forKey:textAnnotation.userId];
    [self setNeedsDisplay];
}

/******************************/
/*** Private Helper Methods ***/
/******************************/


- (void)changePageToPageNum:(int)pageNum
{
    // Get the PDF Page that we will be drawing
    self.currentPage = pageNum;
    CGPDFPageRelease(_page);
    _page = CGPDFDocumentGetPage(self.pdf, pageNum);
    CGPDFPageRetain(_page);
    PAGE_HAS_CHANGED = YES;
    [self setNeedsDisplay];
}

- (NSMutableArray *)getAnnotationsForUser:(NSString *)userId
{
    NSMutableArray *points = [self.userAnnotations objectForKey:userId];
    if (!points)
    {
        points = [[NSMutableArray alloc] init];
        [self.userAnnotations setValue:points forKey:userId];
    }
    return points;
}


/**********************/
/*** Touch Handling ***/
/**********************/


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableArray *points = [self getAnnotationsForUser:@"1"];
    
    for (UITouch *touch in touches)
    {
        NSNumber *x = [NSNumber numberWithFloat:[touch locationInView:self].x];
        NSNumber *y = [NSNumber numberWithFloat:[touch locationInView:self].y];        
        NSNumber *scaledX = [NSNumber numberWithFloat:x.intValue / self.currentZoomScale];
        NSNumber *scaledY = [NSNumber numberWithFloat:y.intValue / self.currentZoomScale];
        
        CGPoint point = CGPointMake(scaledX.floatValue, scaledY.floatValue);
        NSValue *val = [[NSValue valueWithCGPoint:point] init];
        [points addObject:val];

        [self.xs addObject:scaledX];
        [self.ys addObject:scaledY];
    }
    
    if (self.xs.count > 20)
    {
        [self.annotationDelegate annotationDrawn:[NSNumber numberWithInt:self.currentPage]
                                     wihToolSize:[NSNumber numberWithDouble:self.toolWidth]
                                    andToolColor:self.toolColor
                                    andToolAlpha:[NSNumber numberWithDouble:self.toolAlpha]
                                           andXs:[self.xs copy]
                                           andYs:[self.ys copy]
                                         andType:@"dd"];
        [self.xs removeAllObjects];
        [self.ys removeAllObjects];
        self.continuation = YES;
    }
    
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableArray *points = [self getAnnotationsForUser:@"1"];
    for (UITouch *touch in touches)
    {
        NSNumber *x = [NSNumber numberWithFloat:[touch locationInView:self].x];
        NSNumber *y = [NSNumber numberWithFloat:[touch locationInView:self].y];
        NSNumber *scaledX = [NSNumber numberWithFloat:x.intValue / self.currentZoomScale];
        NSNumber *scaledY = [NSNumber numberWithFloat:y.intValue / self.currentZoomScale];
        
        CGPoint point = CGPointMake(scaledX.floatValue, scaledY.floatValue);
        NSValue *val = [[NSValue valueWithCGPoint:point] init];
        [points addObject:val];                

        [self.xs addObject:scaledX];
        [self.ys addObject:scaledY];
    }
    
    if (self.xs.count > 20)
    {
        [self.annotationDelegate annotationDrawn:[NSNumber numberWithInt:self.currentPage]
                                     wihToolSize:[NSNumber numberWithDouble:self.toolWidth]
                                    andToolColor:self.toolColor
                                    andToolAlpha:[NSNumber numberWithDouble:self.toolAlpha]
                                           andXs:[self.xs copy]
                                           andYs:[self.ys copy]
                                         andType:@"dd"];
        [self.xs removeAllObjects];
        [self.ys removeAllObjects];
        self.continuation = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableArray *points = [self getAnnotationsForUser:@"1"];
    
    for (UITouch *touch in touches)
    {
        NSNumber *x = [NSNumber numberWithFloat:[touch locationInView:self].x];
        NSNumber *y = [NSNumber numberWithFloat:[touch locationInView:self].y];
        NSNumber *scaledX = [NSNumber numberWithFloat:x.intValue / self.currentZoomScale];
        NSNumber *scaledY = [NSNumber numberWithFloat:y.intValue / self.currentZoomScale];
        
        CGPoint point = CGPointMake(scaledX.floatValue, scaledY.floatValue);
        NSValue *val = [[NSValue valueWithCGPoint:point] init];
        [points addObject:val];
        
        [self.xs addObject:scaledX];
        [self.ys addObject:scaledY];
    }
    
    [self.annotationDelegate annotationDrawn:[NSNumber numberWithInt:self.currentPage]
                                 wihToolSize:[NSNumber numberWithDouble:self.toolWidth]
                                andToolColor:self.toolColor
                                andToolAlpha:[NSNumber numberWithDouble:self.toolAlpha]
                                       andXs:[self.xs copy]
                                       andYs:[self.ys copy]
                                     andType:@"de"];
    self.continuation = NO;
    
    [self.xs removeAllObjects];
    [self.ys removeAllObjects];
    
    [self setNeedsDisplay];
}


/***************/
/*** Drawing ***/
/***************/


// TODO: Refactor into two methods.
-(void)drawRect:(CGRect)rect
{   
    // Determine the size of the page.
    CGRect pageRect = CGPDFPageGetBoxRect(self.page, kCGPDFMediaBox);
//    self.pdfScale = self.frame.size.width/pageRect.size.width;
    NSLog(@"Frame width: %f", self.frame.size.width);
    NSLog(@"Frame height: %f", self.frame.size.height);
    NSLog(@"Bounds width: %f", pageRect.size.width);
    NSLog(@"Bound height: %f", pageRect.size.height);
//    self.pdfScale = self.bounds.size.width/pageRect.size.width;
    self.pdfScale = self.bounds.size.height/pageRect.size.height;
    NSLog(@"PDF Scale: %f", self.pdfScale);
    pageRect.size = CGSizeMake(pageRect.size.width*self.pdfScale, pageRect.size.height*self.pdfScale);
    CGContextRef context;
    
    if (PAGE_HAS_CHANGED)
    {
        /****************/
        /*** Draw PDF ***/
        /****************/
        
        // renders its content.
        UIGraphicsBeginImageContext(pageRect.size);
        
        context = UIGraphicsGetCurrentContext();
        
        // First fill the background with white.
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
        CGContextFillRect(context,pageRect);
        
        CGContextSaveGState(context);
        // Flip the context so that the PDF page is rendered
        // right side up.
        CGContextTranslateCTM(context, 0.0, pageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        // Scale the context so that the PDF page is rendered 
        // at the correct size for the zoom level.
        CGContextScaleCTM(context, self.pdfScale, self.pdfScale);	
        CGContextDrawPDFPage(context, self.page);
        UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRestoreGState(context);
        
        UIGraphicsEndImageContext();
        
        // Create a new view from the background image, put it in the back, and
        // remove previous background image view.
        self.backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
        self.backgroundImageView.frame = pageRect;
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.containerView addSubview:self.backgroundImageView];
        [self.containerView sendSubviewToBack:self.backgroundImageView];
        [self.oldBackgroundImageView removeFromSuperview];
        self.oldBackgroundImageView = self.backgroundImageView;
      
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
        self.pdfView = [[TiledPDFView alloc] initWithFrame:pageRect andScale:self.pdfScale];
        [self.pdfView setPage:self.page];
            
        // Add the new (page) view, and remove the previous one.
        [self.containerView addSubview:self.pdfView];
        [self.oldPDFView removeFromSuperview];
        self.oldPDFView = self.pdfView;
        
        PAGE_HAS_CHANGED = NO;
    }

    
    /************************/
    /*** Draw Annotations ***/
    /************************/
    
    
    // Open a new image context.
    UIGraphicsBeginImageContext(pageRect.size);
    context = UIGraphicsGetCurrentContext();
    
    // Set drawing parameters.
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.0);
    CGContextFillRect(context,pageRect);
    CGContextSetLineWidth(context, self.toolWidth);
    CGContextSetAlpha(context, self.toolAlpha);
    [self.toolColor setStroke];
    
    // Draw the cached image onto the image context.
    NSString *pageNum = [NSString stringWithFormat:@"%d", self.currentPage];
    UIImage *cachedImage = [self.cachedImages objectForKey:pageNum];
    if (cachedImage) [cachedImage drawAtPoint:CGPointZero];
    
    
    for (NSString *userId in self.userAnnotations) {
        if ([userId isEqualToString:self.idToIgnore])
        {
            NSLog(@"Ignoring broadcast");
            continue;
        }
        
        if (![userId isEqualToString:@"1"])
        {
            CGContextSetLineWidth(context, self.annotationToolWidth);
            if (self.annotationToolAlpha) CGContextSetAlpha(context, self.annotationToolAlpha);
            NSLog(@"Annotation tool alpha: %@", self.annotationToolAlpha);
            [self.annotationToolColor setStroke];
        }
        
        
        // Convert an array of NSValues wrapping CGPoints to a C array of CGPoints.
        NSMutableArray *points = [self.userAnnotations objectForKey:userId];        
        NSUInteger numPoints = [points count];
        CGPoint *pointsArrayInC = malloc(numPoints * sizeof(CGPoint));
        for (int i=0; i < numPoints; ++i) {
            pointsArrayInC[i] = [((NSValue *) [points objectAtIndex:i]) CGPointValue];
            self.lastPoint = ((NSValue *) [points objectAtIndex:i]);
        }
        
        CGContextAddLines(context, pointsArrayInC, numPoints);
        CGContextStrokePath(context);        
        
        // Remember to free the C array we needed to allocate.
        free(pointsArrayInC);
        
        //...And remove the points we just drew.
        [points removeAllObjects];        
    }
    
    // Add text annotations.
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    for (NSString *userId in self.userTextAnnotations)
    {
        NSLog(@"Attempting to draw text annotation for userId: %@", userId);
        TextAnnotation *textAnnotation = [self.userTextAnnotations objectForKey:userId];
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(textAnnotation.startX.floatValue, textAnnotation.startY.floatValue, 50.0, 50.0)];
        textView.font = [UIFont systemFontOfSize:20.0];
        textView.textColor = textAnnotation.color;
        textView.text = textAnnotation.text;
        textView.backgroundColor = [UIColor clearColor];
        [self.containerView addSubview:textView];
        [userIds addObject:userId];
    }
    
    [self.userTextAnnotations removeObjectsForKeys:userIds];
    
    // Replace cached image with new image.
    cachedImage = UIGraphicsGetImageFromCurrentImageContext();
    [self.cachedImages setValue:cachedImage forKey:pageNum];
    UIGraphicsEndImageContext();
    
    // Finally, draw the new image on the screen.
    context = UIGraphicsGetCurrentContext();
    
    UIImageView *cachedImageView = [[UIImageView alloc] initWithImage:cachedImage];
    cachedImageView.frame = pageRect;
    cachedImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:cachedImageView];
    [self.containerView addSubview:cachedImageView];
    [self.oldAnnotationImageView removeFromSuperview];
    self.oldAnnotationImageView = cachedImageView;
}


/***************************/
/*** Instantiation Stuff ***/
/***************************/

- (void)setup
{
    // Set up the UIScrollView
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.delegate = self;
    [self setBackgroundColor:[UIColor grayColor]];
    self.maximumZoomScale = 5.0;
    self.minimumZoomScale = 1.0;
    self.scrollEnabled = NO;
    
    self.currentPage = 1;
    self.contentMode = UIViewContentModeRedraw;
    self.toolWidth = 10.0;
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.containerView];
    
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

/*****************************/
/*** Scrolling and Zooming ***/
/*****************************/


#pragma mark -
#pragma mark Override layoutSubviews to center content

// We use layoutSubviews to center the PDF page in the view
- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    // center the image as it becomes smaller than the size of the screen
	
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.pdfView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.pdfView.frame = frameToCenter;
	self.backgroundImageView.frame = frameToCenter;
    
	// to handle the interaction between CATiledLayer and high resolution screens, we need to manually set the
	// tiling view's contentScaleFactor to 1.0. (If we omitted this, it would be 2.0 on high resolution screens,
	// which would cause the CATiledLayer to ask us for tiles of the wrong scales.)
	self.pdfView.contentScaleFactor = 1.0;
}

#pragma mark -
#pragma mark UIScrollView delegate methods

// A UIScrollView delegate callback, called when the user starts zooming. 
// We return our current TiledPDFView.
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
//    return self.pdfView;
    return self.containerView;
}

// A UIScrollView delegate callback, called when the user stops zooming.  When the user stops zooming
// we create a new TiledPDFView based on the new zoom level and draw it on top of the old TiledPDFView.
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
//	// set the new scale factor for the TiledPDFView
//	self.pdfScale *=scale;
//	
//	// Calculate the new frame for the new TiledPDFView
//	CGRect pageRect = CGPDFPageGetBoxRect(self.page, kCGPDFMediaBox);
//	pageRect.size = CGSizeMake(pageRect.size.width*self.pdfScale, pageRect.size.height*self.pdfScale);
//	
//	// Create a new TiledPDFView based on new frame and scaling.
//	self.pdfView = [[TiledPDFView alloc] initWithFrame:pageRect andScale:self.pdfScale];
//	[self.pdfView setPage:self.page];
//	
//	// Add the new TiledPDFView to the PDFScrollView.
////	[self addSubview:self.pdfView];
//    [self.containerView addSubview:self.pdfView];
    self.currentZoomScale = scale;
}

// A UIScrollView delegate callback, called when the user begins zooming.  When the user begins zooming
// we remove the old TiledPDFView and set the current TiledPDFView to be the old view so we can create a
// a new TiledPDFView when the zooming ends.
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
	// Remove back tiled view.
	[self.oldPDFView removeFromSuperview];
//	[self.oldPDFView release];
	
	// Set the current TiledPDFView to be the old view.
	self.oldPDFView = self.pdfView;
//	[self addSubview:self.oldPDFView];
    [self.containerView addSubview:self.oldPDFView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"About to drag!");
}

@end
