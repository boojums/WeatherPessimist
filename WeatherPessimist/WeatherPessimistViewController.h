//
//  WeatherPessimistViewController.h
//  WeatherPessimist
//
//  Created by Cristina Luis on 8/17/12.
//  Copyright (c) 2012 Cristina Luis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeatherPessimistViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *zipField;
@property (strong, nonatomic) IBOutlet UILabel *currentLabel;
@property (strong, nonatomic) IBOutlet UILabel *nextDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *twoDayLabel;
- (IBAction)buttonPushed;
- (IBAction)textFieldReturn:(id)sender;
- (IBAction)backgroundTouched:(id)sender;

@end
