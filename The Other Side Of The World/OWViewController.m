#import "RegExCategories.h"
#import "OWViewController.h"

#import "Reachability.h"
#import "TRAutoComplete/TRAutocomplete.h"

#import "TheFarSide-Swift.h"


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[UIDevice currentDevice] respondsToSelector:@selector(systemVersion)] && [[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

CLLocationManager *locationManager;

@implementation OWViewController

NSMutableArray* onLoadBlocks;

GMSCameraPosition* cameraToBe;
NSString* toBeInAddressBox;

//MKMapView *map;
//GMSMapView *map;

BOOL reloading;

BOOL isInitalized;

BOOL foundLocationAreadySoDontStartProgressIndicator;
BOOL stillFadingOutDataSoDontStartProgressIndicator;
BOOL gotDataSoDontStartAnything;
BOOL lookingForLocationSoDontDeallocateLocationManager;
BOOL tappedCancelButtonSoDontFindFarSide;
BOOL findingLand;

BOOL justRequestedLocationAccess;

NSMutableData *landServerResponseData;

GMSMarker *marker;

double landLat;
double landLng;

double previouslyLoadedLat;
double previouslyLoadedLng;

NSString *address;
NSString *city;

NSString *startingAddress;
NSString *startingCity;

OWUtilities *utilities;

double startingLat;
double startingLng;
CLLocationManager *locationManager;
GMSCameraPosition *test;

NSThread		*otherSideFinderThread;
otherSideFinder *otherSideFinderObject;

//UIBarButtonItem *stopButton;
//UIBarButtonItem *refreshButton;

UIBarButtonItem         *activityIndicatorBarButtonItem;
UIActivityIndicatorView *activityIndicator;

UIBarButtonItem *cancelTypingButton;

Reachability *reachabilityObject;

OWAutocompleteView *autocompleteView;

NSLayoutConstraint *navigationBarConstraint;


//UISegmentedControl *stylePicker;
UIActionSheet *infoPanel;


- (instancetype)init {
	
	// single equals sign is not a typo
	if ( self = [super init] ) [self realInit];
		return self;
}

- (void)realInit {
		
	//in this case, 1000 means "no value".
	previouslyLoadedLat = 1000;
	previouslyLoadedLng = 1000;
	
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	
	activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	
	self.restorationIdentifier = NSStringFromClass([self class]);
	
	isInitalized = true;
	
	onLoadBlocks = [NSMutableArray new];
	}


- (void)allocateLocationManager {
	locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    locationManager.delegate = self;
}

- (void)viewDidLoad {
	
	if (!isInitalized) [self realInit];
	
	[super viewDidLoad];
	/*coordsDisplay		.alpha = 0;
	whereItIs		    .alpha = 0;
	coordsDisplayForLand.alpha = 0;
	addressDisplay		.alpha = 0;*/
	
    utilities = [[OWUtilities alloc] initWithDelagate:self];
    reloading = NO;
	
    
	[self allocateLocationManager];
	self.textField.delegate = self;
	
	self.map.settings.compassButton = YES;
	self.map.myLocationEnabled = YES;
	self.map.padding = UIEdgeInsetsMake(64, 0, 44, 0);
	self.map.delegate = self;
	
	self.stopButton.enabled = NO;
	
	if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) self.locationButton.enabled = NO;
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		navigationBarConstraint = [NSLayoutConstraint constraintWithItem:self.navigationBar
															   attribute:NSLayoutAttributeHeight
															   relatedBy:NSLayoutRelationEqual
																  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f
																constant:64];
		[self.navigationBar addConstraint:navigationBarConstraint];
	 }
	
	reachabilityObject = [Reachability reachabilityForInternetConnection];
	[self checkInternetStatus:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkInternetStatus:) name:kReachabilityChangedNotification object:nil];
	[reachabilityObject startNotifier];
	
	autocompleteView = [[OWAutocompleteView alloc] initWithTextField:self.textField parentView:self.view];
	
	autocompleteView.tableView.separatorColor = [UIColor lightGrayColor];
	autocompleteView.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"what you can do"
	message:@"You can find the farthest place from yourself, or anywhere you know of! "
							  "just tap the location button, press and hold your finger on the map, or type an address into the box.\n"
							  "To find out stuff about  this place, tap the share button in the corner."
	delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:	nil];
		[alert show];
	}
	
	if (cameraToBe) _map.camera = cameraToBe;
	if (toBeInAddressBox) _textField.text = toBeInAddressBox;
	
	if (previouslyLoadedLat != 1000 && previouslyLoadedLng != 1000) {
		marker = [[GMSMarker alloc] init];
		marker.position = CLLocationCoordinate2DMake(landLat, landLng);
		if      (startingCity    != nil) marker.snippet = [NSString stringWithFormat:@"the farthest land from %@", startingCity];
		else if (startingAddress != nil) marker.snippet = [NSString stringWithFormat:@"the farthest land from %@", startingAddress];
		
		marker.appearAnimation = kGMSMarkerAnimationNone;
		marker.map = self.map;
		
		_shareButton.enabled = YES;
	}
	
	for (void (^block)() in onLoadBlocks) {
		block();
	}
	
	[self setViewRestorationIds];
}

