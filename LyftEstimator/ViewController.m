//
//  ViewController.m
//  LyftEstimator
//
//  Created by Paul Rolfe on 3/25/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize mapView,destination, start,fromField,title,toField,city,searchBarView,searchTableView,resultsView,activityIndicator,resultFare,milesLabel,uberResult,uberActivityIndicator;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (city==nil)
        city=[[NSUserDefaults standardUserDefaults] objectForKey:@"city"];
    
    //Set the city on the user object.
    [PFUser currentUser][@"city"]=city;
    [[PFUser currentUser] saveInBackground];
    
    mapView.showsUserLocation = YES;
    mapView.rotateEnabled=NO;
    mapView.pitchEnabled=NO;
    mapView.delegate=self;
    
    toField.delegate=self;
    [toField addTarget:self action:@selector(filterContentForSearchText) forControlEvents:UIControlEventEditingChanged];
    fromField.delegate=self;
    [fromField addTarget:self action:@selector(filterContentForSearchText) forControlEvents:UIControlEventEditingChanged];
    //start the fromfield as bold and pink
    fromField.textColor=[UIColor colorWithRed:0.94 green:0.33 blue:0.82 alpha:1];
    UIFontDescriptor * boldfont = [[UIFontDescriptor alloc] init];
    UIFontDescriptor * bolder = [boldfont fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    fromField.font=[UIFont fontWithDescriptor:bolder size:15];
    
    searchTableView.hidden=YES;
    searchTableView.delegate=self;
    searchTableView.dataSource=self;
    searchBarView.hidden=NO;
    searchShouldBeUp=YES;
    
    self.lyftButton.layer.cornerRadius=5;
    self.uberButton.layer.cornerRadius=5;
    self.lyftButton.layer.shadowRadius=5;
    self.uberButton.layer.shadowRadius=5;
    self.uberButton.layer.shadowOpacity=.5;
    self.lyftButton.layer.shadowOpacity=.5;
    
    resultsView.hidden=YES;
    resultFare.hidden=YES;
    resultFare.layer.cornerRadius=5;
    uberResult.hidden=YES;
    uberResult.layer.cornerRadius=5;
    resultsView.backgroundColor=[UIColor colorWithWhite:.8 alpha:.7];
    
    self.navigationItem.prompt=@"Search or drop a pin";
    self.navigationItem.title=city;
    
    UILongPressGestureRecognizer * press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    press.minimumPressDuration = .5; //user needs to press for x seconds
    [mapView addGestureRecognizer:press];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [mapView addGestureRecognizer:tap];
    
    UISwipeGestureRecognizer * downResults = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(downWithResults)];
    downResults.direction=UISwipeGestureRecognizerDirectionDown;
    [resultsView addGestureRecognizer:downResults];
    
    //iAd things
    if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
        bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    } else {
        bannerView = [[ADBannerView alloc] init];
    }
    bannerView.delegate = self;
    [self.view addSubview:bannerView];
  
}
-(void)downWithResults{
    CGFloat op = resultsView.frame.size.height;
    CGFloat vc = self.view.frame.size.height;
    [UIView beginAnimations:@"moveDown" context:nil];
    [UIView setAnimationDuration:.2];
    [resultsView setFrame:CGRectMake(0, vc, resultsView.frame.size.width, op)];
    [UIView commitAnimations];
    resultFare.hidden=YES;
    uberResult.hidden=YES;
}
-(void) viewDidAppear:(BOOL)animated{
    //count the opens.
    
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //if the open count is 5 or a multiple of 20...
        NSLog(@"Current count is %d",[object[@"openCount"] intValue]);
        
        if ([object[@"openCount"] intValue]==5 || ([object[@"openCount"] intValue]%20)==0){
            if([object[@"openCount"] intValue]!=0)
                [self showSharePrompt];
        }
        
        [[PFUser currentUser] incrementKey:@"openCount"];
        [[PFUser currentUser] saveInBackground];
        
    }];
    
    //maybe zoom to city?
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = city;
    
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        if (response.mapItems.count == 0)
            NSLog(@"No Matches");
        else{
            MKMapItem * startCity=[response.mapItems objectAtIndex:0];
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(startCity.placemark.location.coordinate, 20000, 20000);
            [mapView setRegion:region animated:YES];
        }
    }];
}
-(void) showNewFeatures{
    UIView * newFeatures = [[UIView alloc] initWithFrame:CGRectMake(0, resultsView.frame.origin.y-110, 320, 142)];
    newFeatures.tag=102;
    UIImageView * display = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 142)];
    display.image=[UIImage imageNamed:@"tapToOpen"];
    
    UIButton * xOut = [[UIButton alloc] initWithFrame:CGRectMake(13, 0, 33, 33)];
    [xOut setImage:[UIImage imageNamed:@"x_alt-512"] forState:UIControlStateNormal];
    [xOut addTarget:self action:@selector(removeFeaturesPrompt) forControlEvents:UIControlEventTouchUpInside];
    
    [newFeatures addSubview:display];
    [newFeatures addSubview:xOut];
    [self.view addSubview:newFeatures];
}
-(void) removeFeaturesPrompt{
    [[self.view viewWithTag:102] removeFromSuperview];
}
-(NSString *)GetDocumentDirectory{
    NSString * homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    return homeDir;
}

