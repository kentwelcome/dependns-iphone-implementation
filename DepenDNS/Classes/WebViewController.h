//
//  WebViewController.h
//  WebViewTutorial
//
//  Created by iPhone SDK Articles on 8/19/08.
//  Copyright 2008 www.iPhoneSDKArticles.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MyCLController.h"

@class MatchAlgo;

@interface WebViewController : UIViewController <UITextFieldDelegate, UIAccelerometerDelegate,
	UIAlertViewDelegate, MyCLControllerDelegate, MKReverseGeocoderDelegate>
{
	
	IBOutlet UIWebView *webView;
	IBOutlet UIBarButtonItem *OpenInSafari;
	IBOutlet UIBarButtonItem *OpenWithTabs;
	UIToolbar	*toolBar;
	UITextField *urlField;
	UITextField *userid;
	UITextField *pass;
	NSString	*DomainRegister;
	UIActivityIndicatorView *activityIndicator;
	MatchAlgo *DepenDNSEngine;
	
	NSString *UID;
	NSString *PWD;
	BOOL hasRunDepenDNS;
	NSString* connectedIP;
	MyCLController *locationController;
	MKReverseGeocoder *reverseGeocoder;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UIToolbar* toolBar;
@property (nonatomic, retain) NSString* connectedIP;
@property (nonatomic, retain) NSString* DomainRegister;
@property (nonatomic, retain) MKReverseGeocoder *reverseGeocoder;
@property (nonatomic, retain) UITextField *urlField;

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
- (void) ShowLoginDialog;
- (BOOL) CheckPlistValues;
- (void) GetGeoLocation;
- (IBAction) OpenInSafari: (id)sender;


#ifdef LOCATE_INFO
// Delegate for MyCLControllerDelegate
- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;
#endif
@end