- (void)setViewRestorationIds {
	_textField.restorationIdentifier = @"address field";
}

static NSString* startingLatKey = @"startingLat";
static NSString* startingLngKey = @"startingLng";

static NSString* miscDataKey = @"miscData";
static NSString* mapCameraKey = @"mapCamera";
static NSString* addressBoxKey = @"addressBox";


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];
	
	[coder encodeDouble:startingLat forKey:startingLatKey];
	[coder encodeDouble:startingLng forKey:startingLngKey];
	[coder encodeObject:OWMiscellaneousData.sharedData forKey:miscDataKey];
	
	[coder encodeObject:[[OWCameraPositionContainer alloc] initWithContained:_map.camera] forKey:mapCameraKey];
	
	[coder encodeObject:_textField.text forKey:addressBoxKey];
}
- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
	
	startingLat = [coder decodeDoubleForKey:startingLatKey];
	startingLng = [coder decodeDoubleForKey:startingLngKey];
	previouslyLoadedLat = startingLat;
	previouslyLoadedLng = startingLng;
	OWMiscellaneousData.sharedData = [coder decodeObjectForKey:miscDataKey];
	
	OWMiscellaneousData* data = OWMiscellaneousData.sharedData;
	landLat = [data.landLat doubleValue];
	landLng = [data.landLng doubleValue];
	address = data.address;
	city = data.locality;
	
	cameraToBe = ((OWCameraPositionContainer *)[coder decodeObjectForKey:mapCameraKey]).contained;
	
	toBeInAddressBox = [coder decodeObjectForKey:addressBoxKey];
	
}




- (void)checkInternetStatus:(NSNotification *)notice {
	NetworkStatus internetStatus = [reachabilityObject currentReachabilityStatus];
	if (internetStatus == NotReachable) [self updateInternetStatusInfo:NO];
	else								[self updateInternetStatusInfo:YES];
}

- (void) updateInternetStatusInfo:(BOOL)connected {
	if (connected) {
		self.locationButton.enabled = YES;
		self.textField.enabled = YES;
		[OWUtilities fadeElement:self.notConnectedToInternetLabel to:0 withDuration:.3];
	}
	else {
		self.locationButton.enabled = NO;
		self.textField.enabled = NO;
		[OWUtilities fadeElement:self.notConnectedToInternetLabel to:1 withDuration:.3];
	}
}

-(void) loadData {
	
	[self showProgressIndicator];
	
	//self.refreshOrCancelButton.
	//self.progressIndicator.hidden = NO;
	//self.progressIndicator.progress = initalProgress;
	if (locationManager == nil) [self allocateLocationManager];
	
	CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
	
	if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && (
															 authorizationStatus == kCLAuthorizationStatusNotDetermined ||
															 authorizationStatus == kCLAuthorizationStatusDenied)) {
		justRequestedLocationAccess = YES;
		[locationManager requestWhenInUseAuthorization];
	}

	if ([CLLocationManager locationServicesEnabled]) {
		
		foundLocationAreadySoDontStartProgressIndicator = NO;
		gotDataSoDontStartAnything						= NO;
		
		lookingForLocationSoDontDeallocateLocationManager = YES;
		[locationManager startUpdatingLocation];
	}
	else {
		[self locationFindingFailed:YES];
	}
}