#pragma mark - Social
-(void) showSharePrompt{
    UIView * shareprompt = [[UIView alloc] initWithFrame:CGRectMake(37,106,246,395)];
    shareprompt.tag=101;
    
    UIButton * xOut = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [xOut setImage:[UIImage imageNamed:@"x_alt-512"] forState:UIControlStateNormal];
    [xOut addTarget:self action:@selector(removeSharePrompt) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView * mainImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 246, 395)];
    mainImage.image=[UIImage imageNamed:@"share_popup.png"];
    
    UIButton * fbButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 330, 40, 40)];
    [fbButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
    [fbButton addTarget:self action:@selector(shareFb) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * twButton = [[UIButton alloc] initWithFrame:CGRectMake(150, 330, 40, 40)];
    [twButton setImage:[UIImage imageNamed:@"twitter.png"] forState:UIControlStateNormal];
    [twButton addTarget:self action:@selector(shareTw) forControlEvents:UIControlEventTouchUpInside];
    
    [shareprompt addSubview:mainImage];
    [shareprompt addSubview:fbButton];
    [shareprompt addSubview:twButton];
    [shareprompt addSubview:xOut];
    shareprompt.alpha=0;
    
    [self.view addSubview:shareprompt];
    
    [UIView animateWithDuration:.2 delay:0 options:0 animations:^{
        // Animate the alpha value of your imageView from 1.0 to 0.0 here
        shareprompt.alpha=1;
    } completion:^(BOOL finished) {
        // Once the animation is completed and the alpha has gone to 0.0, hide the view for good
    }];

}
-(void) removeSharePrompt{
    [[self.view viewWithTag:101] removeFromSuperview];
}
-(void)shareFb{
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        NSLog(@"Ready to Facebook.");
        SLComposeViewController *fbComposer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbComposer setInitialText:@"Make sure you get the best deal on your next rideshare with MyFare."];
        [fbComposer addImage:[UIImage imageNamed:@"LyftOrUber.png"]];
        [fbComposer addURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/myfare/id848923129?mt=8"]];
        fbComposer.completionHandler = ^(SLComposeViewControllerResult result){
            if(result == SLComposeViewControllerResultDone){
                NSLog(@"Facebooked.");
                [self removeSharePrompt];
                
            } else if(result == SLComposeViewControllerResultCancelled) {
                NSLog(@"Cancelled.");
            }
        };
        [self presentViewController:fbComposer animated:YES completion:nil];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"You can't facebook right now, make sure your device has an internet connection and you have at least one Facebook account setup"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}
-(void)shareTw{
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        NSLog(@"Ready to Tweet.");
        SLComposeViewController *tweetComposer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetComposer setInitialText:@"Make sure you get the best deal on your next rideshare with #MyFare."];
        [tweetComposer addImage:[UIImage imageNamed:@"LyftOrUber.png"]];
        [tweetComposer addURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/myfare/id848923129?mt=8"]];
        tweetComposer.completionHandler = ^(SLComposeViewControllerResult result){
            if(result == SLComposeViewControllerResultDone){
                NSLog(@"Tweeted.");
                [self removeSharePrompt];
                
            } else if(result == SLComposeViewControllerResultCancelled) {
                NSLog(@"Cancelled.");
            }
        };
        [self presentViewController:tweetComposer animated:YES completion:nil];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - iAd Methods
//iAd things
- (void)layoutAnimated:(BOOL)animated
{
    // As of iOS 6.0, the banner will automatically resize itself based on its width.
    // To support iOS 5.0 however, we continue to set the currentContentSizeIdentifier appropriately.
    CGRect contentFrame = self.view.bounds;
    /*if (contentFrame.size.width < contentFrame.size.height) {
        bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    } else {
        bannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }*/
    
    CGRect bannerFrame = bannerView.frame;
    if (bannerView.bannerLoaded) {
        contentFrame.size.height -= bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        _contentView.frame = contentFrame;
        [_contentView layoutIfNeeded];
        bannerView.frame = bannerFrame;
    }];
}
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self layoutAnimated:NO];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutAnimated:YES];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

