//
//  CityTableViewController.h
//  LyftEstimator
//
//  Created by Paul Rolfe on 3/25/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>

@interface CityTableViewController : UITableViewController<UIWebViewDelegate>{
    NSMutableArray * cities;
    UIActivityIndicatorView * spinnner;
}

@end
