//
//  SetupViewController.m
//  GateOpener
//
//

#import "SetupViewController.h"

@interface SetupViewController ()

@end

@implementation SetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, 300, 300);
    MKCoordinateRegion adjustedRegion = [self.map regionThatFits:viewRegion];
    [self.map setRegion:adjustedRegion animated:YES];
    self.map.showsUserLocation = YES;
    self.code.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"code"];
}

-(IBAction)centerSet:(id)sender {
    CLLocationCoordinate2D centerCoordinate = [self.map centerCoordinate];
    [[NSUserDefaults standardUserDefaults] setDouble:centerCoordinate.latitude forKey:@"latitude"];
    [[NSUserDefaults standardUserDefaults] setDouble:centerCoordinate.longitude forKey:@"longitude"];
    
    [[NSUserDefaults standardUserDefaults] setDouble:8.0 forKey:@"radius"];
    
}

-(IBAction)codeSet:(id)sender {
    // Probably should go in keychain but as this is not being distrbuted it proabbly ok in user defaults
    [[NSUserDefaults standardUserDefaults] setValue:self.code.text forKey:@"code"];
    
}



@end