-(BOOL)shouldAutorotate{
    return YES;
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self layoutAnimated:YES];
}

#pragma mark - Textfields
- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    [self estimateFare:textField];
    
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    //show the table.
    searchTableView.hidden=NO;
    textField.textColor=[UIColor blackColor];
    UIFontDescriptor * unboldfont = [[UIFontDescriptor alloc] init];
    textField.font=[UIFont fontWithDescriptor:unboldfont size:15];
    [self filterContentForSearchText];
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if ([textField.text isEqualToString:@"Current Location"]){
        textField.textColor=[UIColor colorWithRed:0.94 green:0.33 blue:0.82 alpha:1];
        UIFontDescriptor * boldfont = [[UIFontDescriptor alloc] init];
        UIFontDescriptor * bolder = [boldfont fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        textField.font=[UIFont fontWithDescriptor:bolder size:15];
    }
    else{
        textField.textColor=[UIColor blackColor];
        UIFontDescriptor * unboldfont = [[UIFontDescriptor alloc] init];
        textField.font=[UIFont fontWithDescriptor:unboldfont size:15];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Estimation and Mapping
- (void)estimateFare:(id)sender {
    
    newSearch=YES;
    searchShouldBeUp=NO;
    
    //clear the old results.
    [mapView removeOverlays:mapView.overlays];
    [mapView removeAnnotation:oldStartPin];
    
    [toField resignFirstResponder];
    [fromField resignFirstResponder];
    
    //Find the destination
    if (![toField.text isEqualToString:@""]){
        [mapView removeAnnotations:mapView.annotations];
        
        MKLocalSearchRequest *request =
        [[MKLocalSearchRequest alloc] init];

        request.naturalLanguageQuery = toField.text;
        request.region =  mapView.region;
        
        matchingItems = [[NSMutableArray alloc] init];
        
        MKLocalSearch *search =
        [[MKLocalSearch alloc]initWithRequest:request];
        
        [search startWithCompletionHandler:^(MKLocalSearchResponse
                                             *response, NSError *error) {
            if (response.mapItems.count == 0)
                NSLog(@"No Matches");
            else{
                
                for (MKMapItem *item in response.mapItems)
                {
                    [matchingItems addObject:item];
                    MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:item.placemark.location.coordinate addressDictionary:nil];
                    annot.title = item.name;
                    annot.subtitle = [NSString stringWithFormat:@"%@, %@",item.placemark.locality,item.placemark.administrativeArea];
                    annot.mapItem=item;

                    [mapView addAnnotation:annot];
                }
                
                //save the destination to the file
                [self addDestinationToSavedSearch:[mapView annotations][0]];
                
                destination = [matchingItems objectAtIndex:0];
                [self findRoute];
            }
        }];
    }
    else{
        [self findRoute];
    }
}

-(void)findRoute{
    //set the starting point
    if ([fromField.text isEqualToString:@""] || [fromField.text isEqualToString:@"Current Location"]){
        //Set it to say current location, if it doesn't. And make it pink and bold.
        fromField.text=@"Current Location";
        UIFontDescriptor * boldfont = [[UIFontDescriptor alloc] init];
        UIFontDescriptor * bolder = [boldfont fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        fromField.font=[UIFont fontWithDescriptor:bolder size:15];
        fromField.textColor=[UIColor colorWithRed:0.94 green:0.33 blue:0.82 alpha:1];
        
        start = [MKMapItem mapItemForCurrentLocation];
        //place a pin at start.
        MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:mapView.userLocation.coordinate addressDictionary:nil];
        annot.title = @"Current Location";
        annot.isStart=YES;
        annot.mapItem=start;
        oldStartPin=annot;
        [mapView addAnnotation:annot];
        
        [self calculateRoute];
    }
    //maybe search for the starting point if it's not the current location.
    else if (start==nil || newSearch){
        [self fromMapItem];
    }
    //else just calculate using the existing starting point.
    else{
        [self calculateRoute];
    }
}
-(void) fromMapItem{
    MKLocalSearchRequest *request =
    [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = fromField.text;
    request.region =  mapView.region;
    
    NSMutableArray * startItems = [[NSMutableArray alloc] init];
    
    MKLocalSearch *search =
    [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        if (response.mapItems.count == 0)
            NSLog(@"No Start Matches");
        else{
            
            for (MKMapItem *item in response.mapItems)
            {
                [startItems addObject:item];
            }
            start = [startItems objectAtIndex:0];
            
            //create a pin for the new start place.
            MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:start.placemark.location.coordinate addressDictionary:nil];
            annot.title = start.name;
            annot.subtitle = [NSString stringWithFormat:@"%@, %@",start.placemark.locality,start.placemark.administrativeArea];
            annot.isStart=YES;
            annot.mapItem=start;
            oldStartPin=annot;
            [mapView addAnnotation:annot];
            
            [self calculateRoute];
        }
    }];
}
-(void) calculateRoute{
    
    //hide everything, start indicators
    [activityIndicator startAnimating];
    [uberActivityIndicator startAnimating];
    resultFare.hidden=YES;
    uberResult.hidden=YES;
    resultsView.hidden=NO;
    searchTableView.hidden=YES;
    
    //create the animation to show the results
    CGFloat op = resultsView.frame.size.height;
    CGFloat vc = self.view.frame.size.height;
    [resultsView setFrame:CGRectMake(0, vc, resultsView.frame.size.width, op)];
    [UIView beginAnimations:@"moveUp" context:nil];
    [UIView setAnimationDuration:.2];
    [resultsView setFrame:CGRectMake(0, vc-op, resultsView.frame.size.width, op)];
    [UIView commitAnimations];
    
    //if there is no start pin present, make one at the current location.
    if (start==nil){
        start = [MKMapItem mapItemForCurrentLocation];
        //place a pin at start.
        MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:mapView.userLocation.coordinate addressDictionary:nil];
        annot.title = @"Current Location";
        annot.isStart=YES;
        annot.mapItem=start;
        oldStartPin=annot;
        [mapView addAnnotation:annot];
    }
    
    MKDirectionsRequest *dRequest =
    [[MKDirectionsRequest alloc] init];
    dRequest.destination = destination;
    dRequest.source = start;
    dRequest.requestsAlternateRoutes = YES;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:dRequest];
    
    
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error) {
             // Handle error
             //NSLog([error.userInfo objectForKey:NSLocalizedDescriptionKey]);
         } else {
             [self showRoute:response];
         }
     }];
}
-(void)showRoute:(MKDirectionsResponse *)response
{
    [mapView removeOverlays:mapView.overlays];
    
    otherRoutes = [[NSMutableArray alloc] init];
    int i=0;
    for (MKRoute *route in response.routes){
        currentRouteIndex=0;
        if (i==0){
            [otherRoutes addObject:route];
            [self getFareFromRoute:route];
            
        }
        if (i>0){
            [otherRoutes addObject:route];
        }
        i++;
    }
}
-(void) getFareFromRoute:(MKRoute *)route{
    //show new features if they haven't seen them yet.
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"version1.2"]==NO){
        [self showNewFeatures];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"version1.2"];
    }
    
    NSInteger i = [otherRoutes indexOfObject:route];
    
    route.polyline.title=[NSString stringWithFormat:@"Route %li of %lu",(long)i+1,(unsigned long)otherRoutes.count];
    [mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
    
    miles = (route.distance/1000)*.62;
    minutes = route.expectedTravelTime/60;
    
    milesLabel.text = [NSString stringWithFormat:@"Route %lu:  %.2f miles, %.0f minutes",currentRouteIndex+1,miles,minutes];
    
    [activityIndicator startAnimating];
    [uberActivityIndicator startAnimating];
    resultFare.hidden=YES;
    uberResult.hidden=YES;
    //Add a parse cloud function that will calculate the cost for Lyft
    [PFCloud callFunctionInBackground:@"estimate"
                       withParameters:@{@"miles" : [NSNumber numberWithFloat:miles],
                                        @"minutes" : [NSNumber numberWithFloat:minutes],
                                        @"timeOfDay" : [NSDate date],
                                        @"city" : city}
                                block:^(NSString * message, NSError *error) {
                                    if (!error){
                                        //When it returns success, pop up alert
                                        [activityIndicator stopAnimating];
                                        resultFare.hidden=NO;
                                        resultFare.text=message;
                                    }
                                    if (error){
                                        UIAlertView * badCode = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                        [badCode show];
                                        [activityIndicator stopAnimating];
                                    }
                                }];
    //Add a parse cloud function that will calculate the cost for Uber
    [PFCloud callFunctionInBackground:@"estimateUber"
                       withParameters:@{@"miles" : [NSNumber numberWithFloat:miles],
                                        @"minutes" : [NSNumber numberWithFloat:minutes],
                                        @"timeOfDay" : [NSDate date],
                                        @"city" : city}
                                block:^(NSString * message, NSError *error) {
                                    if (!error){
                                        //When it returns success, pop up alert
                                        [uberActivityIndicator stopAnimating];
                                        uberResult.hidden=NO;
                                        uberResult.text=message;
                                    }
                                    if (error){
                                        UIAlertView * badCode = [[UIAlertView alloc] initWithTitle:@"Error" message:[error userInfo][@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                        [badCode show];
                                        [uberActivityIndicator stopAnimating];
                                    }
                                }];
    
    //zoom to the route
    MKPolygon* polygon = [MKPolygon polygonWithPoints:route.polyline.points count:route.polyline.pointCount];
    
    if (newSearch){
        [mapView setRegion:MKCoordinateRegionForMapRect([polygon boundingMapRect])
                  animated:YES];
        newSearch=NO;
    }
    
    //Track that this request was made.
    NSDictionary *dimensions = @{
                                 // Define ranges to bucket data points into meaningful segments
                                 @"city": city
                                 };
    // Send the dimensions to Parse along with the 'search' event
    [PFAnalytics trackEvent:@"Estimation" dimensions:dimensions];

}
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    MKPolylineRenderer *renderer =[[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.strokeColor = [UIColor colorWithRed:.33 green:.94 blue:.82 alpha:1];
    renderer.lineWidth = 5.0;
    return renderer;
}


-(MKAnnotationView *) mapView:(MKMapView *)mapview viewForAnnotation:(id<MKAnnotation>)annotation{
    // Try to dequeue an existing pin view first (code not shown).
    if ([annotation class]==[MKUserLocation class]) {        
        return nil;
	}
    
    MyCustomAnnotation * annot = (MyCustomAnnotation *)annotation;
	
	static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
    MKPinAnnotationView *customPinView= (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationIdentifier];
    if (customPinView == nil){
        customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier];
    }
    if (annot.isStart){
        customPinView.pinColor = MKPinAnnotationColorGreen;
        customPinView.animatesDrop = NO;
        customPinView.canShowCallout = YES;
        customPinView.draggable=YES;
    }
    else{
        customPinView.pinColor = MKPinAnnotationColorPurple;
        customPinView.animatesDrop = YES;
        customPinView.canShowCallout = YES;
        customPinView.draggable=YES;
    }
    
    // Because this is an iOS app, add the detail disclosure button to display details about the annotation in another view.
    /*UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
    customPinView.rightCalloutAccessoryView = rightButton;
    
    // Add a custom image to the left side of the callout.
    UIImageView *myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MyCustomImage.png"]];
    customPinView.leftCalloutAccessoryView = myCustomImage;*/
    
    return customPinView;
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    //..Whatever you want to happen when the dragging starts or stops
    if (oldState==MKAnnotationViewDragStateDragging){
        //get the info from the old annotation to make a new one...
        MyCustomAnnotation *annotation = (MyCustomAnnotation *)annotationView.annotation;
        CLLocationCoordinate2D  coord = annotation.coordinate;
        BOOL isStart = annotation.isStart;
        [self.mapView removeAnnotation:annotation];
        
        MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:coord addressDictionary:nil];
        annot.isStart=isStart;
        [self.mapView addAnnotation:annot];
		[self geocodeLocation:annot.location forAnnotation:annot];
    }
}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    //if the user touches a pin
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
	}
    
    MyCustomAnnotation * annot = (MyCustomAnnotation *)view.annotation;
    if (annot.isStart)
        return;
    
    destination = ((MyCustomAnnotation *)view.annotation).mapItem;
    [self calculateRoute];
}
- (void)geocodeLocation:(CLLocation*)location forAnnotation:(MyCustomAnnotation*)annotation{
    
    if (!geocoder)
        geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:location completionHandler:
     ^(NSArray* placemarks, NSError* error){
         if ([placemarks count] > 0)
         {
             MKPlacemark * newMark = [[MKPlacemark alloc] initWithPlacemark:[placemarks objectAtIndex:0]];
             annotation.title = newMark.name;
             annotation.subtitle = [NSString stringWithFormat:@"%@, %@",newMark.locality,newMark.administrativeArea];
             MKMapItem * newItem=[[MKMapItem alloc] initWithPlacemark:newMark];
             annotation.mapItem=newItem;
             if (annotation.isStart){
                 start=newItem;
                 oldStartPin=annotation;
             }
             else{
                 destination = newItem;
                 oldAnnot=annotation;
             }
             [self calculateRoute];
         }
     }];
}
-(void) mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    searchBarView.hidden=YES;
}
-(void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (searchShouldBeUp)
        searchBarView.hidden=NO;
}

