//
//  AnnotationViewController.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnnotationViewController.h"
#import "PDFScrollView.h"
#import "AnnotationServerBroadcaster.h"
#import "SBJson.h"

@interface AnnotationViewController ()

@property (nonatomic, weak) IBOutlet PDFScrollView *pdfView;
@property (nonatomic, strong) AnnotationServerBroadcaster *broadcaster;

@end

@implementation AnnotationViewController

@synthesize pdfView = _pdfView;
@synthesize broadcaster = _broadcaster;
@synthesize session = _session;
@synthesize username = _username;

dispatch_queue_t annotationBroadcasterQueue;

- (IBAction)previousButtonPressed:(id)sender
{
    [self.pdfView goToPrevPage];
}

- (IBAction)nextButtonPressed:(id)sender
{
    [self.pdfView goToNextPage];
}

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

- (IBAction)toolTypeButtonPressed:(UIBarButtonItem *) sender
{
    if ([sender.title isEqualToString:@"Pen"])
    {
        [self.pdfView switchToPencilTool];
    }
    else if ([sender.title isEqualToString:@"Highlighter"])
    {
        [self.pdfView switchToHighlighterTool];
    }
    else if ([sender.title isEqualToString:@"White Out"])
    {
        [self.pdfView switchToEraserTool];
    }
    else if ([sender.title isEqualToString:@"Hand"])
    {
        [self.pdfView switchToHandTool];
    }
}

- (IBAction)segmentedControllPressed:(UISegmentedControl *)sender forEvent:(UIEvent *)event
{
    if (sender.selectedSegmentIndex == 0)
    { 
        [self.pdfView switchToHandTool];
    }
    else if (sender.selectedSegmentIndex == 1)
    {
        [self.pdfView switchToPencilTool];
    }
    else if (sender.selectedSegmentIndex == 2)
    {
        [self.pdfView switchToHighlighterTool];
    }
    else if (sender.selectedSegmentIndex == 3)
    {
//        [self.pdfView switchToEraserTool];
//        [self.pdfView switchToTextTool];
    }
}

- (IBAction)toolColorButtonPressed:(UIBarButtonItem *)sender
{    
    if (sender.tag == 0) self.pdfView.toolColor = [UIColor redColor];
    else if (sender.tag == 1) self.pdfView.toolColor = [UIColor blueColor];
    else if (sender.tag == 2) self.pdfView.toolColor = [UIColor greenColor];
    else if (sender.tag == 3) self.pdfView.toolColor = [UIColor yellowColor];
    else if (sender.tag == 4) self.pdfView.toolColor = [UIColor blackColor];
}

