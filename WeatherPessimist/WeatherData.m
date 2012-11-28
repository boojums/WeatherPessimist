/*
    WeatherData class implementation
 
 Pessimizes current conditions and forecast based on climate area

 To use: initialize with a json object from WorldWeatherOnline
 
 To do list:
- adjust zip codes method?
- lat/lon climate zone method
- city climate zone method
- get current location in lat/lon
- enum for zone constants?
- pessimized variables should just be a dictionary? of NSNumbers?

- have one dictionary for each climate zone in plist (duplicate existing entries)
 --randomize which description gets used
- first screen current conditions, next screen next-day forecast
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

    climateZoneMethods = [NSArray arrayWithObjects:@"none", @"desert", @"southeast", @"northeast", @"midwest", @"mountainWest", @"pacificNW", @"midatlantic", nil];

    if (self) {
        //if query was of type 'zip code'
        [self setClimateZoneByZip:zip];
        NSLog(@"climateZone set to %i, %@", climateZone, climateZoneMethods[climateZone]);
        
        [self pessimizeData];
    }

    //get today's date
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    dateComponents = [gregorian components:NSMonthCalendarUnit fromDate:today];
    
    return self;
 
}

//need NSNumber selector method
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

- (void)pessimizeData
{

    //check for special zip code/date possibilities (tornado, hurricane, flood, super hot, plague, etc)
    //have special date/location checks for holidays, red sox/yankees, etc.
    //alert sequence if it's *really* bad (super hot days in AZ, osv.) "Are you really sure you want to see this?"
    //fetch description based on wxcode from json and climate zone
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"wxcodes" ofType:@"plist"];
    //should check if plistPath is valid
    NSDictionary *wxCodes = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary *codeDictionary = [wxCodes objectForKey:code];
    self->description = (NSString *)[[codeDictionary objectForKey:@"descriptions"] objectAtIndex:climateZone];

    NSLog(@"description for %@ code at %d: %@", code, climateZone, description);

    //should this be in the init method instead? **********************
    //should be NSNumber?
    self.tempF = [[currentConditions objectForKey:@"temp_F"] intValue];
    self.wind_mph = [currentConditions objectForKey:@"windspeedMiles"];
    self.nextTemp = [nextDayForecast objectForKey:@"tempMaxF"];
    self.twoDayTemp = [twoDayForecast objectForKey:@"tempMaxF"];
    
    //call the special pessimizer function based on the climate zone
    SEL s = NSSelectorFromString(self->climateZoneMethods[climateZone]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:s];
#pragma clang diagnostic pop
}

- (void)none
{
    return;
}

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
    if ((dateComponents.month > 6) && (dateComponents.month <10))
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

- (void)southeast
{
    
}

- (void)northeast
{
    
}

- (void)midwest
{
    
}

- (void)mountainWest
{
    
}

- (void)pacificNW
{
    
}

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