#pragma mark - Gesture Handlers
-(void) handleTap:(UIGestureRecognizer *)gestureRecognizer{
    [toField resignFirstResponder];
    [fromField resignFirstResponder];
}

-(void) handlePress:(UIGestureRecognizer *)gestureRecognizer{
    
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    [mapView removeAnnotation:oldAnnot];
    
    CGPoint touchPoint = [gestureRecognizer locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    
    MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:touchMapCoordinate addressDictionary:nil];
    [mapView addAnnotation:annot];

    MKPlacemark * pmark = [[MKPlacemark alloc] initWithCoordinate:touchMapCoordinate addressDictionary:nil];
    
    //set the start location to the dropped pin and estimate the far to that spot. Need to add address data to the mapitem.
    [self geocodeLocation:pmark.location forAnnotation:annot];
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if ([scrollView isMemberOfClass:[UITableView class]]){
        [toField resignFirstResponder];
        [fromField resignFirstResponder];
        resultsView.hidden=YES;
    }
}


#pragma mark - Tableview
-(void) addDestinationToSavedSearch:(MyCustomAnnotation *)destinationItem{
    NSMutableArray * masterArray = [NSMutableArray arrayWithContentsOfFile:[self.GetDocumentDirectory stringByAppendingPathComponent:@"SavedSearches"]];
    if (masterArray==nil)
        masterArray = [[NSMutableArray alloc] init];
    
    if (![destinationItem.title isEqualToString:@"Current Location"]){
        NSMutableDictionary * newDict = [[NSMutableDictionary alloc] init];
        [newDict setValue:destinationItem.title forKey:@"title"];
        [newDict setValue:destinationItem.subtitle forKey:@"subtitle"];
        [newDict setValue:[NSString stringWithFormat:@"%f",destinationItem.coordinate.latitude] forKey:@"latitude"];
        [newDict setValue:[NSString stringWithFormat:@"%f",destinationItem.coordinate.longitude] forKey:@"longitude"];
        [masterArray insertObject:newDict atIndex:0];
        if (masterArray.count>20){
            [masterArray removeObjectAtIndex:20];
        }
        [masterArray writeToFile:[self.GetDocumentDirectory stringByAppendingPathComponent:@"SavedSearches"] atomically:YES];

    }
}
-(NSArray *)mapItemsArrayFromDictionaryArray:(NSArray *)dictArray{
    NSMutableArray * newArray = [[NSMutableArray alloc] init];
    
    for (int i=0;i<dictArray.count;i++){
        NSDictionary * currentDict = dictArray[i];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([currentDict[@"latitude"] doubleValue], [currentDict[@"longitude"] doubleValue]);
        
        MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:coord addressDictionary:nil];
        annot.title = currentDict[@"title"];
        annot.subtitle = currentDict[@"subtitle"];
        MKPlacemark * pm = [[MKPlacemark alloc] initWithCoordinate:coord addressDictionary:nil];
        MKMapItem * mi = [[MKMapItem alloc] initWithPlacemark:pm];
        annot.mapItem=mi;
        
        [newArray addObject:annot];
    }
    
    return newArray;
}

