//
//  WeatherPessimistViewController.m
//  WeatherPessimist

/* To do list:
 - add search for location support from http://www.worldweatheronline.com/feed/search.ashx
*/

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //macro for background queue

#import "WXPData.h"
#import "WeatherPessimistViewController.h"

#pragma mark - 
#pragma WeatherPessimistViewController implementation
@implementation WeatherPessimistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.currentLocation = nil;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    if (![WXPData canConnect])
        NSLog(@"Can't connect");
    else
        NSLog(@"Can connect");
    
    //archived data should be loaded from last use. Don't fetch until asked?

    pageControlBeingUsed = NO;
    
    //check preferences for number of days to show? 
    for (int i = 0; i < 2; i++) {
        CGRect frame;
        frame.origin.x = self.scrollView.frame.size.width * i;
        frame.origin.y = 0;
        frame.size = self.scrollView.frame.size;
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * 2, self.scrollView.frame.size.height);
    
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = 2;
    
    //somehow wait for current location and update automatically -- perhaps in didUpdateToLocation
    if(self.currentLocation != nil)
        [self currentLocationSearch];

}

//could be one method using id of button to determine whether to build current location query or search
//but they are different -- no search results needed for current lcoation 
- (IBAction)currentLocationSearch
{
    NSLog(@"currentLocationSearch");
    if(![WXPData canConnect]) {
        return;
    }
    //need to check when last check was, used cached data if available
    
    NSString *query;
    if(self.currentLocation != nil){
        NSString *latitude = [NSString stringWithFormat:@"%+.2f",
                                self.currentLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%+.2f",
                                self.currentLocation.coordinate.longitude];
        query = [NSString stringWithFormat:@"%@,%@",latitude, longitude];
    } else {
        NSLog(@"No location");
    }
    
    if([self timeToUpdate:query])
    {
        weatherData = [[WXPData alloc] initWithQuery:query];
        [weatherData pessimizeData];
        [self updateLabels];
        
        //need to update to include whichever method was used last. cache entire object?
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:[NSDate date] forKey:@"lastUpdate"];
        [prefs setObject:query forKey:@"lastquery"];
        [prefs synchronize];
    }
    return;
}

- (IBAction)querySearch
{
    //should include a search for valid search possibilities
    NSLog(@"querySearch");
    NSString *query = self.searchField.text;
    [self.searchField resignFirstResponder];
        
    if([self timeToUpdate:query])
    {
        weatherData = [[WXPData alloc] initWithQuery:query];
        //check for errors
        [weatherData pessimizeData];
        [self updateLabels];

        //need to update to include whichever method was used last. cache entire object?
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:[NSDate date] forKey:@"lastUpdate"];
        [prefs setObject:query forKey:@"lastquery"];
        [prefs synchronize];
    }
    return;
 }


- (void)updateLabels
{
    //update labels with weatherData pessimized data -- array for forecasted data?
    self.currentLabel.numberOfLines = 0;
    
    NSString *description = [weatherData.pessimizedCurrentConditions objectForKey:@"description"];
    NSString *temp = [weatherData.pessimizedCurrentConditions objectForKey:@"temp_F"];
    NSString *wind = [weatherData.pessimizedCurrentConditions objectForKey:@"windspeedMiles"];
    self.currentLabel.text = [NSString stringWithFormat:@"%@\n%@°F\n%@mph", description, temp, wind];
    
    temp = [weatherData.pessimizedForecastConditions[0] objectForKey:@"tempMaxF"];
    self.nextDayLabel.text = [NSString stringWithFormat:@"Tomorrow will be %@°F", temp];
    temp = [weatherData.pessimizedForecastConditions[1] objectForKey:@"tempMaxF"];
    self.twoDayLabel.text = [NSString stringWithFormat:@"The next day will be %@°F", temp];
    
    self.currentImage.image = [UIImage imageNamed:weatherData.imageNames[0]];
    
    //needs date formatting with NSDateFormatter
    self.updatedLabel.text = [NSString stringWithFormat:@"Last Updated: %@", [NSDate date]];
}

- (BOOL)timeToUpdate:(NSString *)query
{
    //need to check defaults for last time updated and which query was used
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *lastQuery = [prefs stringForKey:@"lastQuery"];
    NSDate *lastUpdate = (NSDate *)[prefs objectForKey:@"lastUpdate"];
    
    //figure out how much time has elapsed
    NSTimeInterval elapsed;
    if (lastUpdate) {
        elapsed = [lastUpdate timeIntervalSinceNow];
    } else {
        elapsed = 0;
    }
    
    //make sure 15 minutes (900 seconds) has elapsed and it's not the same new zip code
    if ((elapsed > -900) && ([lastQuery isEqualToString:query])) {
        return NO;
    }
    
    return YES;
}


