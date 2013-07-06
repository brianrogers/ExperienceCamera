//
//  SendStatementViewController.m
//  ExperienceCamera
//
//  Created by Brian Rogers on 6/25/13.
//  Copyright (c) 2013 Brian Rogers. All rights reserved.
//

#import "SendStatementViewController.h"

@interface SendStatementViewController ()
{
    CLLocation *currentLocation;
    NSString *currentAddress;
}
@end

@implementation SendStatementViewController

@synthesize imageData = _imageData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *lrs = [[NSMutableDictionary alloc] init];
    [lrs setValue:@"https://your.lrs.com/endpoint" forKey:@"endpoint"];
    [lrs setValue:@"Basic YourAuthStringHereJhsudhJHDKsshd74875yrhJJHHdgdhsjdhgjgsg=="forKey:@"auth"];
    [lrs setValue:@"1.0.0"forKey:@"version"];
    // just add one LRS for now
    [options setValue:[NSArray arrayWithObject:lrs] forKey:@"recordStore"];
    [options setValue:@"1.0.0" forKey:@"version"];
    _tincan = [[RSTinCanConnector alloc] initWithOptions:options];
    
    locationManager = [[CLLocationManager alloc] init];
    currentAddress = @""; //default to blank
    [self getCurrentLocation];
    
    [self.view endEditing:YES];
    

    
    [_fullName setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"actor-name"]];
    [_emailAddress setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"actor-email"]];
    
    [_verbId setText:@"http://adlnet.gov/expapi/verbs/experienced"];
    [_activityId setText:@"http://registry.tincanapi.com/activities/experience-camera"];
    [_activityName setText:@""];
    
    
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // For selecting cell.
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];

    
}

- (void) hideKeyboard {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self sendStatement];
    [self.delegate sendStatementViewControllerDidFinish:self];
}

- (IBAction)sendStatementAndClose:(id)sender
{
    [self sendStatement];
    
}

- (IBAction)cancel:(id)sender
{
    [self.delegate sendStatementViewControllerDidFinish:self];
}

- (void)getCurrentLocation {
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    currentLocation = newLocation;
        
    // Stop Location Manager
    [locationManager stopUpdatingLocation];
    
    NSLog(@"Resolving the Address");
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            currentAddress = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                 placemark.subThoroughfare, placemark.thoroughfare,
                                 placemark.postalCode, placemark.locality,
                                 placemark.administrativeArea,
                                 placemark.country];
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    
}


- (void)sendStatement
{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setValue:_fullName.text forKey:@"actor-name"];
    [userDefaults setValue:_emailAddress.text forKey:@"actor-email"];
    
    NSString *currentLong = [NSString stringWithFormat:@"%.8f",currentLocation.coordinate.longitude];
    NSString *currentLat = [NSString stringWithFormat:@"%.8f",currentLocation.coordinate.latitude];
    NSDictionary *coordinateDict = [[NSDictionary alloc] initWithObjects:@[currentLong, currentLat, currentAddress] forKeys:@[@"currentLong",@"currentLat",@"currentAddress"]];
    NSMutableDictionary *resultExt = [[NSMutableDictionary alloc] init];
    [resultExt setValue:coordinateDict forKey:@"http://registry.tincanapi.com/extensions/coordinates"];
    
    
    // sha2 hash the data
    NSString *sha2 = [TCUtil computeSHA256DigestForString:_imageData];
    
    TCAttachment *photo = [[TCAttachment alloc] initWithSha2:sha2 withDataString:_imageData withUsageType:@"http://tincanapi.com/image" withContentType:@"image/jpg" withContentTransferEncoding:@"base64" withDisplay:[[TCLocalizedValues alloc] initWithLanguageCode:@"en-US" withValue:_activityName.text] withDescription:[[TCLocalizedValues alloc] initWithLanguageCode:@"en-US" withValue:_activityName.text] withLength:[NSNumber numberWithInteger:_imageData.length] withFileUrl:nil];
    
    TCAttachmentCollection *attachments = [[TCAttachmentCollection alloc] init];
    [attachments addAttachment:photo];
    
    //NSLog(@"%@", [attachments JSONString]);
    
    NSMutableDictionary *statementOptions = [[NSMutableDictionary alloc] init];
    [statementOptions setValue:[NSString stringWithFormat:@"%@#%@",_activityId.text, [self uuidString]] forKey:@"activityId"];
    [statementOptions setValue:[[TCVerb alloc] initWithId:_verbId.text withVerbDisplay:[[TCLocalizedValues alloc] initWithLanguageCode:@"en-US" withValue:@"experienced"]] forKey:@"verb"];
    [statementOptions setValue:@"http://adlnet.gov/expapi/activities/course" forKey:@"activityType"];
    
    
    TCAgent *actor = [[TCAgent alloc] initWithName:_fullName.text withMbox:[NSString stringWithFormat:@"mailto:%@",_emailAddress.text]];
    
    TCActivityDefinition *actDef = [[TCActivityDefinition alloc] initWithName:[[TCLocalizedValues alloc] initWithLanguageCode:@"en-US" withValue:_activityName.text]
                                                              withDescription:[[TCLocalizedValues alloc] initWithLanguageCode:@"en-US" withValue:_activityName.text]
                                                                     withType:[statementOptions valueForKey:@"activityType"]
                                                               withExtensions:resultExt
                                                          withInteractionType:nil
                                                  withCorrectResponsesPattern:nil
                                                                  withChoices:nil
                                                                    withScale:nil
                                                                   withTarget:nil
                                                                    withSteps:nil];
    
    TCActivity *activity = [[TCActivity alloc] initWithId:[statementOptions valueForKey:@"activityId"] withActivityDefinition:actDef];
    
    //NSLog(@"%@",[activity JSONString]);
    
    TCStatement *statement = [[TCStatement alloc] initWithId:nil withActor:actor withTarget:activity withVerb:[[TCVerb alloc] initWithId:@"http://tincanapi.com/verbs/photographed" withVerbDisplay:[[TCLocalizedValues alloc] initWithLanguageCode:@"en-US" withValue:@"Photographed"]] withBoundary:@"abc123" withAttachments:attachments];
    
    //NSLog(@"%@", statement.JSONString);
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [_tincan sendStatement:statement withCompletionBlock:^(){
        NSLog(@"statement sent");
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Statement Sent" andMessage:@"Your experience was recorded."];
        
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDefault
                              handler:^(SIAlertView *alert) {
                                  NSLog(@"Button1 Clicked");
                                  [self.delegate sendStatementViewControllerDidFinish:self];
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        
        [alertView show];
        
    }withErrorBlock:^(TCError *error){
        NSLog(@"ERROR: %@", error.userInfo);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Error" andMessage:@"There was an error saving your experience."];
        
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDefault
                              handler:^(SIAlertView *alert) {
                                  NSLog(@"Button1 Clicked");
                                  [self.delegate sendStatementViewControllerDidFinish:self];
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        
        [alertView show];
    }];
    //NSLog(@"image/jpg;base64,%@", [UIImageJPEGRepresentation(_imageView.image, 80) base64EncodedString]);
}

- (NSString *)uuidString {
    // Returns a UUID
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    return uuidStr;
}

@end
