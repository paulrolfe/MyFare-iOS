//
//  ViewController.h
//  LyftEstimator
//
//  Created by Paul Rolfe on 3/25/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "ResultsViewController.h"
#import <iAd/iAd.h>
#import <Social/Social.h>

@class MyCustomAnnotation;

@interface ViewController : UIViewController<MKMapViewDelegate, UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,ADBannerViewDelegate>{
    NSMutableArray * matchingItems;
    float miles;
    float minutes;
    MKAnnotationView * oldPin;
    CLGeocoder * geocoder;
    MyCustomAnnotation * oldAnnot;
    MyCustomAnnotation * oldStartPin;
    BOOL newSearch;
    BOOL searchShouldBeUp;
    NSMutableArray * tableResults;
    NSArray *  defaultResults;
    NSMutableArray * otherRoutes;
    NSUInteger currentRouteIndex;
    
    ADBannerView *bannerView;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property MKMapItem *destination;
@property MKMapItem *start;
@property NSString * city;

@property (weak, nonatomic) IBOutlet UITextField *fromField;
@property (weak, nonatomic) IBOutlet UITextField *toField;

@property (weak, nonatomic) IBOutlet UITableView *searchTableView;
@property (weak, nonatomic) IBOutlet UIView *resultsView;

@property (weak, nonatomic) IBOutlet UIView *searchBarView;

- (IBAction)searchBarButton:(id)sender;
- (IBAction)switchStartEndButton:(id)sender;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uberActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *resultFare;
@property (weak, nonatomic) IBOutlet UILabel *uberResult;
@property (weak, nonatomic) IBOutlet UILabel *milesLabel;
- (IBAction)cancelSearch:(id)sender;
- (IBAction)switchRoutes:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *uberButton;
@property (weak, nonatomic) IBOutlet UIButton *lyftButton;
- (IBAction)goToLyft:(id)sender;
- (IBAction)goToUber:(id)sender;

@property (nonatomic, strong) IBOutlet UIView *contentView;

@end

@interface MyCustomAnnotation : MKPlacemark {
	CLLocationCoordinate2D coordinate_;
	NSString *title_;
	NSString *subtitle_;
}

// Re-declare MKAnnotation's readonly property 'coordinate' to readwrite.
@property (nonatomic, readwrite, assign) CLLocationCoordinate2D coordinate;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property BOOL isStart;
@property MKMapItem * mapItem;

@end
