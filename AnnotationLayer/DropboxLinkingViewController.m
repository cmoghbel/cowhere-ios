//
//  DropboxLinkingViewController.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DropboxLinkingViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface DropboxLinkingViewController ()

@end

@implementation DropboxLinkingViewController

@synthesize createButton;

- (IBAction)didPressLink
{
    NSLog(@"Here!");
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] link];
    }
    [self updateButtons];
    [self.view setNeedsDisplay];
}

- (void)updateButtons {
    NSString* title = [[DBSession sharedSession] isLinked] ? @"Create New Session" : @"Link Dropbox";
    [self.createButton setTitle:title forState:UIControlStateNormal];
    
//    self.navigationItem.rightBarButtonItem.enabled = [[DBSession sharedSession] isLinked];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[DBSession sharedSession] unlinkAll];
    [self updateButtons];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setCreateButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
