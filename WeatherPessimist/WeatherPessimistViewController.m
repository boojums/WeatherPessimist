//
//  WeatherPessimistViewController.m
//  WeatherPessimist
//
//  Created by Cristina Luis on 8/17/12.
//  Copyright (c) 2012 Cristina Luis. All rights reserved.
//

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //macro for background queue
//#define kJSONStringURL @"/Users/csluis/Code/iOS/WeatherPessimist/weatherdata.json"
#define kJSONStringURL @"http://free.worldweatheronline.com/feed/weather.ashx?q=85711&format=json&num_of_days=2&key=be45236e98154106120808&includeLocation=yes"

#define kJSONStringURLBeginning @"http://free.worldweatheronline.com/feed/weather.ashx?q="
#define kJSONStringURLEnd @"&format=json&num_of_days=2&key=be45236e98154106120808&includeLocation=yes"


#import "WeatherData.h"
#import "WeatherPessimistViewController.h"

#pragma mark -
#pragma mark NSDictionary categories for JSON support
@interface NSDictionary(JSONCategories)

+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress;

@end

@implementation NSDictionary(JSONCategories)

+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress
{
    NSData* data = [NSData dataWithContentsOfURL:
                    [NSURL URLWithString:urlAddress]];
    if(data == nil) {
        NSLog(@"failed to load data with url");
        return nil;
    }
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}

@end

#pragma - 
#pragma WeatherPessimistViewController interface
@interface WeatherPessimistViewController ()

@end

@implementation WeatherPessimistViewController
@synthesize zipField, currentLabel, nextDayLabel, twoDayLabel, currentImage;
@synthesize scrollView, pageControl;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //first check to see when last update was - info is cached
    //check if connected to internet
    //if needed, use cached information first
    //if time to refresh, use location finder or default zip code
    
    //create background queue, fetch data in the background based on last zip code
    dispatch_async(kBgQueue, ^{
        NSDictionary *json = [NSDictionary dictionaryWithContentsOfJSONURLString:kJSONStringURL];        [self performSelectorOnMainThread:@selector(fetchedData:)                                                                                                                                  withObject:json waitUntilDone:YES]; //fetchedData must be on main thread b/c UI stuff
    });
    
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
    
    //set single tap recognizer
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    [scrollView addGestureRecognizer:singleTap];
    
}

//called once data has been retrieved from web - should be bg thread if large file to be parsed
- (void)fetchedData:(NSDictionary *)responseData {
    
    NSDictionary *data = [responseData objectForKey:@"data"];
    if ((data == NULL) || ([data objectForKey:@"error"])){
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"No weather!"
                              message:@"We're having trouble getting your forecast!"
                              delegate:nil
                              cancelButtonTitle:@"Bummer"
                              otherButtonTitles:nil, nil];
        [alert show];
        zipField.text = @"";
        return;
    }
       

    //need proper construction/destruction of weatherData objects
    WeatherData *weatherData = [[WeatherData alloc] initWithData:data];

    //update labels with weatherData pessimized data -- array for forecasted data?
    currentLabel.numberOfLines = 0; 
    currentLabel.text = [NSString stringWithFormat:@"%@\n%d°F\n%dmph", weatherData.description, weatherData.tempF, weatherData.wind_mph];
    
    nextDayLabel.text = [NSString stringWithFormat:@"Tomorrow will be %@°F", weatherData.forecastMaxTempsF[0]];
   
    twoDayLabel.text = [NSString stringWithFormat:@"The next day will be %@°F", weatherData.forecastMaxTempsF[1]];
    
    currentImage.image = [UIImage imageNamed:weatherData.imageName];
    

}

- (IBAction)buttonPushed {
    [zipField resignFirstResponder];       //put keyboard away
    NSString *toScan = zipField.text;     //add support for city, state also?
    
    // strip zipField text down to just decimal digits
    NSScanner *s = [NSScanner scannerWithString:toScan];
    NSString *zipString;
    BOOL foo = [s scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&zipString];
    
    // check for proper length
    if((!foo) || ([zipString length] != 5)) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Invalid zip code"
                              message:@"Try a real zip code."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil, nil];
        [alert show];
        [zipField becomeFirstResponder];
        return;
    }
    
    // check for positive value
    NSNumber *zipNum = [NSNumber numberWithInt:[zipString intValue]];
    if ([zipNum intValue] <= 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Invalid zip code"
                              message:@"Try a real zip code."
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil, nil];
        [alert show];
        [zipField becomeFirstResponder];
        return;
    }
    
    //need to check defaults for last time updated and which zip was used
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *lastZipString = [prefs stringForKey:@"enteredZip"]; //get last zip code
    NSDate *then = (NSDate *)[prefs objectForKey:@"lastUpdate"]; //get last time
    
    //figure out how much time has elapsed
    NSTimeInterval elapsed;
    if (then) {
        elapsed = [then timeIntervalSinceNow];
    } else {
        elapsed = 0;
    }
    
    //make sure 15 minutes (900 seconds) has elapsed and it's not the same new zip code
    if ((elapsed > -900) && ([lastZipString isEqualToString:zipString])) {
        return; // no need to fetch new data
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@%@",kJSONStringURLBeginning, zipString, kJSONStringURLEnd];
    
    NSDictionary *result = [NSDictionary dictionaryWithContentsOfJSONURLString:urlString];
    [self fetchedData:result];
    
    //store currently fetched data - why not store all of it?
    [prefs setObject:[NSDate date] forKey:@"lastUpdate"];
    [prefs setObject:zipNum forKey:@"enteredZip"];
    [prefs synchronize];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	if (!pageControlBeingUsed) {
		// Switch the indicator when more than 50% of the previous/next page is visible
		CGFloat pageWidth = self.scrollView.frame.size.width;
		int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
		self.pageControl.currentPage = page;
	}
}

- (IBAction)changePage {
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlBeingUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlBeingUsed = NO;
}

- (BOOL)needToUpdate {
  //needs to be written
    return 1;
}

- (void)viewDidUnload {
    [self setZipField:nil];
    [self setCurrentLabel:nil];
    [self setNextDayLabel:nil];
    [self setTwoDayLabel:nil];
    self.scrollView = nil;
    self.pageControl = nil;

    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    //CGPoint touchPoint=[gesture locationInView:scrollView];
    [zipField resignFirstResponder];
}

-(IBAction)backgroundTouched:(id)sender {
    [zipField resignFirstResponder];
}

-(IBAction)textFieldReturn:(id)sender {
    [sender resignFirstResponder];
}

@end
