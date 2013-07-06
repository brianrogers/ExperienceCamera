//
//  FlipsideViewController.h
//  ExperienceCamera
//
//  Created by Brian Rogers on 6/22/13.
//  Copyright (c) 2013 Brian Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController

@property (weak, nonatomic) id <FlipsideViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIWebView *webview;

- (IBAction)done:(id)sender;

@end
