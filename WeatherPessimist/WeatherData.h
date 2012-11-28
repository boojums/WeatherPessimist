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
    NSArray         *climateZoneMethods;
    NSDictionary    *data;
    NSDictionary    *currentConditions;
    NSDictionary    *nextDayForecast;
    NSDictionary    *twoDayForecast;
    NSString        *code;
    NSDictionary    *codeDictionary;
}


//pressimistic climate variables here - as properties to synthesize
//some kind of arrays instead?
@property int     tempF;
@property (strong, nonatomic) NSNumber *wind_mph;
@property (strong, nonatomic) NSNumber *nextTemp;
@property (strong, nonatomic) NSNumber *twoDayTemp;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSDateComponents   *dateComponents;
//@property (strong, nonatomic) NSThing *thingName;

-(id)initWithData:(NSDictionary *)jsondata;

//if these are not in the interface but only implemented, then are they private?
- (void)setClimateZoneByLat:(float)latititude andLong:(float)longitude;
- (void)setClimateZoneByZip:(NSNumber *)zipCode;

- (void)pessimizeData;
- (void)none;
- (void)desert;
- (void)southeast;
- (void)northeast;
- (void)midwest;
- (void)mountainWest;
- (void)pacificNW;
- (void)midatlantic;
@end

