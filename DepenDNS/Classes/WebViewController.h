//
//  WebViewController.h
//  WebViewTutorial
//
//  Created by iPhone SDK Articles on 8/19/08.
//  Copyright 2008 www.iPhoneSDKArticles.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MatchAlgo;

@interface WebViewController : UIViewController <UITextFieldDelegate, UIAccelerometerDelegate, UIAlertViewDelegate>{
	
	IBOutlet UIWebView *webView;
	UIToolbar	*toolBar;
	UITextField *urlField;
	UIActivityIndicatorView *activityIndicator;
	MatchAlgo *DepenDNSEngine;
	
	BOOL hasRunDepenDNS;
	NSString* connectedIP;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UIToolbar *toolBar;
@property (nonatomic, retain) NSString *connectedIP;

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;

@end
