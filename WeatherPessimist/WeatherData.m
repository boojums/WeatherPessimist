//
//  WeatherData.m
//  WeatherPessimist
//
//  Pessimizes current conditions and forecast based on climate area
//  To use: initialize with a json object from WorldWeatherOnline
//
//  Created by Cristina Luis on 8/17/12.
//  Copyright (c) 2012 Cristina Luis. All rights reserved.
//

/*
 To do list:
- use location information from request itself to assign climate zone. see:
    http://koeppen-geiger.vu-wien.ac.at/present.htm
- get current location in lat/lon
- enum for zone constants?
- pessimized variables should just be a dictionary? of NSNumbers?
- first screen current conditions, next screen next-day forecast, etc.
- preferences screen/button
 */

#define kNoClimateZone 0;
#define kHotDesert 1;
#define kSoutheast 2;
#define kRedSoxNation 3;
#define kFlyoverStates 4;
#define kMountainWest 5;
#define kPacificNW 6;
#define kMidAtlantic 7;


#import "WeatherData.h"

@implementation WeatherData

@synthesize tempF, nextTemp, wind_mph, twoDayTemp, description, dateComponents;

-(id)initWithData:(NSDictionary *)jsondata
{
    self = [super init];
    self->data = jsondata;
    self->currentConditions = [[data objectForKey:@"current_condition"] objectAtIndex:0];
    self->nextDayForecast = [[data objectForKey:@"weather"] objectAtIndex:0];
    self->twoDayForecast = [[data objectForKey:@"weather"] objectAtIndex:1];
    //this is only a zip code if the type of request was a zip code -- need to check request type
    NSNumber *zip = [[[data objectForKey:@"request"] objectAtIndex:0] objectForKey:@"query"];
    self->code = (NSString *)[currentConditions objectForKey:@"weatherCode"];

   
    //Keys in jsondata are: weather, request, current_condition
    //current_condition has an array of one, which is a dictionary
    //weather is an array of two, nextDayForecast and twoDayForecast

    //should this be an enum list?
    climateZoneMethods = [NSArray arrayWithObjects:@"none", @"desert", @"southeast", @"northeast", @"midwest", @"mountainWest", @"pacificNW", @"midatlantic", nil];

    //get today's date -- should probably use date from weather request instead!
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    dateComponents = [gregorian components:NSMonthCalendarUnit fromDate:today];
    
    if (self) {
        //if query was of type 'zip code'
        [self setClimateZoneByZip:zip];
        NSLog(@"climateZone set to %i, %@", climateZone, climateZoneMethods[climateZone]);
        
        //set codeDictionary to be dictionary for codes of climate zone
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"wxcodes" ofType:@"plist"];
        //should check if plistPath is valid
        NSDictionary *wxCodes = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        NSString *temp = climateZoneMethods[climateZone];
        codeDictionary = [[wxCodes objectForKey:temp]
                          objectForKey:code];

        [self pessimizeData];
    }

    return self;
 
}

- (void) setClimateZoneByZip:(NSNumber *)zipCode
{
    int zip = [zipCode intValue];
    
    //some kind of NSNumber range comparison method?
    if (((zip >= 85000) && (zip < 88500)) || ((zip >= 88900) && (zip < 90000))){
        self->climateZone = kHotDesert;
        return;
    }
    else if (((zip >= 27000 ) && (zip < 40000)) || ((zip >= 70000) && (zip < 80000))) {
        self->climateZone = kSoutheast;
        return;
    }
    else if ((zip >= 01000) && (zip < 07000)) {
        self->climateZone = kRedSoxNation;
        return;
    }
    else if (((zip >= 80000) && (zip < 85000)) || ((zip >= 59000) && (zip < 60000))){
        self->climateZone = kMountainWest;
        return;
    }
    else if ((zip >= 40000) && (zip < 70000)) { // need to remove montana (59)
        self->climateZone = kFlyoverStates;
        return;
    }
    else if ((zip >= 97000) && (zip < 99500)) {
        self->climateZone = kPacificNW;
        return;
    }
    else if ((zip >= 07000) && (zip < 27000)) {
        self->climateZone = kMidAtlantic;
        return;
    }
    else if ((zip >= 90000) && (zip < 97000)) { // California and Hawaii
        self->climateZone = kHotDesert;
        return;
    }
    else if ((zip >= 99500) && (zip < 100000)) { //Alaska
        self->climateZone = kMidAtlantic;
        return;
    }
    
    climateZone = kNoClimateZone;
}

- (void) setClimateZoneByLat:(float)latititude andLong:(float)longitude
{
    
}


// ******************************************************************************** pessimizeData
- (void)pessimizeData
{

    //check for special zip code/date possibilities (tornado, hurricane, flood, super hot, plague, etc)
    //have special date/location checks for holidays, red sox/yankees, etc.
    //alert sequence if it's *really* bad (super hot days in AZ, osv.) "Are you really sure you want to see this?"
   
    //set default description
    //randomized or incremented over time if multiple identical codes in a row
    description = (NSString *)[[codeDictionary objectForKey:@"descriptions"]
                               objectAtIndex:0];

    NSLog(@"description for %@ code at %d: %@", code, 0, description);

    //should this be in the init method instead? **********************
    //should be NSNumber?
    tempF = [[currentConditions objectForKey:@"temp_F"] intValue];
    wind_mph = [currentConditions objectForKey:@"windspeedMiles"];
    nextTemp = [nextDayForecast objectForKey:@"tempMaxF"];
    twoDayTemp = [twoDayForecast objectForKey:@"tempMaxF"];
    
    
    //call the special pessimizer function based on the climate zone
    SEL s = NSSelectorFromString(self->climateZoneMethods[climateZone]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:s];
#pragma clang diagnostic pop
}

// ******************************************************************************** none

- (void)none
{
    return;
}

// ******************************************************************************** desert

- (void)desert
{
    //do crazy stuff to the pessimize the data
    NSLog(@"desert called successfully");
    
    //NSNumber ranges?
    if(tempF > 80)
        tempF += 10; //randomize for some variability
    else if(tempF < 40)
        tempF -= 10;
    
    //if monsoon season, and humidity is reasonably high, make it higher with no rain
    if ((dateComponents.month > 6) && (dateComponents.month < 10))
        {
            //humidity higher
            //no precip value
            //change code
        }
    
    //wind
    switch ([wind_mph integerValue]) {
        case 0:
            wind_mph = [NSNumber numberWithInt:[wind_mph intValue] + 7];
            break;
        case 10:
            wind_mph = [NSNumber numberWithInt:[wind_mph intValue] + 15];
        default:
            wind_mph = [NSNumber numberWithInt:[wind_mph intValue] + 7];
            break;
    }
}

// ******************************************************************************** southeast

- (void)southeast
{
    
}

// ******************************************************************************** northeast

- (void)northeast
{
    
}

// ******************************************************************************** midwest

- (void)midwest
{
    
}

// ******************************************************************************** mountainWest

- (void)mountainWest
{
    
}

// ******************************************************************************** pacificNW

- (void)pacificNW
{
    
}

// ******************************************************************************** midatlantic

- (void)midatlantic
{
    
}



- (void)dealloc
{
    
//release as needed with [varName release];

}

@end


/*
 NSEnumerator *enumerator = [twoDayForecast keyEnumerator];
 id key;
 while ((key = [enumerator nextObject])) {
 NSLog(@"key: %@", key);
 NSLog(@"%@", [twoDayForecast objectForKey:key]);
 }
 */


