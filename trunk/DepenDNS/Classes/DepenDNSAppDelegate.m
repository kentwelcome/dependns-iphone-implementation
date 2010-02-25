//
//  DepenDNSAppDelegate.m
//  DepenDNS
//
//  Created by Mac on 2010/2/12.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "DepenDNSAppDelegate.h"
#import "RootViewController.h"
#import "WebViewController.h"
#import "Reachability.h"

@implementation DepenDNSAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize MyWebView;

#pragma mark -
#pragma mark Application lifecycle

/*
- (id)init
{
	if(self = [super init])
	{
		asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
	}
	return self;
}
*/

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch
	
	// Check Reachability
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:)
												 name: kReachabilityChangedNotification object: nil];
	
	hostReach = [[Reachability reachabilityWithHostName: @"www.apple.com"] retain];
	[hostReach startNotifer];
	
	// [window addSubview:[navigationController view]];
	MyWebView = [[WebViewController alloc] initWithNibName:@"WebView" bundle:[NSBundle mainBundle]];
	[window addSubview:[MyWebView view]];
    [window makeKeyAndVisible];
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
	NetworkStatus netStatus = [curReach currentReachabilityStatus];
	// BOOL connectionRequired= [curReach connectionRequired];
	
	if(netStatus != ReachableViaWiFi) {
		NSLog(@"NotReachable In WiFi.");
		NSString* msg = @"Open WiFi Interface To Connect Network!";
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message: msg 
			delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
	/*
	NSString* baseLabel=  @"";
	NSString* interface=  @"";
	if(!connectionRequired) {
		baseLabel=  
		NSLog(baseLabel);
		else if(netStatus != ReachableViaWWAN) {
			NSLog(@"NotReachable In Cellular Network.");
			interface = [interface stringByAppendingFormat:@"And 3G "];
		}
	}
	*/
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[MyWebView release];
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

