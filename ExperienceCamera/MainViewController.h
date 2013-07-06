//
//  MainViewController.h
//  ExperienceCamera
//
//  Created by Brian Rogers on 6/22/13.
//  Copyright (c) 2013 Brian Rogers. All rights reserved.
//

#import "FlipsideViewController.h"
#import "SendStatementViewController.h"
#import "UIImage+Resize.h"
#import "UIImage+OrientationFix.h"


@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@property (strong, nonatomic) UIPopoverController *sendStatementPopoverController;

@property (strong, nonatomic) IBOutlet UIImageView *imageView;


-(IBAction)takePhoto:(id)sender;
-(IBAction)sendStatement:(id)sender;
@end
