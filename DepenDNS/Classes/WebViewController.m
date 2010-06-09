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
#include "ASIAuthenticationDialog.h"


@implementation WebViewController

@synthesize webView;
@synthesize toolBar;
@synthesize connectedIP;
@synthesize reverseGeocoder;

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
	//UIBarButtonItem *LoadButton = [[UIBarButtonItem alloc] 
	//								 initWithTitle:@"Go" style:UIBarButtonItemStyleBordered 
	//								 target:self action:@selector(LoadURL:)];
	
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
	
	UIBarButtonItem *LoginButton = [[UIBarButtonItem alloc] 
									initWithTitle:@"Login" style:UIBarButtonItemStyleBordered 
									target:self action:@selector(ShowLoginDialog)];
	
	
	UIBarButtonItem *textFieldItem = [[UIBarButtonItem alloc] initWithCustomView:urlField];
	
	CGRect mainBounds = [[UIScreen mainScreen] bounds];
	CGRect indicatorBounds = CGRectMake(mainBounds.size.width / 2 - 12,
										mainBounds.size.height / 2 - 12, 24, 24);
	activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:indicatorBounds];
	
	activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	
	UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator]; 
	
	
    //NSArray *topBarItems = [NSArray arrayWithObjects: LoadButton, textFieldItem, LoginButton, activityItem, nil];	
    NSArray *topBarItems = [NSArray arrayWithObjects: textFieldItem, LoginButton, activityItem, nil];	
    
	[self.toolBar setItems:topBarItems animated:NO];
	
	// [self ShowLoginDialog];
	// [self GetGeoLocation];
	
	// Get Geo Location Info	
	locationController = [[MyCLController alloc] init];
    locationController.delegate = self;
    [locationController.locationManager startUpdatingLocation];
	
	hasRunDepenDNS = NO;
}

- (void) GetGeoLocation
{
	NSLog(@"Get GeoLocation.");
	
}

- (void) textFieldDidBeginEditing:(UITextField*) textField
{
	NSLog(@"BeginEdit");
	urlField.textColor = [UIColor blackColor];
}

- (void) textFieldDidEndEditing:(UITextField*) textField
{
	NSLog(@"EndEdit");
	hasRunDepenDNS = NO;
	self.connectedIP = @"";
	NSString* domain;
	urlField.textColor = [UIColor blackColor];
	NSString *urlAddress = urlField.text;
	NSLog(@"goto URL:%@.", urlAddress);
	
	// Run DepenDNS
	int pos = [urlAddress rangeOfString: @"http://"].location;
	if ( pos == NSNotFound ){
		domain = urlAddress;
		urlAddress = [NSString stringWithFormat: @"http://%@",urlAddress];
	} else {
		domain = [urlAddress substringFromIndex: pos+7]; 
	}
	
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	//Load the request in the UIWebView.
	[webView loadRequest:requestObj];
	NSLog(@"%@\n",urlAddress);
	
	
	pos = [domain rangeOfString: @"/"].location;
	if(pos==NSNotFound)
		NSLog(@"Domain: %@", domain);
	else
		NSLog(@"Domain: %@", [domain substringToIndex: pos]);
	
	// Get IP address of this Domain
	const char* domaincString = [domain cStringUsingEncoding:NSASCIIStringEncoding];
	struct hostent *host_entry;
	host_entry=gethostbyname(domaincString);
	char* ipaddr = inet_ntoa (*(struct in_addr *)*host_entry->h_addr_list);
	
	self.connectedIP = [NSString initWithCString:ipaddr length:strlen(ipaddr)];
	
	NSLog(@"My IP is %@.", self.connectedIP);
	// change the method use php server to do match algorithm
	
	[DepenDNSEngine RunMatchAlgo: domain GetUser: userid.text GetPass: pass.text ];
	
	hasRunDepenDNS = YES;
	
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
			int res = [DepenDNSEngine checkTrustWorthy:self.connectedIP];
			NSLog(@"res = %d.", res);
			
			if(res==0) {
				NSLog(@"Safe!");
				urlField.textColor = [UIColor blueColor];
			}
			if(res==1) {
				NSLog(@"Might be suffer pharming!");
				urlField.textColor = [UIColor redColor];
			}
			if(res==-1) {
				NSLog(@"DNS Query Failed! Press Detect Again!");
				urlField.textColor = [UIColor orangeColor];
			}
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
	NSString* domain;
	urlField.textColor = [UIColor blackColor];
	NSString *urlAddress = urlField.text;
	NSLog(@"goto URL:%@.", urlAddress);
	
	// Run DepenDNS
	int pos = [urlAddress rangeOfString: @"http://"].location;
	if ( pos == NSNotFound ){
		domain = urlAddress;
		urlAddress = [NSString stringWithFormat: @"http://%@",urlAddress];
	} else {
		domain = [urlAddress substringFromIndex: pos+7]; 
	}

	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	//Load the request in the UIWebView.
	[webView loadRequest:requestObj];
	NSLog(@"%@\n",urlAddress);
	
	
	pos = [domain rangeOfString: @"/"].location;
	if(pos==NSNotFound)
		NSLog(@"Domain: %@", domain);
	else
		NSLog(@"Domain: %@", [domain substringToIndex: pos]);
	
	// Get IP address of this Domain
	const char* domaincString = [domain cStringUsingEncoding:NSASCIIStringEncoding];
	struct hostent *host_entry;
	host_entry=gethostbyname(domaincString);
	char* ipaddr = inet_ntoa (*(struct in_addr *)*host_entry->h_addr_list);
	self.connectedIP = [NSString initWithCString:ipaddr length:strlen(ipaddr)];
	NSLog(@"My IP is %@.", self.connectedIP);
	// change the method use php server to do match algorithm
	
	//NSLog(@"userid: %@\n",userid.text);
	
	[DepenDNSEngine RunMatchAlgo: domain GetUser: userid.text GetPass: pass.text ];
	
	/*NSURL *ask_url = [NSURL URLWithString:@"http://is10.cs.nthu.edu.tw/~kent/test.php?question=www.google.com"];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:ask_url];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [request responseString];
		NSLog(@"%@",response);
		hasRunDepenDNS = YES;
	}*/
	hasRunDepenDNS = YES;
	
	
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	NSLog(@"webViewDidStartLoad");
	// Change URL TextField Value
	NSLog(@"Loading URL = %@.", [[[self.webView request] URL] absoluteString]);
	// urlField.text = [[[self.webView request] URL] absoluteString];
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

- (void) ShowLoginDialog
{

	UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"Enter Login Information"
													 message:@"\n\n\n" // IMPORTANT
													delegate:self
										   cancelButtonTitle:@"Cancel"
										   otherButtonTitles:@"Login", nil];
	
	userid = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 50.0, 260.0, 25.0)];
	[userid setBackgroundColor:[UIColor whiteColor]];
	[userid setPlaceholder:@"username"];
	[prompt addSubview:userid];
	
	pass = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 85.0, 260.0, 25.0)];
	[pass setBackgroundColor:[UIColor whiteColor]];
	[pass setPlaceholder:@"password"];
	[pass setSecureTextEntry:YES];
	[prompt addSubview:pass];
	
	// set place
	[prompt setTransform:CGAffineTransformMakeTranslation(0.0, 110.0)];
	[prompt show];
    [prompt release];
	
	// set cursor and show keyboard
	[userid becomeFirstResponder];
	
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; 
	// Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)locationUpdate:(CLLocation *)location {
    NSLog(@"%@", [location description]);
	NSLog(@"Accuracy: %f.", [location verticalAccuracy]);
	NSLog(@"Current latitude %f",location.coordinate.latitude);
	NSLog(@"Current longitude %f",location.coordinate.longitude);
	
	self.reverseGeocoder =
	[[[MKReverseGeocoder alloc] initWithCoordinate:location.coordinate] autorelease];
    reverseGeocoder.delegate = self;
    [reverseGeocoder start];
	// NSLog(@"latitude: %@", location.coordinate.latitude);
	// NSLog(@"longitude: %@", location.coordinate.longitude);
}