- (void)filterContentForSearchText{

    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    
    NSString * searchText;
    if ([toField isFirstResponder])
        searchText=toField.text;
    if ([fromField isFirstResponder])
        searchText=fromField.text;
    
    if ([searchText isEqualToString:@""]){
        //make the first option current location
        MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:mapView.userLocation.coordinate addressDictionary:nil];
        annot.title = @"Current Location";
        annot.mapItem=[MKMapItem mapItemForCurrentLocation];
        [tableResults addObject:annot];
        
        tableResults=[[NSMutableArray alloc] initWithObjects:annot, nil];
        NSMutableArray * masterArray = [NSMutableArray arrayWithContentsOfFile:[self.GetDocumentDirectory stringByAppendingPathComponent:@"SavedSearches"]];
        [tableResults addObjectsFromArray:[self mapItemsArrayFromDictionaryArray:masterArray]];
        [searchTableView reloadData];
        return;
    }
    
    request.naturalLanguageQuery = searchText;
    //request.region =  MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate,97000, 97000);
    request.region=mapView.region;
    
    NSMutableArray * newPlaces = [[NSMutableArray alloc] init];
    
    MKLocalSearch *search =
    [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        if (response.mapItems.count == 0){
            NSLog(@"No Matches");
        }
        else{
            
            for (MKMapItem *item in response.mapItems)
            {
                MyCustomAnnotation *annot = [[MyCustomAnnotation alloc] initWithCoordinate:item.placemark.location.coordinate addressDictionary:nil];
                annot.title = item.name;
                annot.subtitle = [NSString stringWithFormat:@"%@, %@", item.placemark.locality,item.placemark.administrativeArea];
                annot.mapItem=item;
                [newPlaces addObject:annot];
            }
            tableResults = newPlaces;
            [searchTableView reloadData];
        }
    }];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return tableResults.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell==nil){
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    MyCustomAnnotation *annot = [tableResults objectAtIndex:indexPath.row];
    cell.textLabel.text=annot.title;
    cell.detailTextLabel.text=annot.subtitle;
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([toField isFirstResponder]){
        destination=((MyCustomAnnotation *)[tableResults objectAtIndex:indexPath.row]).mapItem;
        toField.text=((MyCustomAnnotation *)[tableResults objectAtIndex:indexPath.row]).title;
        newSearch=YES;
        [toField resignFirstResponder];
        [fromField resignFirstResponder];
        
        //clear the old results.
        [mapView removeOverlays:mapView.overlays];
        [mapView removeAnnotations:mapView.annotations];
        
        [mapView addAnnotation:(MyCustomAnnotation *)[tableResults objectAtIndex:indexPath.row]];
        [searchBarView setHidden:YES];
        searchShouldBeUp=NO;
        [self findRoute];
    }
    if ([fromField isFirstResponder]){
        start=((MyCustomAnnotation *)[tableResults objectAtIndex:indexPath.row]).mapItem;
        fromField.text=((MyCustomAnnotation *)[tableResults objectAtIndex:indexPath.row]).title;
        [toField becomeFirstResponder];
        [self filterContentForSearchText];
    }
    
    //save the destination to the file
    [self addDestinationToSavedSearch:(MyCustomAnnotation *)[tableResults objectAtIndex:indexPath.row]];
    
}

