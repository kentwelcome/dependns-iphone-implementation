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
@synthesize DomainRegister;
@synthesize urlField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
		DepenDNSEngine = [[MatchAlgo alloc]init];
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
	// init the domain register. use for cache the ip with the same domain 
	self.DomainRegister = [NSString stringWithFormat:@""];
	
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
	if ([self CheckPlistValues] == false){ 
		[self ShowLoginDialog];
	}

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
	[self.webView loadRequest:requestObj];
	NSLog(@"%@\n",[self.webView request]);
	
	
	pos = [domain rangeOfString: @"/"].location;
	if(pos==NSNotFound){
		NSLog(@"Domain: %@\n", domain);
		self.DomainRegister = [NSString stringWithFormat:@"%@",domain];
	} else {
		NSLog(@"Domain: %@\n", [domain substringToIndex: pos]);
		self.DomainRegister = [NSString stringWithFormat:@"%@",[domain substringToIndex: pos]];
	}
	
	
	// Get IP address of this Domain
	const char* domaincString = [domain cStringUsingEncoding:NSASCIIStringEncoding];
	struct hostent *host_entry;
	host_entry=gethostbyname(domaincString);
	if ( host_entry == NULL ) {
		return;
	}
	char* ipaddr = inet_ntoa (*(struct in_addr *)*host_entry->h_addr_list);
	self.connectedIP = [NSString stringWithFormat:@"%s",ipaddr ];
	//NSLog(@"hit\n");
	NSLog(@"My IP is %@.", self.connectedIP);
	// change the method use php server to do match algorithm
	
	[DepenDNSEngine RunMatchAlgo: domain GetUser: userid.text GetPass: pass.text ];
	
	hasRunDepenDNS = YES;
	
}

- (void) RunDepenDNS: (UITextField*) textField
{
	NSLog(@"Run DepenDNS");
	hasRunDepenDNS = NO;
	NSString* domain;
	NSString* urlAddress = textField.text;
	
	// extract the domain name from url
	int pos = [urlAddress rangeOfString: @"http://"].location;
	if ( pos == NSNotFound ){
		domain = urlAddress;
		urlAddress = [NSString stringWithFormat: @"http://%@",urlAddress];
	} else {
		domain = [urlAddress substringFromIndex: pos+7]; 
	}
	
	pos = [domain rangeOfString: @"/"].location;
	if(pos==NSNotFound){
		NSLog(@"Domain: %@\n", domain);
	} else {
		NSLog(@"Domain: %@\n", [domain substringToIndex: pos]);
		domain = [NSString stringWithFormat:@"%@",[domain substringToIndex: pos]];
	}
	NSLog(@"Register: %@\n",self.DomainRegister);
	if ( [domain isEqualToString: self.DomainRegister] == NO ){ // difference domain
		
		// Get IP address of this Domains
		NSLog(@"Get IP\n");
		const char* domaincString = [domain cStringUsingEncoding:NSASCIIStringEncoding];
		struct hostent *host_entry;
		host_entry=gethostbyname(domaincString);
		if ( host_entry == NULL ) {
			goto end;
		}
		char* ipaddr = inet_ntoa (*(struct in_addr *)*host_entry->h_addr_list);
		self.connectedIP = [NSString stringWithFormat:@"%s",ipaddr ];
		
		NSLog(@"My IP is %@.", self.connectedIP);
		
		NSLog(@"Run %@\n",domain);
		[DepenDNSEngine RunMatchAlgo: domain GetUser: UID GetPass: PWD ];
	} else {
		NSLog(@"Same domain\n");
	}
	
	
end:
	if(pos==NSNotFound){
		self.DomainRegister = [NSString stringWithFormat:@"%@",domain];
	} else {
		self.DomainRegister = [NSString stringWithFormat:@"%@",[domain substringToIndex: pos]];
	}
	
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
	NSLog(@"Load complete URL = %@.", [[[self.webView request] URL] absoluteString]);
	[activityIndicator stopAnimating];
	// Change URL TextField Value
	urlField.text = [[[self.webView request] URL] absoluteString];
	[self RunDepenDNS:urlField];
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

- (BOOL) CheckPlistValues 
{
	//Get the Plist values	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *UserName = [defaults objectForKey:@"name_preference"];
	NSString *Password = [defaults objectForKey:@"password_preference"];
	NSLog(@"User:\t%@\n",UserName);
	NSLog(@"Passwd:\t%@\n",Password);

	int result = [DepenDNSEngine RunMatchAlgo:@"moon.cs.nthu.edu.tw" GetUser:UserName GetPass:Password];
	if (result < 0){
		return false;
	} else {
		NSLog(@"login ok\n");
		UID = [NSString stringWithString:UserName];
		PWD = [NSString stringWithString:Password];
		
		return true;
	}

}

- (void) ShowLoginDialog
{

	UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"Enter Login Information"
													 message:@"\n\n\n\n" // IMPORTANT
													delegate:self
										   cancelButtonTitle:@"Register"
										   otherButtonTitles:@"Login", nil];
	
	
	userid = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 50.0, 260.0, 25.0)];
	[userid setBackgroundColor:[UIColor whiteColor]];
	[userid setPlaceholder:@"User Name"];
	userid.clearButtonMode = UITextFieldViewModeWhileEditing;
	userid.keyboardType = UIKeyboardTypeDefault;
	userid.keyboardAppearance = UIKeyboardAppearanceAlert;
	userid.autocorrectionType = UITextAutocorrectionTypeNo;
	userid.secureTextEntry = NO;
	[prompt addSubview:userid];
	
	pass = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 85.0, 260.0, 25.0)];
	[pass setBackgroundColor:[UIColor whiteColor]];
	[pass setPlaceholder:@"Password"];
	[pass setSecureTextEntry:YES];
	pass.clearButtonMode = UITextFieldViewModeWhileEditing;
	pass.keyboardType = UIKeyboardTypeDefault;
	pass.keyboardAppearance = UIKeyboardAppearanceAlert;
	pass.autocorrectionType = UITextAutocorrectionTypeNo;
	[prompt addSubview:pass];
	
	// set place
	[prompt setTransform:CGAffineTransformMakeTranslation(0.0, 0.0)];
	[prompt show];
    [prompt release];
	
	// set cursor and show keyboard
	[userid becomeFirstResponder];
	
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
	
	if (index == 1)	// button Login
	{
		//NSLog(@"button 1\n");
	} else if (index == 0) { // button Register
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://moon.cs.nthu.edu.tw/~kent/DepenDNS"]];
		//NSLog(@"button2\n");
	}
	// ... repeat for each button that you need to do something with
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

// Read the connect url and open it with Safari
- (IBAction) OpenInSafari: (id)sender
{
	NSLog(@"Open %@ in Safari.\n",urlField.text);
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlField.text]];
	
}

#ifdef LOCATE_INFO
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
#endif

- (void)dealloc {
	[reverseGeocoder release];
	//[locationController release];		// remove location function 
	[DepenDNSEngine release];
	[activityIndicator release];
	[urlField release];
	[toolBar release];
	[super dealloc];
}


@end
