//
//  WebViewController.h
//  WebViewTutorial
//
//  Created by iPhone SDK Articles on 8/19/08.
//  Copyright 2008 www.iPhoneSDKArticles.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyCLController.h"

@class MatchAlgo;

@interface WebViewController : UIViewController <UITextFieldDelegate, UIAccelerometerDelegate, UIAlertViewDelegate, MyCLControllerDelegate>{
	
	IBOutlet UIWebView *webView;
	UIToolbar	*toolBar;
	UITextField *urlField;
	UITextField *userid;
	UITextField *pass;
	UIActivityIndicatorView *activityIndicator;
	MatchAlgo *DepenDNSEngine;
	
	BOOL hasRunDepenDNS;
	NSString* connectedIP;
	MyCLController *locationController;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UIToolbar* toolBar;
@property (nonatomic, retain) NSString* connectedIP;

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
- (void) ShowLoginDialog;
- (void) GetGeoLocation;

// Delegate for MyCLControllerDelegate
- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;

@end