#pragma mark - Button Actions
- (IBAction)searchBarButton:(id)sender {
    if (![searchBarView isHidden]){//if the search bar is visible...
        [self estimateFare:sender];
        searchBarView.hidden=YES;
    }
    else{//otherwise, bring it up and assign first responder.
        searchBarView.hidden=NO;
        searchShouldBeUp=YES;
        [toField becomeFirstResponder];
    }
}
- (IBAction)switchStartEndButton:(id)sender {
    
    NSString * toText = toField.text;
    NSString * fromText = fromField.text;
    
    toField.text=fromText;
    fromField.text=toText;
    
    [self textFieldDidEndEditing:fromField];
    [self textFieldDidEndEditing:toField];
    
}
- (IBAction)cancelSearch:(id)sender {
    if ([searchTableView isHidden]){
        searchBarView.hidden=YES;
        searchShouldBeUp=NO;
    }
    searchTableView.hidden=YES;
    [toField resignFirstResponder];
    [fromField resignFirstResponder];
}
- (IBAction)switchRoutes:(id)sender {
    [mapView removeOverlays:mapView.overlays];
    
    if (currentRouteIndex+1<otherRoutes.count){
        currentRouteIndex=currentRouteIndex+1;
    }
    else{
        currentRouteIndex=0;
    }
    
    [self getFareFromRoute:[otherRoutes objectAtIndex:currentRouteIndex]];
}
- (IBAction)goToLyft:(id)sender {
    NSString * urlString = @"lyft://";
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        // Do something awesome - the app is installed! Launch App.
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    else {
        // No Uber app! Open Mobile Website.
        NSString * newUserURL = @"https://www.lyft.com/invited/PAUL349147";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:newUserURL]];
        NSDictionary *dimensions = @{
                                     // Define ranges to bucket data points into meaningful segments
                                     @"city": city,
                                     @"service":@"lyft"
                                     };
        [PFAnalytics trackEvent:@"Referrals" dimensions:dimensions];

    }
}

