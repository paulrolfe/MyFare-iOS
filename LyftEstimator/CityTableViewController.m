//
//  CityTableViewController.m
//  LyftEstimator
//
//  Created by Paul Rolfe on 3/25/14.
//  Copyright (c) 2014 Paul Rolfe. All rights reserved.
//

#import "CityTableViewController.h"

@interface CityTableViewController ()

@end

@implementation CityTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"city"]){
        [self performSegueWithIdentifier:@"toMap" sender:self];
    }
    
    [self loadCities];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"myInfo.png"] landscapeImagePhone:[UIImage imageNamed:@"myInfo.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goToInfoPage)];
}
-(void)loadCities{
    //make array from Parse objects
    PFQuery * cityQuery = [PFQuery queryWithClassName:@"City"];
    [cityQuery whereKeyExists:@"cityName"];
    cities = [[NSMutableArray alloc] init];
    [cityQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error){
            for(PFObject * city in objects){
                [cities addObject:city[@"cityName"]];
            }
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
            [cities sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            [self.tableView reloadData];
        }
    }];
}
-(void)viewWillAppear:(BOOL)animated{
    self.navigationItem.title=@"Choose Your City";
    self.navigationItem.prompt=@"Pricing for regular hours only";
}
-(void) dismissViewHelp{
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void) goToInfoPage{
    UIViewController *trueDest = [[UIViewController alloc] init];
    UINavigationController *destNav = [[UINavigationController alloc] initWithRootViewController:trueDest];
    
    trueDest.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon@2x.png"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewHelp)];
    trueDest.title=@"About";
    
    UISwipeGestureRecognizer * gestureR =[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViewHelp)];
    gestureR.direction = UISwipeGestureRecognizerDirectionDown;
    [destNav.view addGestureRecognizer:gestureR];
    
    UIWebView * pdfView = [[UIWebView alloc] initWithFrame:trueDest.view.frame];
    spinnner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(trueDest.view.frame.size.width/2-25, trueDest.view.frame.size.height/2-25, 50, 50)];
    spinnner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    NSURL *targetURL = [NSURL URLWithString:@"http://paulrolfe.wordpress.com/examples-of-work/lyftestimator/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
    pdfView.scalesPageToFit=YES;
    pdfView.delegate=self;
    [trueDest.view addSubview:pdfView];
    [trueDest.view addSubview:spinnner];
    [spinnner startAnimating];
    
    [self presentViewController:destNav animated:YES completion:nil];
    
    [pdfView loadRequest:request];
    
    [pdfView.scrollView setContentOffset:CGPointZero animated:NO];
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [spinnner stopAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return cities.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSString * city = [cities objectAtIndex:indexPath.row];
    cell.textLabel.text= city;
    cell.detailTextLabel.text = nil;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath * path = [self.tableView indexPathForSelectedRow];
    self.navigationItem.title=@"Cities";
    //save their city in settings.
    // Get the new view controller using [segue destinationViewController].
    if (!cities)
        [((ViewController *)segue.destinationViewController) setCity:[[NSUserDefaults standardUserDefaults] objectForKey:@"city"]];
    else{
        [[NSUserDefaults standardUserDefaults]setObject:[cities objectAtIndex:path.row] forKey:@"city"];
        [((ViewController *)segue.destinationViewController) setCity:[cities objectAtIndex:path.row]];
    }

    
    // Pass the selected object to the new view controller.
}


@end