- (void)receivedMessage:(NSDictionary *)json
{
    NSDictionary *message =  [json objectForKey:@"Ok"];
    if (message)
    {
        NSLog(@"Connection message received: %@", message);
        NSString *connectionId = [message objectForKey:@"connection_id"];
        if (connectionId)
        {
            NSLog(@"Connection Id: %@", connectionId);
            self.broadcaster.connectionId = connectionId;
            self.pdfView.idToIgnore = connectionId;
        }
        return;
    }
    else
    {
        if (!json)
        {
            NSLog(@"ERROR: JSON Received in callback was null?!");
            return;
        }
    }
    
    message = json;
    NSString *type = [message objectForKey:@"type"];
    if ([type isEqualToString:@"t"])
    {
        NSLog(@"Received a text command!");
        NSNumber *startX = [message objectForKey:@"sx"];
        NSNumber *startY = [message objectForKey:@"sy"];
        NSNumber *endX = [message objectForKey:@"ex"];
        NSNumber *endY = [message objectForKey:@"ey"];
        
        NSNumber *width = [NSNumber numberWithInt:(endX.intValue - startX.intValue)];
        NSNumber *height = [NSNumber numberWithInt:(startY.intValue - endY.intValue)];
        
        NSString *textValue = [message objectForKey:@"value"];
        
        NSNumber *colorNum = [json objectForKey:@"color"];
        UIColor *color = [UIColor yellowColor];
        switch (colorNum.intValue) {
            case 0:
                color = [UIColor blackColor];
                break;
            case 1:
                color = [UIColor redColor];
                break; 
            case 2:
                color = [UIColor blueColor];
                break;
            case 3:
                color = [UIColor yellowColor];
                break;
            case 4:
                color = [UIColor greenColor];
            default:
                break;
        }
        
        NSString *userId = [json objectForKey:@"id"];
        NSNumber *page = [json objectForKey:@"page"];
        
        TextAnnotation *textAnnotation = [[TextAnnotation alloc] init];
        textAnnotation.text = textValue;
        textAnnotation.page = page;
        textAnnotation.color = color;
        textAnnotation.startX = startX;
        textAnnotation.startY = startY;
        textAnnotation.width = width;
        textAnnotation.height = height;
        textAnnotation.userId = userId;
        
        [self.pdfView addTextAnnotation:textAnnotation];
    }
    else
    {   
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        // NSArray of NSNumbers
        NSArray *xs = [json objectForKey:@"x"];
        NSArray *ys = [json objectForKey:@"y"];

        NSNumber *colorNum = [json objectForKey:@"color"];
        UIColor *color = [UIColor yellowColor];
        switch (colorNum.intValue) {
            case 0:
                color = [UIColor blackColor];
                break;
            case 1:
                color = [UIColor redColor];
                break; 
            case 2:
                color = [UIColor blueColor];
                break;   
            case 3:
                color = [UIColor yellowColor];
                break;
            case 4:
                color = [UIColor greenColor];
                break;
            default:
                break;
        }
     
        NSLog(@"Converted the color ok!");
        
        NSNumber *brushVal = [json objectForKey:@"brush"];
        NSNumber *brushSize = [NSNumber numberWithInt:2];
        NSNumber *alpha = [NSNumber numberWithFloat:1.0];
        
        switch (brushVal.intValue)
        {
            case 1:
                brushSize = [NSNumber numberWithInt:1];
                break;
            case 2:
                brushSize = [NSNumber numberWithInt:2];
                break;
            case 3:
                brushSize = [NSNumber numberWithInt:4];
                break;
            case 4:
                brushSize = [NSNumber numberWithInt:10];
                alpha = [NSNumber numberWithFloat:.25];
                break;
            case 5:
                brushSize = [NSNumber numberWithInt:20];
                alpha = [NSNumber numberWithFloat:.25];
                break;
            case 6:
                brushSize = [NSNumber numberWithInt:30];
                alpha = [NSNumber numberWithFloat:.25];
                break;
            default:
                break;
        }
        
//        switch (brushVal.intValue) {
//            case 4:
//                alpha = [NSNumber numberWithFloat:.25];
//            case 1:
//                brushSize = [NSNumber numberWithInt:5];
//                break;
//            case 6:
//                alpha = [NSNumber numberWithFloat:.25];
//            case 3:
//                brushSize = [NSNumber numberWithInt:15];
//                break;
//            case 5:
//                alpha = [NSNumber numberWithFloat:.25];
//                break;
//            default:
//                break;
//        }
        
        NSLog(@"Converted the brush size ok!");
        
        
        NSString *userId = [json objectForKey:@"id"];
        if ([userId isKindOfClass:[NSString class]])
        {
            NSLog(@"User id is indeed a string!");
        }
        else {
            NSLog(@"User id is not a string?!");
        }
        
        NSNumber *page = [json objectForKey:@"page"];
        
        NSLog(@"Converted page ok!");
        
        BOOL continuation = YES;
        if ([type isEqualToString:@"de"])
        {
            continuation = NO;
        }
        
        [self.pdfView annotate:page
                  withToolSize:brushSize
                  andToolColor:color
                  andToolAlpha:alpha
                         andXs:xs
                         andYs:ys
                     andUserId:userId
               andContinuation:continuation];
    }
    
}

