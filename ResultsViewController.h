//
//  ResultsViewController.h
//  LyftEstimator
//
//  Created by Paul Rolfe on 4/12/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>{
    NSArray * resultsArray;
}

@property NSString * resultsString;
@property (weak, nonatomic) IBOutlet UITableView *ResultsTableView;

@end