- (void)didReceiveMemoryWarning {
	//locationManager = nil;
	
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	if (justRequestedLocationAccess) {
		justRequestedLocationAccess = NO;	
		[self loadData];
	}
}

- (void)locationFindingFailed:(BOOL)aboutLocationServices {
	
	[self hideProgressIndicator];
	//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Determine Location" message:@"please enter your address, city, or zip code to continue" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	//alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	NSString* title = nil;
	NSString* body = nil;
	if (!aboutLocationServices) title = @"Cannot Determine Location";
	else {
		title = @"Location Services Disabled";
		body = @"Turn on location services in Settings > Privacy to use this feature.";
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alert show];
}

- (void)farSideFindingFailed {
	[self hideProgressIndicator];
	NSString *message;
	if ([reachabilityObject currentReachabilityStatus] == NotReachable) message = @"You must be connected to the internet";
	else message = @"";
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not find the Far Side" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	if (findingLand) [self stop:nil];

}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (error.code == kCLErrorDenied) [self locationFindingFailed:YES];
	if (error.code == kCLErrorLocationUnknown || error.code == kCLErrorHeadingFailure) [self locationFindingFailed:NO];
	
	
}

- (void)loadDataWithLocation:(id)locationOrAddress tappedOnMap:(BOOL)tappedOnMap {
	
	if (findingLand) {
		[self stop:nil];
	}
	
	void (^doStuff)(double, double) = ^(double newlat, double newlng) {
		
		//float newlat = location.coordinate.latitude;
		//float newlng = location.coordinate.longitude;
		
		newlat = -newlat;      newlng = newlng - 180;
		
		//    if (newlat < -90 )  {newlat += 180;}
		//    if (newlat >  90 ) {newlat -= 180;}
		
		if (newlng < -180) {newlng += 360;}
		if (newlng >  180) {newlng -= 360;}
		
		
		
		
		/*if (!stillFadingOutDataSoDontStartProgressIndicator) {
			[self.locationProgressIndicator stopAnimating ];
			[self.upperProgressIndicator    startAnimating];
		}*/
		
		startingLat = newlat;   startingLng = newlng;
		
		/*if (reloading) UIView.AnimationBeginsFromCurrentState = YES;
		[utilities fadeElement:self.coordsDisplay to:1 withDuration:1];
		self.coordsDisplay.text = [OWUtilities displayCoords:lat lng:lng];*/
		
		if (self.calculateLandLocally) {
			
			NSNumber *objectLat = [NSNumber numberWithFloat:newlat];
			NSNumber *objectLng = [NSNumber numberWithFloat:newlng];
			
			/*NSArray *objectsToSend = [NSArray arrayWithObjects:
			 objectLat,
			 objectLng,
			 ^(NSDictionary *stuff) {
			 [self displayStuff:stuff];
			 },
			 nil];*/
			
			
			NSArray *(^blockToSend)(NSDictionary* stuff) = ^(NSDictionary *stuff) {
				if ([stuff objectForKey:@"get values"]) {
					return [NSArray arrayWithObjects:objectLat, objectLng, nil];
				}
				else if ([stuff objectForKey:@"progress"] != nil) {
					//float something = [[stuff objectForKey:@"progress"] floatValue];
					//[self.progressIndicator setProgress:[[stuff objectForKey:@"progress"] floatValue] animated:YES];
					
					return [NSArray new];
				}
				else if (stuff[@"error"]) {
					[self performSelectorOnMainThread:@selector(farSideFindingFailed) withObject:nil waitUntilDone:NO];
					return [NSArray new];
				}
				else {
					[self performSelectorOnMainThread:@selector(displayStuff:) withObject:stuff waitUntilDone:YES];
					return [NSArray new];
				}
			};
			
			otherSideFinderObject = [otherSideFinder new];
			otherSideFinderThread = [[NSThread alloc] initWithTarget:otherSideFinderObject selector:@selector(startFinding:) object:blockToSend];
			[otherSideFinderThread start];
			//[finder startFinding:objectsToSend];
			//[self displayStuff:[NSDictionary dictionaryWithObjectsAndKeys:0, @"lat", 0, @"lng", nil]];
		}
		else {
			[OWUtilities ignorableProblemAlert];
			/*NSString *urlString = [NSString stringWithFormat:@"http://localhost/~max/ow.php?lat=%f&lng=%f", startingLat, startingLng];
			
			NSURL *url = [NSURL URLWithString:urlString];
			NSURLRequest *request = [ NSURLRequest requestWithURL: url ];
			[NSURLConnection sendAsynchronousRequest:request queue:nil completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
				
				if (connectionError) {
					[self farSideFindingFailed];
				}
				else {
					gotDataSoDontStartAnything = YES;
					
					
					
					NSError *error = nil;
					NSDictionary *jsonReturned = [NSJSONSerialization
												  JSONObjectWithData:data
												  options:0
												  error:&error];
					[self displayStuff:jsonReturned];
					
				}
			}];*/
			
		}
	};
	
	
	if ([locationOrAddress isMemberOfClass:[CLLocation class]]) {
		
		
		CLLocation *location = locationOrAddress;
		//if (tappedOnMap) {
			OWSteppedGeocoder *geocoder = [OWSteppedGeocoder new];
			[geocoder reverseGeocodeAndPackageWithLat:location.coordinate.latitude lng:location.coordinate.longitude success:^(NSDictionary *stuff) {
				
				startingAddress            = stuff[@"place"][@"address"];
				startingCity			   = stuff[@"place"][@"city"];
				NSString *toBeInAddressBox = stuff[@"place"][@"city"];
				
				
				if (toBeInAddressBox == nil || [toBeInAddressBox isEqualToString:@""] || self.map.camera.zoom > 11) toBeInAddressBox = startingAddress;
				
				[self.textField performSelectorOnMainThread:@selector(setText:) withObject:toBeInAddressBox waitUntilDone:NO];
				if (!findingLand) {
					[marker performSelectorOnMainThread:@selector(setSnippet:) withObject:[NSString stringWithFormat:@"the farthest land from %@", toBeInAddressBox] waitUntilDone:NO];
				}
			} failure:^(NSError *error) {
				//do nothing
			}];
		//}
		/*else {
			startingAddress = @"you";
			self.textField.text = @"My Location";
		}*/
		doStuff(location.coordinate.latitude, location.coordinate.longitude);
	}
	else if (![locationOrAddress isEqualToString:@""]) {
		startingAddress = locationOrAddress;
		
		OWSteppedGeocoder *geocoder = [OWSteppedGeocoder new];
		[geocoder geocode:locationOrAddress failure:^(id reason) {
			[self farSideFindingFailed];
		}
		success:^(double lat, double lng) {
			previouslyLoadedLat = lat;
			previouslyLoadedLng = lng;
			doStuff(lat, lng);
		}];
		
	}
	else return;
	
	self.stopButton.enabled = YES;
	findingLand = YES;
	
	//add activity indicator
	[self showProgressIndicator];
	
	
	//self.progressIndicator.hidden = NO;
	//[self.progressIndicator setProgress:progressBeforeStartFinding animated:YES];
	
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	
	foundLocationAreadySoDontStartProgressIndicator = YES;
	
	
    /*lat = roundNumber([[NSDecimalNumber alloc] numberWithFloat:locationManager.location.coordinate.lat]);
     lng = roundNumber([[NSDecimalNumber alloc] numberWithFloat:locationManager.location.coordinate.lng]);*/
    [locationManager stopUpdatingLocation];
    lookingForLocationSoDontDeallocateLocationManager = NO;

    CLLocation *location = [locations lastObject];
    	
	[self loadDataWithLocation:location tappedOnMap:NO];
    
    
    
    //self.whereItIs.text = request;

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    landServerResponseData = [[NSMutableData alloc] init];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [landServerResponseData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //self.whereItIs.text = [error localizedDescription];
[self farSideFindingFailed];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	gotDataSoDontStartAnything = YES;
    // Once this method is invoked, "landServerResponseData" contains the complete result
    //NSString *textReturned = [[NSString alloc] initWithData:landServerResponseData encoding:NSUTF8StringEncoding];
    
    NSDictionary *jsonReturned;
    if(NSClassFromString(@"NSJSONSerialization")) {
        NSError *error = nil;
        jsonReturned = [NSJSONSerialization
                     JSONObjectWithData:landServerResponseData
                     options:0
                     error:&error];
		[self displayStuff:jsonReturned];
        
        if(error) {}
        
    }
    else {
        
    }
    
	
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
	if ([reachabilityObject currentReachabilityStatus] != NotReachable) {
		[self loadDataWithLocation:[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] tappedOnMap:YES];
	}
}

- (void)displayStuff:(NSDictionary *)stuff {
	
	self.stopButton.enabled = NO;
	
	//remove activity indicator
	[self hideProgressIndicator];
	/*float duration = 1 - self.progressIndicator.progress;
	
	[UIView animateWithDuration:duration animations:^{self.progressIndicator.progress = 1;} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.3  animations:^{self.progressIndicator.alpha    = 0;} completion:^(BOOL finished) {
			self.progressIndicator.hidden = YES;
			self.progressIndicator.alpha = 1;
			self.progressIndicator.progress = 0;
		}];
	}];*/
	
	//NSDictionary *place = [stuff objectForKey:@"place"];
    
    //NSString *landLatString = [stuff objectForKey:@"lat"];
    //NSString *landLngString = [stuff objectForKey:@"lng"];
    
   // address        = [place objectForKey:@"address"];
    //NSString *type = [place objectForKey:@"type"   ];
    //city           = [place objectForKey:@"city"   ];
    
       
    //landLat = [[NSDecimalNumber decimalNumberWithString:landLatString] doubleValue];
    //landLng = [[NSDecimalNumber decimalNumberWithString:landLngString] doubleValue];
	landLat = [[stuff objectForKey:@"lat"] doubleValue];
	landLng = [[stuff objectForKey:@"lng"] doubleValue];
	
	if (marker != nil) marker.map = nil;
	
	self.map.camera = [GMSCameraPosition cameraWithLatitude:startingLat longitude:startingLng zoom:9];
	
	/*[[OWGoogleMapsDelegateToCallback new] animateZoom:1 mapView:self.map completion:^{
		[[OWGoogleMapsDelegateToCallback new] panTo:CLLocationCoordinate2DMake(landLat, landLng) mapView:self.map completion:^{
			[[OWGoogleMapsDelegateToCallback new] animateZoom:10 mapView:self.map completion:^{*/
	self.map.camera = [GMSCameraPosition cameraWithLatitude:landLat longitude:landLng zoom:10];
	
	marker = [[GMSMarker alloc] init];
	marker.position = CLLocationCoordinate2DMake(landLat, landLng);
	if      (startingCity    != nil) marker.snippet = [NSString stringWithFormat:@"the farthest land from %@", startingCity];
	else if (startingAddress != nil) marker.snippet = [NSString stringWithFormat:@"the farthest land from %@", startingAddress];
	
	marker.appearAnimation = kGMSMarkerAnimationPop;
	marker.map = self.map;
			/*}];
		}];
	}];*/
	findingLand = NO;
	
	OWMiscellaneousData.sharedData.landLat = [NSNumber numberWithDouble:landLat];
	OWMiscellaneousData.sharedData.landLng = [NSNumber numberWithDouble:landLng];
	
	UIBarButtonItem *shareButton = self.toolbar.items.lastObject;
	shareButton.enabled = YES;
	
	if (stuff[@"place"] != nil) {
		OWMiscellaneousData.sharedData.address = stuff[@"place"][@"address"];
	}
	else {
		OWMiscellaneousData.sharedData.locality = OWMiscellaneousData.sharedData.address = nil;
		[[OWSteppedGeocoder new] reverseGeocodeAndPackageWithLat:landLat lng:landLng success:^(NSDictionary *stuff) {
			
			[NSObject runClosureInMainThread:^() {
				OWMiscellaneousData.sharedData.address = stuff[@"place"][@"address"];
				
				NSString *city = stuff[@"place"][@"city"];
				if (city != nil && ![city isEqualToString:@""]) OWMiscellaneousData.sharedData.locality = city;
				else											OWMiscellaneousData.sharedData.locality = nil;
			}];
		} failure:^(id error) {}];
	}
	
}

- (IBAction)refresh:(id)sender {

	if (previouslyLoadedLat != 1000) {
		[self loadDataWithLocation:[[CLLocation alloc] initWithLatitude:previouslyLoadedLat longitude: previouslyLoadedLng] tappedOnMap:NO];
	}
	else {
		[self loadData];
	}
}

- (IBAction)loadLocation:(id)sender {
	[self loadData];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (!tappedCancelButtonSoDontFindFarSide) [self loadDataWithLocation:textField.text tappedOnMap:NO];
	else tappedCancelButtonSoDontFindFarSide = NO;
	
	[self.mainNavigationItem setRightBarButtonItem:self.locationButton animated:YES];
	[self.view sendSubviewToBack: self.dismissTextFieldButton];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	if (cancelTypingButton == nil) {
		cancelTypingButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard:)];
	}
	
	[self.view sendSubviewToBack:self.map];
	
	[self.mainNavigationItem setRightBarButtonItem:cancelTypingButton animated:YES];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (IBAction)dismissKeyboard:(id)sender {
	tappedCancelButtonSoDontFindFarSide = YES;
	[self.textField resignFirstResponder];
}

