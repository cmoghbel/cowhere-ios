//
//  JoinSessionViewController.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JoinSessionViewController.h"
#import "AnnotationViewController.h"
#import "AnnotationServerListener.h"
#import "SBJson.h"

@interface JoinSessionViewController ()

@property NSString *session;
@property NSString *username;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL fileDownloaded;
@property (nonatomic, strong) NSMutableData *fileData;
@property (nonatomic) long expectedContentLength;
@property (nonatomic) BOOL receivedFileURL;
@property (nonatomic, strong) NSString *fileURL;
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation JoinSessionViewController

@synthesize sessionCodeTextField;
@synthesize usernameTextField;
@synthesize session = _session;
@synthesize username = _username;
@synthesize progressLabel = _progressLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize fileDownloaded = _fileDownloaded;
@synthesize fileData = _fileData;
@synthesize expectedContentLength = _expectedContentLength;
@synthesize receivedFileURL = _receivedFileURL;
@synthesize fileURL = _fileURL;
@synthesize connection = _connection;

- (NSMutableData *)fileData
{
    if (!_fileData) _fileData = [[NSMutableData alloc] init];
    return _fileData;
}

// TODO: Make grabbing all the information more robust.
- (IBAction)sessionTextFieldEditingEnded:(UITextField *)sender
{
    self.session = sender.text;
}

- (IBAction)sessionTextFieldEditingChanged:(UITextField *)sender
{
    self.session = sender.text;
}

- (IBAction)usernameTextFieldEditingEnded:(UITextField *)sender
{
    self.username = sender.text;
}

- (IBAction)usernameTextFieldEditingChanged:(UITextField *)sender
{
    self.username = sender.text;
}

- (void)startConnection
{
    [self.connection start];
}

- (IBAction)joinButtonPressed:(UIButton *)sender
{
    NSString *getFileURLString = [NSString stringWithFormat:@"http://184.169.151.213:80/f/?s=%@", self.session];
    getFileURLString = [getFileURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *getFileURL = [[NSURL alloc] initWithString:getFileURLString];
    NSMutableURLRequest *getFileURLRequest = [[NSMutableURLRequest alloc] initWithURL:getFileURL];
    [getFileURLRequest setHTTPMethod:@"GET"];
    [getFileURLRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [getFileURLRequest setTimeoutInterval:10000000];

    NSError *errorReturned = nil;
    NSURLResponse *theResponse =[[NSURLResponse alloc] init];
    NSData *data = [NSURLConnection sendSynchronousRequest:getFileURLRequest returningResponse:&theResponse error:&errorReturned];
    
    NSDictionary *json = [data JSONValue];
    self.fileURL = [json objectForKey:@"Ok"];
    NSLog(@"FileURL: %@", self.fileURL);
    self.receivedFileURL = YES;
    
    self.progressLabel.hidden = NO;
    [self.activityIndicator startAnimating];
    [self.view setNeedsDisplay];
    
    dispatch_queue_t createSessionQueue = dispatch_queue_create("createSessionQueue", NULL);
    dispatch_async(createSessionQueue,
    ^{
        NSString *fileDownloadString = [self.fileURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURL *fileDownloadURL = [[NSURL alloc] initWithString:fileDownloadString];
        NSData *data = [[NSData alloc] initWithContentsOfURL:fileDownloadURL];
        
        NSLog(@"Succeeded! Received %d bytes of data", [data length]);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);    
        NSString *documentsDirectory = [paths objectAtIndex:0];	
        NSString *pdfPath = [documentsDirectory stringByAppendingPathComponent:@"temp.pdf"];
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if ([fileManager fileExistsAtPath:pdfPath])
        {
            NSError *error = [[NSError alloc] init];
            [fileManager removeItemAtPath:pdfPath error:&error];
            NSLog(@"Removed old temp file!");
        }
        // Give a brief sleep in order to make sure I/O completes.
        [NSThread sleepForTimeInterval:0.5];
        [data writeToFile:pdfPath atomically:YES];
        NSLog(@"Wrote temp file to disk!");
        
        self.fileDownloaded = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.progressLabel.hidden = YES;
            [self.view setNeedsDisplay];
            [self performSegueWithIdentifier:@"joinSession" sender:self];
        });
    });
    dispatch_release(createSessionQueue);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Going to join session %@ with username %@", self.session, self.username);
    
    NSLog(@"Time to segue!");
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setSessionCodeTextField:nil];
    [self setUsernameTextField:nil];
    [self setProgressLabel:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
