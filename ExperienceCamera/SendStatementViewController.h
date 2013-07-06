//
//  SendStatementViewController.h
//  ExperienceCamera
//
//  Created by Brian Rogers on 6/25/13.
//  Copyright (c) 2013 Brian Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSTCAPI/RSTinCanConnector.h"
#import "Base64.h"
#import <CoreLocation/CoreLocation.h>
#import <SIAlertView/SIAlertView.h>
#import "MBProgressHUD.h"

@class SendStatementViewController;

@protocol SendStatementViewControllerDelegate
- (void)sendStatementViewControllerDidFinish:(SendStatementViewController *)controller;
@end

@interface SendStatementViewController : UIViewController <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
}
@property (weak, nonatomic) id <SendStatementViewControllerDelegate> delegate;

@property (strong, nonatomic) RSTinCanConnector *tincan;
@property (strong, nonatomic) NSString *imageData;

@property (weak, nonatomic) IBOutlet UITextField *fullName;
@property (weak, nonatomic) IBOutlet UITextField *emailAddress;
@property (weak, nonatomic) IBOutlet UITextField *verbId;
@property (weak, nonatomic) IBOutlet UITextField *activityId;
@property (weak, nonatomic) IBOutlet UITextField *activityName;

- (IBAction)done:(id)sender;
-(IBAction)sendStatementAndClose:(id)sender;
-(IBAction)cancel:(id)sender;

@end
