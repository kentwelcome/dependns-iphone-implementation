//
//  WebViewController.m
//  WebViewTutorial
//
//  Created by iPhone SDK Articles on 8/19/08.
//  Copyright 2008 www.iPhoneSDKArticles.com. All rights reserved.
//

#import "WebViewController.h"
#import "MatchAlgo.h"
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation WebViewController

@synthesize webView;
@synthesize toolBar;
@synthesize connectedIP;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		DepenDNSEngine = [[MatchAlgo alloc]init];
		// [DepenDNSEngine RunMatchAlgo: @"www.nthu.edu.tw"];
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad. */
- (void)viewDidLoad {
	
	// Put UIAccelerometer here for detect shaking
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 40)];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
	// TabBar
	self.toolBar = [UIToolbar new];
	self.toolBar.barStyle = UIBarStyleDefault;
	
	// size up the toolbar and set its frame
	[self.toolBar sizeToFit];
	CGFloat toolbarHeight = [self.toolBar frame].size.height;
	CGRect mainViewBounds = self.view.bounds;
	[self.toolBar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
									  // CGRectGetMaxY(mainViewBounds) - CGRectGetHeight(mainViewBounds) + (toolbarHeight * 2.0) + 45.0,
									  CGRectGetMaxY(mainViewBounds) - CGRectGetHeight(mainViewBounds) + toolbarHeight - 25.0,
									  CGRectGetWidth(mainViewBounds),
									  toolbarHeight)];
	
	[self.view addSubview:self.toolBar];
	
	// Set Functional Buttons
	UIBarButtonItem *LoadButton = [[UIBarButtonItem alloc] 
									 initWithTitle:@"Detect" style:UIBarButtonItemStyleBordered 
									 target:self action:@selector(LoadURL:)];
	
	CGRect frame = CGRectMake(0, 0, 200, (toolbarHeight-20.0));
    urlField = [[UITextField alloc] initWithFrame:frame];
    
    urlField.borderStyle = UITextBorderStyleRoundedRect;
    urlField.textColor = [UIColor blackColor];
	urlField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
	urlField.keyboardType = UIKeyboardTypeDefault;
	urlField.returnKeyType = UIReturnKeyDone;
	urlField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	urlField.text = @"http://";
	[urlField setDelegate: self];
	
	UIBarButtonItem *textFieldItem = [[UIBarButtonItem alloc] initWithCustomView:urlField];
	
	CGRect mainBounds = [[UIScreen mainScreen] bounds];
	CGRect indicatorBounds = CGRectMake(mainBounds.size.width / 2 - 12,
										mainBounds.size.height / 2 - 12, 24, 24);
	activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:indicatorBounds];
	
	activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	
	UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator]; 
	
    NSArray *topBarItems = [NSArray arrayWithObjects: LoadButton, textFieldItem, activityItem, nil];	
    [self.toolBar setItems:topBarItems animated:NO];
	
	hasRunDepenDNS = NO;
}

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	const float violence = 1.5;
	static BOOL beenhere;
	BOOL shake = FALSE;
	
	if (beenhere) return;
	beenhere = TRUE;
	if (acceleration.x > violence * 1.5 || acceleration.x < (-1.5* violence))
		shake = TRUE;
	if (acceleration.y > violence * 2 || acceleration.y < (-2 * violence))
		shake = TRUE;
	if (acceleration.z > violence * 3 || acceleration.z < (-3 * violence))
		shake = TRUE;
	
	if (shake) {
		NSLog(@"Detect Shaking!");
		
		if(hasRunDepenDNS) {
			NSString* msg = @""; 
			
			int res = [DepenDNSEngine checkTrustWorthy:self.connectedIP];
			NSLog(@"res = %d.", res);
			
			if(res==0) {
				NSLog(@"Safe!");
				msg = @"Current is Safe!";
			}
			if(res==1) {
				NSLog(@"Might be suffer pharming!");
				msg = @"Might be suffer pharming!";
			}
			if(res==-1) {
				NSLog(@"DNS Query Failed! Press Detect Again!");
				msg = @"DNS Query Failed! Press Detect Again!";
			}
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message: msg 
				delegate:webView cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
		
	} 
	beenhere = FALSE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[urlField resignFirstResponder];
	return YES;
}

- (void) LoadURL:(id)sender {
	
	hasRunDepenDNS = NO;
	self.connectedIP = @"";
	
	NSString *urlAddress = urlField.text;
	//urlAddress = [urlAddress stringByAppendingString:urlField.text];
	NSLog(@"goto URL:%@.", urlAddress);
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	//Load the request in the UIWebView.
	[webView loadRequest:requestObj];
	
	// Run DepenDNS
	int pos = [urlAddress rangeOfString: @"//"].location;
	NSString* domain = [urlAddress substringFromIndex: pos+2];
	NSLog(@"Domain: %@", domain);
	
	// Get IP address of this Domain
	const char* domaincString = [domain cStringUsingEncoding:NSASCIIStringEncoding];
	struct hostent *host_entry;
	host_entry=gethostbyname(domaincString);
	char* ipaddr = inet_ntoa (*(struct in_addr *)*host_entry->h_addr_list);
	self.connectedIP = [NSString stringWithCString:ipaddr length:strlen(ipaddr)];
	NSLog(@"My IP is %@.", self.connectedIP);
	
	[DepenDNSEngine RunMatchAlgo: domain];
	hasRunDepenDNS = YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	NSLog(@"webViewDidStartLoad");
	[activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	NSLog(@"webViewDidFinishLoad");
	[activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	NSLog(@"didFailLoadWithError");
	// report the error inside the webview
	NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
							 error.localizedDescription];
	[self.webView loadHTMLString:errorString baseURL:nil];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[DepenDNSEngine release];
	[activityIndicator release];
	[urlField release];
	[toolBar release];
	[super dealloc];
}


@end