- (IBAction)showIn:(id)sender {
    // new option: roam to rio?
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Show In…" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Apple Maps", @"Google Maps", @"Search Google", @"Search Wikipedia", nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
       //[sheet showFromRect: infoButton.frame inView:infoButton.superview animated: YES];
    }
    else {
        [sheet showInView:self.view];
    }
    
    
}

- (IBAction)stop:(id)sender {
	findingLand = NO;
	
	[self hideProgressIndicator];
	[locationManager stopUpdatingLocation];
	
	[otherSideFinderThread cancel];
	//[otherSideFinderObject performSelector:@selector(exit) onThread:otherSideFinderThread withObject:nil waitUntilDone:YES];
	//otherSideFinderThread = nil;
	//otherSideFinderObject = nil;
}

- (void)showProgressIndicator {
	self.stopButton.enabled = YES;
	if (![activityIndicator isAnimating]) {
		[activityIndicator startAnimating];
		
		NSMutableArray *items = [self.mainNavigationItem.leftBarButtonItems mutableCopy];
		if (items == nil) items = [NSMutableArray new];
		[items insertObject:activityIndicatorBarButtonItem atIndex:0];
		[self.mainNavigationItem setLeftBarButtonItems:items animated:YES];
	}
}
- (void)hideProgressIndicator {
	self.stopButton.enabled = NO;
	[activityIndicator stopAnimating];
	NSMutableArray *items = [self.mainNavigationItem.leftBarButtonItems mutableCopy];
	if (items.count != 0) [items removeObjectAtIndex:0]; 
	[self.mainNavigationItem setLeftBarButtonItems:items animated:YES];

}