- (IBAction)goToUber:(id)sender {

    NSString * urlString = [NSString stringWithFormat:@"uber://?action=setPickup&pickup[latitude]=%f&pickup[longitude]=%f&pickup[nickname]=%@&dropoff[latitude]=%f&dropoff[longitude]=%f&dropoff[nickname]=%@", start.placemark.location.coordinate.latitude, start.placemark.location.coordinate.longitude,[start.placemark.title stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],destination.placemark.location.coordinate.latitude,destination.placemark.location.coordinate.longitude,[destination.placemark.title stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        // Do something awesome - the app is installed! Launch App.
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    else {
        // No Uber app! Open Mobile Website.
        NSString * newUserURL = @"https://m.uber.com/sign-up?client_id=wtmdzV-rwCReUJrhrgD_XgG9PNaTucRy";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:newUserURL]];
        NSDictionary *dimensions = @{
                                     // Define ranges to bucket data points into meaningful segments
                                     @"city": city,
                                     @"service":@"uber"
                                     };
        [PFAnalytics trackEvent:@"Referrals" dimensions:dimensions];

    }
}
@end

@implementation MyCustomAnnotation

@synthesize coordinate = coordinate_;
@synthesize title = title_;
@synthesize subtitle = subtitle_;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate addressDictionary:(NSDictionary *)addressDictionary {
	
	if ((self = [super initWithCoordinate:coordinate addressDictionary:addressDictionary])) {
		self.coordinate = coordinate;
	}
	return self;
}


@end
