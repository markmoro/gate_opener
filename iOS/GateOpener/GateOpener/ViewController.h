//
//  ViewController.h
//  GateOpener
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController {
    CLLocationManager * locationManager;
    CLLocation* currentLocation;
    CLLocationDistance lastDistance;
    BOOL regionCheck;
}

@property (strong,nonatomic) CLCircularRegion *geoRegion;

-(IBAction)open:(id)sender;
-(IBAction)openWhenNear:(id)sender;
- (void)startStandardUpdates;
@end