- (IBAction)showInfo:(id)sender {
		UIButton *infoButton = sender;
	
	infoPanel = [[UIActionSheet alloc] initWithTitle:@"  " delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles: nil];
	
	UISegmentedControl *stylePicker = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Standard", @"Satellite", @"Terrain", nil]];
	
	if (self.map.mapType == kGMSTypeNormal ) stylePicker.selectedSegmentIndex = 0;
	if (self.map.mapType == kGMSTypeHybrid ) stylePicker.selectedSegmentIndex = 1;
	if (self.map.mapType == kGMSTypeTerrain) stylePicker.selectedSegmentIndex = 2;
	
	
		[stylePicker addTarget:self action:@selector(changeMapType:) forControlEvents:UIControlEventValueChanged];
	
	//[self.view addSubview:stylePicker];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[infoPanel showFromRect: infoButton.frame inView:infoButton.superview animated: YES];
	}
	
	else [infoPanel showInView:self.view];
	stylePicker.frame = CGRectMake(infoPanel.frame.origin.x + 30, infoPanel.frame.origin.y + 10, infoPanel.bounds.size.width - 60, 30);
	[self.view addSubview:stylePicker];
	
	

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//user has just entered their location.
	[self loadDataWithLocation:[alertView textFieldAtIndex:0].text tappedOnMap:NO];
}

