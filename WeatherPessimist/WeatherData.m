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
- change climate zones to be more general
- add climate zones mappings to climate_class.plist
- get current location in lat/lon
- enum for zone constants?
- preferences screen/button
- different leves of pessimism? slightly pessimistic just edges everything,
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

@synthesize tempF, wind_mph, description, dateComponents, imageName, forecastMaxTempsF;

-(id)initWithData:(NSDictionary *)jsondata
{
    self = [super init];
    
    //Keys in jsondata are: weather, nearest_area, request, current_condition
    //current_condition has an array of one, which is a dictionary
    //weather is an array of two, nextDayForecast and twoDayForecast
    self->data = jsondata;
    self->currentConditions = [[data objectForKey:@"current_condition"] objectAtIndex:0];
    self->nextDayForecast = [[data objectForKey:@"weather"] objectAtIndex:0];
    self->twoDayForecast = [[data objectForKey:@"weather"] objectAtIndex:1];
        
    self->code = (NSString *)[currentConditions objectForKey:@"weatherCode"];
    self->nearest_area = [[data objectForKey:@"nearest_area"] objectAtIndex:0];
   

    self->climateZoneNames = [NSArray arrayWithObjects:@"none", @"desert", @"southeast", @"northeast", @"midwest", @"mountainWest", @"pacificNW", @"midatlantic", nil];

    //get today's date -- should probably use date from weather request instead? need local date
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    self->dateComponents = [gregorian components:NSMonthCalendarUnit fromDate:today];
    
    if (self) {
        //if query was of type 'zip code'
        NSString *requestType = [[[data objectForKey:@"request"] objectAtIndex:0] objectForKey:@"type"];
        if ([requestType isEqualToString:@"Zipcode"]){
            NSNumber *zip = [[[data objectForKey:@"request"] objectAtIndex:0] objectForKey:@"query"];
            [self setClimateZoneByZip:zip];
        } else {
            [self setClimateZoneByLatLong];
        }
        
        NSLog(@"climateZone set to %i, %@", climateZone, climateZoneNames[climateZone]);
        
        //set codeDictionary to be dictionary for codes of climate zone
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"wxcodes" ofType:@"plist"];
        //should check if plistPath is valid
       
        self->codeDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        self->zoneDescriptions = [[[codeDictionary objectForKey:climateZoneNames[climateZone]]
                                        objectForKey:code]
                                        objectForKey:@"descriptions"];
        self->description = (NSString *)zoneDescriptions[0]; //default description

        //DO NOT think that init should call pessimize -- this should be requested from the outside
        [self pessimizeData];
    }

    return self;
 
}

//do I actually need to set it a zip code? should this be a public method?
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

//incomplete
- (void) setClimateZoneByLatLong
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"climate_class" ofType:@"plist"];
    //should check if plistPath is valid
    NSDictionary *climate_classification = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *latitude = [nearest_area objectForKey:@"latitude"];
    NSString *longitude = [nearest_area objectForKey:@"longitude"];
    
    //NSLog(@"latitude and longitude are %@ and %@", latitude, longitude);
    
    float latitude_float = [latitude floatValue];
    float longitude_float = [longitude floatValue];
    
    
    //round lat lon to the nearest .25 or .75 for reading off the table
    int halves;
    halves = (int)(latitude_float * 2);
    if(latitude_float > 0)
        latitude_float = halves * 0.5 + 0.25;
    else
        latitude_float = halves * 0.5 - 0.25;
    
    halves = (int)(longitude_float * 2);
    if(longitude_float > 0)
        longitude_float = halves * 0.5 + 0.25;
    else
        longitude_float = halves * 0.5 - 0.25;
                   
    latitude = [NSString stringWithFormat:@"%.2f", latitude_float];
    longitude = [NSString stringWithFormat:@"%.2f", longitude_float];
    
    //NSLog(@"rounded latitude and longitude strings are is %@, %@", latitude, longitude);
    
    NSString *climate = [[climate_classification objectForKey:latitude] objectForKey:longitude];
    NSLog(@"climate classification is: %@", climate);
    //get climate mapping from  climate_class plist, codes dictionary
    
}


// ******************************************************************************** pessimizeData
- (void)pessimizeData
{

    //check for special zip code/date possibilities (tornado, hurricane, flood, super hot, plague, etc)
    //if you've been checking a lot for same place, alert that it's not going to get better
    //have special date/location checks for holidays, red sox/yankees, etc.
    //alert sequence if it's *really* bad (super hot days in AZ, osv.) "Are you really sure you want to see this?"
   
    int count = [zoneDescriptions count];
    if (count > 1) {
        //consider using filtered predicate loading of array- summmer/winter/etc
        int num = arc4random() % (count-1) + 1;
        self.description = (NSString *)zoneDescriptions[num];
    }
    
    self->imageName = (NSString *)[[[codeDictionary objectForKey:climateZoneNames[climateZone]]
                                objectForKey:code]
                                objectForKey:@"imageName"];

    if ([imageName length] == 0) {
        imageName = (NSString *)[[[codeDictionary objectForKey:@"none"]
                                  objectForKey:code]
                                  objectForKey:@"imageName"];
        NSLog(@"Using default image.");
    }


    //write a method to transfer all variables to the instance variables, call from init 
    //should be NSNumber? not sure, don't think so
    self.tempF = [[currentConditions objectForKey:@"temp_F"] intValue];
    self.wind_mph = [[currentConditions objectForKey:@"windspeedMiles"] intValue];
    
    self.forecastMaxTempsF = [[NSMutableArray alloc] initWithObjects:
                        [nextDayForecast objectForKey:@"tempMaxF"],
                        [twoDayForecast objectForKey:@"tempMaxF"], nil];

    //call the special pessimizer function based on the climate zone
    SEL s = NSSelectorFromString(self->climateZoneNames[climateZone]);
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
    
    if((tempF > 80) || (tempF < 107))
        tempF += 10; //randomize for some variability
    else if(tempF < 40)
        tempF -= 10;
    else if(tempF > 106)
        self.description = @"Hot. I didn't even have to exaggerate."; //randomize
    
    //if monsoon season, and humidity is reasonably high, make it higher with no rain
    if ((dateComponents.month > 6) && (dateComponents.month < 10))
        {
            //humidity higher
            //no precip value
            //change code
        }
    
    //wind
    switch (wind_mph) {
        case 0:
            wind_mph += 7;
            break;
        case 10:
            wind_mph += 15;
        default:
            wind_mph += 7;
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
    //write ifSchoolDay method
    //if snow predicted, check whether tomorrow is a school day, msg 'snow but no snow day'
    
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


