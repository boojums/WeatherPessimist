//
//  WeatherData.h
//  WeatherPessimist
//
//  Created by Cristina Luis on 8/17/12.
//  Copyright (c) 2012 Cristina Luis. All rights reserved.
//

@interface WeatherData : NSObject
{
    int             climateZone;
    NSArray         *climateZoneNames;
    NSDictionary    *data;
    NSDictionary    *currentConditions;
    NSDictionary    *nextDayForecast;
    NSDictionary    *twoDayForecast;
    NSDictionary    *nearest_area;
    NSString        *code;
    NSDictionary    *codeDictionary;
    NSArray         *zoneDescriptions;
}


//pressimistic climate variables here - as properties
//single variable for current conditions, array for forecasted conditions (0 tomorrow, 1 next, etc)
@property int           tempF; // should probably all be NSNumbers for consistency with later
@property int           wind_mph;
@property (strong, nonatomic) NSMutableArray *forecastMaxTempsF;
@property (strong, nonatomic) NSMutableArray *forecastMinTempsF;
@property (strong, nonatomic) NSMutableArray *forecastWindsM;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSDateComponents   *dateComponents;
@property (strong, nonatomic) NSString *imageName;

-(id)initWithData:(NSDictionary *)jsondata;

//if these are not in the interface but only implemented, then are they private?
- (void)setClimateZoneByLatLong;
- (void)setClimateZoneByZip:(NSNumber *)zipCode;

- (void)pessimizeData;

@end