- (IBAction)changeMapType:(UISegmentedControl *)stylePicker {
	
	
	int mapStyleIndex = stylePicker.selectedSegmentIndex;
	if (mapStyleIndex == 0) self.map.mapType = kGMSTypeNormal;
	if (mapStyleIndex == 1) self.map.mapType = kGMSTypeHybrid;
	if (mapStyleIndex == 2) self.map.mapType = kGMSTypeTerrain;
	
	[infoPanel dismissWithClickedButtonIndex:-1 animated:YES];
}

/*- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	return;
	// user just selected what to show (show in button was tapped)
	if (buttonIndex == 0) {
		//open apple map
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/?q=&ll=%f,%f", landLat, landLng]];
		[[UIApplication sharedApplication] openURL:url];
	}
	else if (buttonIndex == 1) {
		//open google map
		
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?center=%f,%f",landLat, landLng]];
		
		if (![[UIApplication sharedApplication] canOpenURL:url]) {
			
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.google.com/maps/@%f,%f,10z", landLat, landLng]]];
		}
		else {
			[[UIApplication sharedApplication] openURL:url];
		}
	}
	else if (buttonIndex == 2) {
		//search google
		[UIApplication.sharedApplication openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", [city stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
	}
	else if (buttonIndex == 3) {
		//search wikipedia
		[UIApplication.sharedApplication openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/wiki/Special:Search?search=%@", [city stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
	}
	
}*/

