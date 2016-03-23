//
//  SessionCreatedViewController.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SessionCreatedViewController.h"
#import "AnnotationViewController.h"

@interface SessionCreatedViewController ()

@property (weak, nonatomic) IBOutlet UILabel *sessionLabel;

@end

@implementation SessionCreatedViewController

@synthesize sessionLabel;
@synthesize session = _session;
@synthesize username = _username;

- (void)setSession:(NSString *)session
{
    NSLog(@"Setting session to: %@", session);
    _session = session;
    self.sessionLabel.text = session;
    [self.view setNeedsDisplay];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AnnotationViewController *destination = segue.destinationViewController;
    destination.session = self.session;
    destination.username = self.username;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.sessionLabel.text = self.session;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setSessionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
