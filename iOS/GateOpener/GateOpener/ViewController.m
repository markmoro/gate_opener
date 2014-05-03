//
//  ViewController.m
//  GateOpener
//
//

#import "ViewController.h"
#include <CommonCrypto/CommonHMAC.h>
#include "SetupViewController.h"


// Change enpoint to correct IP
#define ENDPOINT_MP @"http://192.168.1.177/"
#define TOKEN_MP @"token"
#define OPEN_MP @"open"

@interface ViewController ()

@end

@implementation ViewController


-(NSString*)endpoint {
  return ENDPOINT_MP;
}

-(NSURL*)tokenRequest {
    return [NSURL URLWithString:[[self endpoint] stringByAppendingString:TOKEN_MP]];
}

-(NSURL*)openRequest {
    return [NSURL URLWithString:[[self endpoint] stringByAppendingString:OPEN_MP]];

}

-(NSString*)code {
    return [[NSUserDefaults standardUserDefaults]  valueForKey:@"code"];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
        regionCheck =NO;
    [self startStandardUpdates];

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)stopRegionChecking {
    regionCheck =NO;
    
    
    // Use below code if usinf the iOS region check
 /*   if(locationManager && self.geoRegion)
        [locationManager stopMonitoringForRegion:self.geoRegion]; */
}


-(void)startRegionChecking {
    // The comment code below has some issues on smalle distance.  I suspect this is to save power.
    /*
    CLLocationDegrees latitude = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"latitude"];
    CLLocationDegrees longitude = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"longitude"];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    CLLocationDistance regionRadius = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"radius"];
    
    // Create the geographic region to be monitored.
    self.geoRegion = [[CLCircularRegion alloc]
                      initWithCenter:centerCoordinate
                      radius:regionRadius
                      identifier:@"TEST_COORD_ID"];
    [locationManager startMonitoringForRegion:self.geoRegion];
    */
    regionCheck =YES;
    lastDistance = -1;
    
}

- (void)startStandardUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    locationManager.distanceFilter = 1; // meters
    
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
  //  [self open:self];
   // [self stopRegionChecking];
    
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // If it's a relatively recent event, turn off updates to save power.
    
    
    CLLocationDegrees latitude = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"latitude"];
    CLLocationDegrees longitude = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"longitude"];
    CLLocationDistance regionRadius = [[NSUserDefaults standardUserDefaults]  doubleForKey:@"radius"];

    CLLocation *target = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    currentLocation = [locations lastObject];


    CLLocationDistance distance = [currentLocation distanceFromLocation:target];
    NSLog(@"Distance %f",distance);
    if(regionCheck && lastDistance > regionRadius && distance < regionRadius) {
        NSLog(@"Opening ",nil);
        [self open:self];
        [self stopRegionChecking];
    }
    
    lastDistance = distance;
    
    NSDate* eventDate = currentLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              currentLocation.coordinate.latitude,
              currentLocation.coordinate.longitude);
    }

}

-(IBAction)open:(id)sender {
    if(![self code]) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                  @"Error" message:@"No Code set" delegate:self
                                                 cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        return;
    }

    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                              @"Open" message:@"Opening" delegate:self
                                             cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];

    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:[self tokenRequest]];
    
    [urlRequest setHTTPMethod:@"GET"];

    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    NSString * token = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];

    NSLog(@"Token=%@",token);

    
    NSString * digestSrc = [NSString stringWithFormat:@"%@open",token];
    const char *cKey  = [[self code] cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [digestSrc cStringUsingEncoding:NSASCIIStringEncoding];
    
    NSLog(@"%s",cKey);
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    
    NSMutableString* ho = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [ho appendFormat:@"%02x", cHMAC[i]];
    
    
    NSLog(@"Hash=%@",ho);
    

    
    urlRequest = [NSMutableURLRequest requestWithURL:[self openRequest]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[[NSString stringWithFormat:@"d=%@",ho] dataUsingEncoding:NSASCIIStringEncoding]];
    data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    token = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];

    
}

-(IBAction)openWhenNear:(id)sender {
    if( [[NSUserDefaults standardUserDefaults]  valueForKey:@"latitude"])
       [self startRegionChecking];
    else {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:
                                  @"Error" message:@"No Location set" delegate:self
                                                 cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        
    }

    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    SetupViewController *svc= [segue destinationViewController];
    svc.currentLocation = currentLocation;
    
}



@end