/******************************************** UI Stuff ****************************************/
- (void)scrollViewDidScroll:(UIScrollView *)sender
{
	if (!pageControlBeingUsed) {
		// Switch the indicator when more than 50% of the previous/next page is visible
		CGFloat pageWidth = self.scrollView.frame.size.width;
		int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
		self.pageControl.currentPage = page;
	}
}

- (IBAction)changePage
{
	// Update the scroll view to the appropriate page
	CGRect frame;
	frame.origin.x = self.scrollView.frame.size.width * self.pageControl.currentPage;
	frame.origin.y = 0;
	frame.size = self.scrollView.frame.size;
	[self.scrollView scrollRectToVisible:frame animated:YES];
    
	// Keep track of when scrolls happen in response to the page control
	// value changing. If we don't do this, a noticeable "flashing" occurs
	// as the the scroll delegate will temporarily switch back the page
	// number.
	pageControlBeingUsed = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    pageControlBeingUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    pageControlBeingUsed = NO;
}


//deprecated in iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

//for iOS6
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

//this causes problems with iOS5.1!
- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    //CGPoint touchPoint=[gesture locationInView:scrollView];
    [self.searchField resignFirstResponder];
}

//non-functional with a scrollview active   
-(IBAction)backgroundTouched:(id)sender
{
    [self.searchField resignFirstResponder];
}

-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark -
#pragma mark CLLocationManager delegate methods
-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation
          fromLocation:(CLLocation *)oldLocation
{
    //if(currentLocation == nil)
    self.currentLocation = newLocation;
    [self.locationManager stopUpdatingLocation];
    //NSLog(@"current latitude: %@", self.currentLocation);
    
}

-(void)locationManager:(CLLocationManager *)manager
      didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"oops!"
                                                    message:@"Can't get location information!" delegate:nil
                                          cancelButtonTitle:@"Okay"
                                          otherButtonTitles:nil, nil];
    [alert show];
    return;
}


- (void)viewDidUnload
{
    [self setSearchField:nil];
    [self setCurrentLabel:nil];
    [self setNextDayLabel:nil];
    [self setTwoDayLabel:nil];
    self.scrollView = nil;
    self.pageControl = nil;
    
    [self setUpdatedLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
@end




/*    //create background queue, fetch data in the background based on last zip code
 dispatch_async(kBgQueue, ^{
 NSDictionary *json = [NSDictionary dictionaryWithContentsOfJSONURLString:kJSONStringURL];        [self performSelectorOnMainThread:@selector(fetchedData:)                                                                                                                                  withObject:json waitUntilDone:YES]; //fetchedData must be on main thread b/c UI stuff
 });
 
 //called once data has been retrieved from web - should be bg thread if large file to be parsed
 - (void)fetchedData:(NSDictionary *)responseData {
 NSLog(@"fetchedData \n");
 
 NSDictionary *data = [responseData objectForKey:@"data"];
 if ((data == NULL) || ([data objectForKey:@"error"])){
 UIAlertView *alert = [[UIAlertView alloc]
 initWithTitle: @"No weather!"
 message:@"We're having trouble getting your forecast!"
 delegate:nil
 cancelButtonTitle:@"Bummer"
 otherButtonTitles:nil, nil];
 [alert show];
 self.zipField.text = @"";
 return;
 }
 
 weatherData = [[WXPData alloc] initWithData:data];
 if(weatherData) {
 [weatherData pessimizeData];
 }
 [self updateLabels];
 }

 
*/


/*
 //zip code checker method
 NSString *toScan = self.searchField.text;
 NSScanner *s = [NSScanner scannerWithString:toScan];
 NSString *zipString;
 BOOL foo = [s scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&zipString];
 
 if((!foo) || ([zipString length] != 5)) {
 UIAlertView *alert = [[UIAlertView alloc]
 initWithTitle:@"Invalid zip code"
 message:@"Try a real zip code."
 delegate:nil
 cancelButtonTitle:@"Ok"
 otherButtonTitles:nil, nil];
 [alert show];
 [self.searchField becomeFirstResponder];
 return;
 }
 
 NSNumber *zipNum = [NSNumber numberWithInt:[zipString intValue]];
 if ([zipNum intValue] <= 0) {
 UIAlertView *alert = [[UIAlertView alloc]
 initWithTitle:@"Invalid zip code"
 message:@"Try a real zip code."
 delegate:nil
 cancelButtonTitle:@"Ok"
 otherButtonTitles:nil, nil];
 [alert show];
 [self.searchField becomeFirstResponder];
 return;
 }
 query = zipString;
*/
