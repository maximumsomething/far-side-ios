//
//  OWViewController.h
//  The Other Side Of The World
//
//  Created by Max on 6/20/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
//#import <MapKit/MapKit.h>
#import "OWUtilities.h"
//@import GoogleMaps;
#import <GoogleMaps/GoogleMaps.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>


@interface OWViewController : UIViewController <CLLocationManagerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, GMSMapViewDelegate, UITraitEnvironment, UIContentContainer> {
    
    }

- (void)realInit;




@property (retain, nonatomic) IBOutlet UIBarButtonItem    *stopButton;
@property (retain, nonatomic) IBOutlet GMSMapView         *map;
@property (retain, nonatomic) IBOutlet UITextField        *textField;
@property (retain, nonatomic) IBOutlet UIButton           *dismissTextFieldButton;
@property (retain, nonatomic) IBOutlet UISegmentedControl *mapTypeChooser;
@property (retain, nonatomic) IBOutlet UINavigationBar    *navigationBar;
@property (retain, nonatomic) IBOutlet UINavigationItem   *mainNavigationItem;
@property (retain, nonatomic) IBOutlet UIToolbar          *toolbar;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *shareButton;
//@property (retain) IBOutlet NSLayoutConstraint *navigationBarConstraint;
@property (retain, nonatomic) IBOutlet UILabel            *notConnectedToInternetLabel;
@property (retain, nonatomic) IBOutlet UIBarButtonItem    *locationButton;

@property (readonly, nonatomic) BOOL calculateLandLocally;

- (BOOL)calculateLandLocally;

- (void) loadData;
- (IBAction)refresh:        (id)sender;
- (IBAction)showIn:         (id)sender;
- (IBAction)showInfo:       (id)sender;
- (IBAction)share:          (id)sender;
- (IBAction)stop:           (id)sender;
- (IBAction)loadLocation:   (id)sender;
- (IBAction)dismissKeyboard:(id)sender;
- (IBAction)changeMapType:  (id)sender;



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

- (void)displayStuff:(NSDictionary *)stuff;

//location is either a CLLocation or a string containing an address.

//- (void)fadeFinished:(NSNumber *)animationID;

- (void)checkInternetStatus:(NSNotification *)notice;
- (void) updateInternetStatusInfo:(BOOL)connected;

- (OWViewController *)init;


@end


@interface debugThread : NSObject {
    
}
- (void)debug:(void (^) ())callback;
@end