- (void)locationError:(NSError *)error {
    NSLog(@"%@", [error description]);
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
    NSLog(@"MKReverseGeocoder has failed.");
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    //PlacemarkViewController *placemarkViewController =
	//[[PlacemarkViewController alloc] initWithNibName:@"PlacemarkViewController" bundle:nil];
    //placemarkViewController.placemark = placemark;
    //[self presentModalViewController:placemarkViewController animated:YES];
	NSString* local = @"";
	NSLog(@"Thoroughfare: %@", placemark.thoroughfare);
	if(placemark.thoroughfare != nil)
		local = [local stringByAppendingString:placemark.thoroughfare];
	NSLog(@"Sub-thoroughfare: %@", placemark.subThoroughfare);
	if(placemark.subThoroughfare != nil)
		local = [local stringByAppendingString:placemark.subThoroughfare];
	NSLog(@"Locality: %@", placemark.locality);
	if(placemark.locality != nil)
		local = [local stringByAppendingString:placemark.locality];
	NSLog(@"Sub-locality: %@", placemark.subLocality);
	if(placemark.subLocality != nil)
		local = [local stringByAppendingString:placemark.subLocality];
	NSLog(@"Administrative Area: %@", placemark.administrativeArea);
	if(placemark.administrativeArea != nil)
		local = [local stringByAppendingString:placemark.administrativeArea];
	NSLog(@"Sub-administrative Area: %@", placemark.subAdministrativeArea);
	if(placemark.subAdministrativeArea != nil)
		local = [local stringByAppendingString:placemark.subAdministrativeArea];
	NSLog(@"Postal Code: %@", placemark.postalCode);
	if(placemark.postalCode != nil)
		local = [local stringByAppendingString:placemark.postalCode];
	NSLog(@"Country: %@", placemark.country);
	if(placemark.country != nil)
		local = [local stringByAppendingString:placemark.country];
	NSLog(@"Country Code: %@", placemark.countryCode);
	if(placemark.countryCode != nil)
		local = [local stringByAppendingString:placemark.countryCode];
	
	UIAlertView *infoAlert = [[UIAlertView alloc] initWithTitle:@"Location Information"
													 message:local // IMPORTANT
													delegate:nil
										   cancelButtonTitle:nil
										   otherButtonTitles:@"OK", nil];
	// set place
	[infoAlert setTransform:CGAffineTransformMakeTranslation(0.0, 110.0)];
	[infoAlert show];
    [infoAlert release];
}


- (void)dealloc {
	[reverseGeocoder release];
	[locationController release];	
	[DepenDNSEngine release];
	[activityIndicator release];
	[urlField release];
	[toolBar release];
	[super dealloc];
}


@end