- (void)annotationDrawn:(NSNumber *)page
            wihToolSize:(NSNumber *)toolSize
           andToolColor:(UIColor *)toolColor
           andToolAlpha:(NSNumber *)toolAlpha
                  andXs:(NSArray *)xs
                  andYs:(NSArray *)ys
                andType:(NSString *)type
{
    NSLog(@"Annotation drawn called!");
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    [message setValue:page forKey:@"page"];
    [message setValue:self.broadcaster.connectionId forKey:@"id"];
    [message setValue:xs forKey:@"x"];
    [message setValue:ys forKey:@"y"];
    [message setValue:type forKey:@"type"];
    
    if ([toolColor isEqual:[UIColor blackColor]])
    {
        [message setValue:[NSNumber numberWithInt:0] forKey:@"color"];
    }
    else if ([toolColor isEqual:[UIColor redColor]])
    {
        [message setValue:[NSNumber numberWithInt:1] forKey:@"color"];
    }
    else if ([toolColor isEqual:[UIColor blueColor]])
    {
        [message setValue:[NSNumber numberWithInt:2] forKey:@"color"];
    }
    else if ([toolColor isEqual:[UIColor yellowColor]])
    {
        [message setValue:[NSNumber numberWithInt:3] forKey:@"color"];
    }
    else if ([toolColor isEqual:[UIColor greenColor]])
    {
        [message setValue:[NSNumber numberWithInt:4] forKey:@"color"];
    }
    
    if (toolSize.intValue <= 5 && toolAlpha.floatValue == 1.0)
    {
        [message setValue:[NSNumber numberWithInt:1] forKey:@"brush"];
    }
    else if (toolSize.intValue > 5 && toolSize.intValue < 15 && toolAlpha.floatValue == 1.0)
    {
        [message setValue:[NSNumber numberWithInt:2] forKey:@"brush"];
    }
    else if (toolSize.intValue >= 15 && toolAlpha.floatValue == 1.0)
    {
        [message setValue:[NSNumber numberWithInt:3] forKey:@"brush"];
    }
    else if (toolSize.intValue <= 5 && toolAlpha.floatValue == 0.25)
    {
        [message setValue:[NSNumber numberWithInt:4] forKey:@"brush"];
    }
    else if (toolSize.intValue > 5 && toolSize.intValue < 15 && toolAlpha.floatValue == 0.25)
    {
        [message setValue:[NSNumber numberWithInt:4] forKey:@"brush"];
    }
    else if (toolSize.intValue >= 15 && toolAlpha.floatValue == 0.25)
    {
        [message setValue:[NSNumber numberWithInt:5] forKey:@"brush"];
    }
    else
    {
        [message setValue:[NSNumber numberWithInt:0] forKey:@"brush"];
    }
    
    NSLog(@"Message in AnnotationViewController: %@", message);
    dispatch_async(annotationBroadcasterQueue,
    ^{
        if (self.broadcaster.connectionId)
        {
            [self.broadcaster broadcastMessage:message];
            while (!self.broadcaster.messageSent)
            {
                NSLog(@"Keeping broadcast thread alive!");
                [NSThread sleepForTimeInterval:1];
            }
        }
    });    
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.broadcaster = [[AnnotationServerBroadcaster alloc] init];
    self.broadcaster.session = self.session;
    self.broadcaster.username = self.username;
    NSLog(@"Going to join session %@ with username %@", self.session, self.username);
    
    dispatch_queue_t annotationListenerQueue = dispatch_queue_create("annotationListenerQueue", NULL);
    dispatch_async(annotationListenerQueue,
    ^{
        AnnotationServerListener *listener = [[AnnotationServerListener alloc] init];
        listener.delegate = self;
        [listener joinSession:self.session withUsername:self.username];
        while (YES) {
            NSLog(@"Keeping annotation listener thread alive!");
            [NSThread sleepForTimeInterval:60];
        }
    });
    dispatch_release(annotationListenerQueue);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    annotationBroadcasterQueue = dispatch_queue_create("annotationBroadcasterQueue", NULL);
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    dispatch_release(annotationBroadcasterQueue);
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)toolBarButtonPressed:(UIBarButtonItem *)sender {
}
@end
