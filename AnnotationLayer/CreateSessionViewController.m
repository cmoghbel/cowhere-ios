//
//  CreateSessionViewController.m
//  AnnotationLayer
//
//  Created by Chris Moghbel on 4/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateSessionViewController.h"
#import "SessionCreatedViewController.h"
#import "SBJson.h"

@interface CreateSessionViewController ()

//@property NSString *url;
//@property NSString *username;

@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic) BOOL sessionCreated;
@property (nonatomic, strong) NSString *session;
@property (nonatomic, weak) SessionCreatedViewController *destination;
@property (nonatomic) BOOL fileDownloaded;
@property (nonatomic, strong) NSMutableData *fileData;
@property (nonatomic) long expectedContentLength;

@end

@implementation CreateSessionViewController

@synthesize urlTextField = _urlTextField;
@synthesize usernameTextField = _usernameTextField;
@synthesize progressLabel = _progressLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize sessionCreated = _sessionCreated;
@synthesize session = _session;
@synthesize destination = _destination;
@synthesize fileDownloaded = _fileDownloaded;
@synthesize fileData = _fileData;
@synthesize expectedContentLength = _expectedContentLength;

- (NSMutableData *)fileData
{
    if (!_fileData) _fileData = [[NSMutableData alloc] init];
    return _fileData;
}

- (NSString *)session
{
    if (!_session) _session = @"ERROR";
    return _session;
}

- (IBAction)createButtonPressed:(UIButton *)sender
{
    NSString *createString = [NSString stringWithFormat:@"http://184.169.151.213/c/?fileurl=%@", self.urlTextField.text];
    createString = [createString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *createURL = [[NSURL alloc] initWithString:createString];
    NSMutableURLRequest *createRequest = [[NSMutableURLRequest alloc] initWithURL:createURL];
    [createRequest setHTTPMethod:@"GET"];
    [createRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [createRequest setTimeoutInterval:60];
    
    NSLog(@"Trying to create session string: %@", createString);
    NSLog(@"Trying to create session url: %@", createURL);
    NSError *errorReturned = nil;
    NSURLResponse *theResponse =[[NSURLResponse alloc] init];
    NSData *data = [NSURLConnection sendSynchronousRequest:createRequest returningResponse:&theResponse error:&errorReturned];

    NSLog(@"Create did receive data: %@", data);
    NSLog(@"...with message: %@", [data JSONValue]);
    self.session = [[[data JSONValue] objectForKey:@"Ok"] objectForKey:@"session_id"];
    self.destination.session = [self.session copy];
    self.sessionCreated = YES;
    
    self.progressLabel.hidden = NO;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    [self.view setNeedsDisplay];
    NSLog(@"Here!");
    
    dispatch_queue_t createSessionQueue = dispatch_queue_create("createSessionQueue", NULL);
    dispatch_async(createSessionQueue, 
    ^{
                       
        NSString *fileDownloadString = [self.urlTextField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

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
            [self performSegueWithIdentifier:@"createSession" sender:self];
        });    
    });
    dispatch_release(createSessionQueue);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Time to segue!");
    self.destination = segue.destinationViewController;
    self.destination.username = self.usernameTextField.text;
       
    self.destination.session = [self.session copy];
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
    [self setUrlTextField:nil];
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
