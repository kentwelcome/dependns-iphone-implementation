//
//  DepenDNSAppDelegate.h
//  DepenDNS
//
//  Created by Mac on 2010/2/12.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

@class Reachability;
@class WebViewController;

@interface DepenDNSAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
	WebViewController *MyWebView;
	Reachability *hostReach;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet WebViewController *MyWebView;

- (void) reachabilityChanged: (NSNotification* )note;
- (void) updateInterfaceWithReachability: (Reachability*) curReach;

@end