- (IBAction)share:(UIBarButtonItem *)sender {
	NSString *vcardString = [NSString stringWithFormat:@"BEGIN:VCARD\n"
							 "VERSION:3.0\n"
							 "	  N:;Shared Location;;;\n"
							 "	 FN:Shared Location\n"
							 "item1.URL;type=pref:http://maps.apple.com/?ll=%f,%f\n"
							 "item1.X-ABLabel:map url\n"
							 "END:VCARD", landLat, landLng];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0]; // Get documents directory
	
	NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"location.loc.vcf"];
	[vcardString writeToFile:filePath
				  atomically:NO encoding:NSUTF8StringEncoding error:nil];
	
	NSURL *url =  [NSURL fileURLWithPath:filePath];
	
	UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:@[
								[OWSearchWikipediaShareOption  new],
								[OWSearchGoogleShareOption     new],
								[OWShowInAppleMapsShareOption  new],
								[OWShowInGoogleMapsShareOption new]
								]];
	/*shareSheet.excludedActivityTypes = @[
										 UIActivityTypeAssignToContact,
										 UIActivityTypeSaveToCameraRoll
										 ];*/
	
	if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
	{
		[self presentViewController:shareSheet animated:YES completion:nil];
	}
	else {
		UIPopoverController *popControl = [[UIPopoverController alloc] initWithContentViewController:shareSheet];
		[popControl presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
		if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
			navigationBarConstraint.constant = 44;
		}
		else {
			navigationBarConstraint.constant = 64;
		}
	}
	[super willRotateToInterfaceOrientation:orientation duration:duration];
}

- (BOOL)calculateLandLocally {
	
	/*if ([reachabilityObject currentReachabilityStatus] == ReachableViaWiFi) return YES;
	else  {
		if (NSClassFromString(@"CTTelephonyNetworkInfo")
			&& [CTTelephonyNetworkInfo instancesRespondToSelector:@selector(currentRadioAccessTechnology)]) {
			
			NSString *currentRadioAccessTechnology = [CTTelephonyNetworkInfo new].currentRadioAccessTechnology;
			
			if (currentRadioAccessTechnology == CTRadioAccessTechnologyGPRS
				|| currentRadioAccessTechnology == CTRadioAccessTechnologyEdge) {
				return NO;
			}
		}
	}
	//why not?*/
	return YES;
}



/*- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	
}*/


@end


@implementation debugThread

- (void)debug:(void (^)())callback {
	callback();
	}
@end







