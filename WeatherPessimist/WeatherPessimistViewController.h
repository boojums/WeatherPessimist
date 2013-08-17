//
//  WeatherPessimistViewController.h
//  WeatherPessimist
//
//  Created by Cristina Luis on 8/17/12.
//  Copyright (c) 2012 Cristina Luis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface WeatherPessimistViewController : UIViewController <UIScrollViewDelegate, CLLocationManagerDelegate>
{
    BOOL pageControlBeingUsed;
    WXPData *weatherData;
}

@property (strong, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) IBOutlet UILabel *currentLabel;
@property (strong, nonatomic) IBOutlet UILabel *nextDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *twoDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UIImageView *currentImage;
@property (strong, nonatomic) IBOutlet UIScrollView* scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl* pageControl;
@property (strong, nonatomic) IBOutlet UILabel *updatedLabel;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;

- (IBAction)currentLocationSearch;
- (void)querySearchWithQuery:(NSString *)query;
- (IBAction)querySearch;
- (IBAction)textFieldReturn:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)changePage;

@end
