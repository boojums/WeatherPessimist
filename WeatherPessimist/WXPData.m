//
//  WXPData.m
//  WeatherPessimist
//
//  Pessimizes current conditions and forecast based on climate area
//  To use: initialize with a json object from WorldWeatherOnline
//

/*
 To do list:
- change climate zones to be more general
- add climate zones mappings to climate_class.plist
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


#import "WXPData.h"


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //macro for background queue
//#define kJSONStringURL @"/Users/csluis/Code/iOS/WeatherPessimist/weatherdata.json"
#define kJSONStringURL @"http://free.worldweatheronline.com/feed/weather.ashx?q=85711&format=json&num_of_days=2&key=be45236e98154106120808&includeLocation=yes"

#define kJSONStringURLBeginning @"http://free.worldweatheronline.com/feed/weather.ashx?q="
#define kJSONStringURLEnd @"&format=json&num_of_days=2&key=be45236e98154106120808&includeLocation=yes"


#import "WXPData.h"
#import "WeatherPessimistViewController.h"

#pragma mark -
#pragma mark NSDictionary categories for JSON support
@interface NSDictionary(JSONCategories)

+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress;

@end

@implementation NSDictionary(JSONCategories)

+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress
{
    NSData* JSONdata = [NSData dataWithContentsOfURL:
                    [NSURL URLWithString:urlAddress]];
    if(JSONdata == nil) {
        NSLog(@"failed to load data with url");
        return nil;
    }
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:JSONdata
                                                options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}

@end


#pragma mark -
#pragma WXPData private interface
@interface WXPData()
{
    //instance variables here
}

@end

#pragma mark -
#pragma WXPData implimentation
@implementation WXPData

-(id)initWithQuery:(NSString *)query
{
    self = [super init];
    if(self){
        NSString *queryURL = [NSString stringWithFormat:@"%@%@%@",kJSONStringURLBeginning, query, kJSONStringURLEnd];
        //should be added to queue for async handling?
        NSDictionary *responseData = [NSDictionary dictionaryWithContentsOfJSONURLString:queryURL];
        
        allData = [responseData objectForKey:@"data"];

        [self populateData];
    }
    
    return self;
}

-(id)initWithData:(NSDictionary *)jsondata
{
    self = [super init];
    
    if (self) {
        allData = jsondata;
        [self populateData];
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
    
    if ([[NSNull null] isEqual:nearest_area]) {
        NSLog(@"nearest area null");
        return;
    }
    NSString *latitude = [nearest_area objectForKey:@"latitude"];
    NSString *longitude = [nearest_area objectForKey:@"longitude"];
        
    double latitude_dbl = [latitude doubleValue];
    double longitude_dbl = [longitude doubleValue];
    
    latitude = [NSString stringWithFormat:@"%.2f", [self roundToQuarter:latitude_dbl]];
    longitude = [NSString stringWithFormat:@"%.2f", [self roundToQuarter:longitude_dbl]];
    
    //NSLog(@"rounded latitude and longitude strings are is %@, %@", latitude, longitude);
    
    NSString *climate = [[climate_classification objectForKey:latitude] objectForKey:longitude];
    NSLog(@"climate classification is: %@", climate);
    //get climate mapping from  climate_class plist, codes dictionary
    
}

// ******************************************************************************** roundToQuarter
- (double)roundToQuarter:(double)value
{
    int halves;
    halves = (int)(value * 2);
    if(value > 0)
        value = halves * 0.5 + 0.25;
    else
        value = halves * 0.5 - 0.25;
 
    return value;
}

// ******************************************************************************** pessimizeData
- (void)pessimizeData
{

    //check for special zip code/date possibilities (tornado, hurricane, flood, super hot, plague, etc)
    //if you've been checking a lot for same place, alert that it's not going to get better
    //have special date/location checks for holidays, red sox/yankees, etc.
    //alert sequence if it's *really* bad (super hot days in AZ, osv.) "Are you really sure you want to see this?"
   
    [self pessimizeDescriptions];
    [self setDefaultImageName];

    //call the special pessimizer function based on the climate zone
    SEL s = NSSelectorFromString(self->climateZoneNames[climateZone]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:s];
#pragma clang diagnostic pop
}

// ************************************************************************* pessimizeDescription

- (void)pessimizeDescriptions
{
    //consider using filtered predicate loading of array- summmer/winter/etc
    int count = [zoneDescriptions count];
    if (count > 1) {
        int num = (arc4random() % (count -1)) + 1; //any except the 0 index
        self.descriptions[0] = (NSString *)zoneDescriptions[num];
    }
    return;
}

// ************************************************************************* setDefaultImageName

- (void)setDefaultImageName
{
    self.imageName = (NSString *)[[[codeDictionary objectForKey:climateZoneNames[climateZone]]
                                    objectForKey:weatherCodes[0]]
                                   objectForKey:@"imageName"];
    
    if ([self.imageName length] == 0) {
        self.imageName = (NSString *)[[[codeDictionary objectForKey:@"none"]
                                       objectForKey:weatherCodes[0]]
                                      objectForKey:@"imageName"];
        NSLog(@"Using default image.");
    }
    return;
}


// ******************************************************************************** none

- (void)defaultZone
{
    if ([self isSummer]) {
        if (self.tempF > 80) {
            self.tempF += 7;
        } else if (self.tempF < 70) {
            self.tempF -= 6;
        }
        //make it rainier
    }
    
    if ([self isWinter]) {
        if ((self.tempF > 32) && (self.tempF < 43)) {
            self.tempF = self.tempF + ((self.tempF - 32) / 2);
        } else {
            self.tempF -= 10;
        }
    }
    return;
}

// ******************************************************************************** desert

- (void)desert
{

    if((self.tempF > 80) && (self.tempF < 107))
        self.tempF += 10; //randomize for some variability
    else if(self.tempF < 40)
        self.tempF -= 10;
    else if(self.tempF > 106)
        self.descriptions[0] = @"Hot. I didn't even have to exaggerate."; //randomize
    
    //if monsoon season, and humidity is reasonably high, make it higher with no rain
    if ((self.dateComponents.month > 6) && (self.dateComponents.month < 10))
        {
            if (self.humidity > 50) {
                self.humidity *= 1.5;
            }
            //self.precipMM[0] /= 2;
            //change code
        }
    
    switch (self.wind_mph) {
        case 0:
            self.wind_mph += 7;
            break;
        case 10:
            self.wind_mph += 15;
        default:
            self.wind_mph += 7;
            break;
    }
}

// ******************************************************************************** southeast

- (void)southeast
{
    [self defaultZone];
    return;
}

// ******************************************************************************** northeast

- (void)northeast
{
    [self defaultZone];
    return;    
}

// ******************************************************************************** midwest

- (void)midwest
{
    [self defaultZone];
    return;
}

// ******************************************************************************** mountainWest

- (void)mountainWest
{
    [self defaultZone];
    return;
}

// ******************************************************************************** pacificNW

- (void)pacificNW
{
    [self defaultZone];
    if ([self isSummer]) {
        for (NSNumber *day in _precipMM) {
           // day = [NSNumber numberWithInteger:([day intValue] + 3)];
        }
    }
    return;
}

// ******************************************************************************** midatlantic

- (void)midatlantic
{
    [self defaultZone];
    return;
}


- (void)populateData
{
    climateZoneNames = [NSArray arrayWithObjects:@"defaultZone", @"desert", @"southeast", @"northeast", @"midwest", @"mountainWest", @"pacificNW", @"midatlantic", nil];

    //Keys in jsondata are: weather, nearest_area, request, current_condition
    //current_condition has an array of one, which is a dictionary
    //weather is an array of n, with

    currentConditions = [[allData objectForKey:@"current_condition"] objectAtIndex:0];
    forecastConditions = [allData objectForKey:@"weather"];
    nearest_area = [[allData objectForKey:@"nearest_area"] objectAtIndex:0];

    
    weatherCodes[0] = (NSString *)[currentConditions objectForKey:@"weatherCode"];
    int i = 1;
    for (NSDictionary *day in forecastConditions) {
        weatherCodes[i] = [day objectForKey:@"weatherCode"];
        i++;
    }
    
    //get today's date -- should probably use date from weather request instead? need local date
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    _dateComponents = [gregorian components:NSMonthCalendarUnit fromDate:today];
    
    //if query was of type 'zip code'
    NSString *requestType = [[[allData objectForKey:@"request"] objectAtIndex:0] objectForKey:@"type"];
    if ([requestType isEqualToString:@"Zipcode"]){
        NSNumber *zip = [[[allData objectForKey:@"request"] objectAtIndex:0] objectForKey:@"query"];
        [self setClimateZoneByZip:zip];
    } else {
        [self setClimateZoneByLatLong];
    }
    
    NSLog(@"climateZone set to %i, %@", climateZone, climateZoneNames[climateZone]);
    
    //set codeDictionary to be dictionary for codes of climate zone
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"wxcodes" ofType:@"plist"];
    //should check if plistPath is valid
    
    codeDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    zoneDescriptions[0] = [[[codeDictionary objectForKey:climateZoneNames[climateZone]]
                         objectForKey:weatherCodes[0]]
                        objectForKey:@"descriptions"];
    
    self.descriptions[0] = (NSString *)[zoneDescriptions objectAtIndex:0]; //default description
    
    self.tempF = [[currentConditions objectForKey:@"temp_F"] intValue];
    self.wind_mph = [[currentConditions objectForKey:@"windspeedMiles"] intValue];
    
    for (NSDictionary *day in forecastConditions)
    {   
        [self.maxTempsF addObject:(NSNumber *)[day objectForKey:@"tempMaxF"]];
        [self.minTempsF addObject:(NSNumber *)[day objectForKey:@"tempMinF"]];
        [self.windsM addObject:(NSNumber *)[day objectForKey:@"windspeedMiles"]];
        [self.precipMM addObject:(NSNumber *) [day objectForKey:@"precipMM"]];
    }
}

- (BOOL)isSummer
{
    return  ((self.dateComponents.month > 5) && (self.dateComponents.month < 9));
}

- (BOOL)isWinter
{
    return  ((self.dateComponents.month == 12) || (self.dateComponents.month < 3));
}

- (void)dealloc
{
    

}

@end



