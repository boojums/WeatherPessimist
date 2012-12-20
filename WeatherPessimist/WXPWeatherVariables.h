//
//  WXPWeatherVariables.h
//  WeatherPessimist
//
//  Created by Cristina Luis on 12/20/12.
//  Copyright (c) 2012 Cristina Luis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WXPWeatherVariables : NSObject

@property int           maxTempF;
@property int           minTempF;
@property int           windM;
@property int           humidity;
@property int           precipMM;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSDateComponents   *dateComponents;
@property (strong, nonatomic) NSString *imageName;

@end
