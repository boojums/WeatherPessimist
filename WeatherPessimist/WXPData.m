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
- set variables to be mutable arrays? temp, humidity, wind, etc?
- enum for zone constants?
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
#define kJSONStringURL @"/Users/csluis/Code/iOS/WeatherPessimist/weatherdata.json"
//#define kJSONStringURL @"http://free.worldweatheronline.com/feed/weather.ashx?q=85711&format=json&num_of_days=2&key=be45236e98154106120808&includeLocation=yes"

#define kJSONStringURLBeginning @"http://api.worldweatheronline.com/free/v1/weather.ashx?q="
#define kJSONStringURLEnd @"&format=json&num_of_days=2&key=79shmj4zveymbv2mvzxhx6de&includeLocation=yes"

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
    /********************* offline switch ********************/
    BOOL offline = false;
    /********************* offline switch ********************/
    
    NSError* error = nil;
    NSData *JSONdata = nil;
    if (offline) {
        NSString *queryURL = [NSString stringWithFormat:@"%@",kJSONStringURL];
        JSONdata = [[NSFileManager defaultManager] contentsAtPath:queryURL];
    } else {
        JSONdata = [NSData dataWithContentsOfURL: [NSURL URLWithString:urlAddress]
                                             options:kNilOptions
                                               error:&error];
        if (error) {
        NSLog(@"%@", [error localizedDescription]);
        }
    }
    
    //redunant
    if(JSONdata == nil) {
        NSLog(@"Failed to load data with url");
        return nil;
    }
    error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:JSONdata
                                                options:kNilOptions error:&error];
    if (error != nil)
        return nil;
    
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
        //NSLog(@"QueryURL: %@", queryURL);
        NSDictionary *responseData = [NSDictionary dictionaryWithContentsOfJSONURLString:queryURL];
        
        if (responseData == nil) {
            return nil;
        }
        
        allData = [responseData objectForKey:@"data"];

        [self populateData];
    }
    
    return self;
}

// ******************************************************************************** initWithData
-(id)initWithData:(NSDictionary *)jsondata
{
    self = [super init];
    
    if (self) {
        allData = jsondata;
        [self populateData];
    }
    return self;
}

// ******************************************************************************** setClimateZoneByZip
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

// ******************************************************************************** setClimateZoneByLatLong
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
    
    NSLog(@"rounded latitude and longitude strings are is %@, %@", latitude, longitude);
    
    NSString *koppenClass = [[climate_classification objectForKey:latitude] objectForKey:longitude];
    NSString *climate = [[climate_classification objectForKey:@"codes"] objectForKey:koppenClass];
    NSLog(@"climate classification is: %@", climate);
    
    //get climate mapping from  climate_class plist, codes dictionary
    if (climate) {
        climateZone = kNoClimateZone; // for now all map to nothing
    }
    
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
    [self setImageNames];

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
    NSArray *currentDescriptions = [self descriptionsForWeatherCode:
                           [currentConditions objectForKey:@"weatherCode"]];
    
    //consider using filtered predicate loading of array- summmer/winter/etc
    int count = [currentDescriptions count];
    if (count > 1) {
        int num = (arc4random() % (count -1)) + 1; //any except the 0 index
        [_pessimizedCurrentConditions setObject:currentDescriptions[num] forKey:@"description"];
    }
    
    for (NSDictionary *day in forecastConditions) {
        currentDescriptions = [self descriptionsForWeatherCode:
                                [day objectForKey:@"weatherCode"]];
        count = [currentDescriptions count];
        int i = 0;
        if (count > 1) {
            int num = (arc4random() % (count -1)) + 1; //any except the 0 index
            [_pessimizedForecastConditions[i] setObject:currentDescriptions[num] forKey:@"description"];
            i++;
        }

    }
    return;
}

// ************************************************************************* setDefaultImageName

- (void)setImageNames
{
    _imageNames = [[NSMutableArray alloc] initWithCapacity:(forecastDays + 1)];
    _imageNames[0] = [self imageNameForWeatherCode:[currentConditions objectForKey:@"weatherCode"]];
    
    for (NSDictionary *day in forecastConditions) {
        NSString *name = [self imageNameForWeatherCode:[day objectForKey:@"weatherCode"]];
        [_imageNames addObject: name];
    }
    
    //image can be nil! no default set!
    return;
}


// ******************************************************************************** defaultZone

- (void)defaultZone
{
    //this needs to be simplified. one method that takes a value and returns, run for all days
    int tempF = [[currentConditions objectForKey:@"temp_F"] intValue];
    if ([self isSummer]) {
        if (tempF > 80) {
            tempF += 7;
        } else if (tempF < 70) {
            tempF -= 6;
        }
        //make it rainier
    }
    
    if ([self isWinter]) {
        if ((tempF > 32) && (tempF < 43)) {
            tempF = tempF + ((tempF - 32) / 2);
        } else {
            tempF -= 8;
        }
    }
    
    NSString *tempFString = [NSString stringWithFormat:@"%d",tempF];
    [_pessimizedCurrentConditions setObject:tempFString forKey:@"temp_F"];;
    
    int i = 0;
    for (NSDictionary *day in forecastConditions) {
        tempF = [[day objectForKey:@"tempMaxF"] intValue];
        if ([self isSummer]) {
            if (tempF > 80) {
                tempF += 7;
            } else if (tempF < 70) {
                tempF -= 6;
            }
            //make it rainier
        }
        
        if ([self isWinter]) {
            if ((tempF > 32) && (tempF < 43)) {
                tempF = tempF + ((tempF - 32) / 2);
            } else {
                tempF -= 8;
            }
        }
        
        NSString *tempFString = [NSString stringWithFormat:@"%d",tempF];
        NSLog(@"tempFString: %@",tempFString);
        [_pessimizedForecastConditions[i] setObject:tempFString forKey:@"tempMaxF"];
        //NSLog(@"pessimizedForecastConditions: %@",_pessimizedForecastConditions);

         i++;
    }
    
    return;
}

// ******************************************************************************** desert

- (void)desert
{
    [self defaultZone];
    /*
    if((self.tempF > 80) && (self.tempF < 107))
        self.tempF += 10; //randomize for some variability
    else if(self.tempF < 40)
        self.tempF -= 10;
    else if(self.tempF > 106)
        self.description = @"Hot. I didn't even have to exaggerate."; //randomize
    
    //if monsoon season, and humidity is reasonably high, make it higher with no rain
    if ((self.dateComponents.month > 6) && (self.dateComponents.month < 10))
        {
            if (self.humidity > 50) {
                self.humidity *= 1.5;
            }
            self.precipMM /= 2;
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
*/

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
    return;
}

// ******************************************************************************** midatlantic
- (void)midatlantic
{
    [self defaultZone];
    return;
}

// ******************************************************************************** populateData
- (void)populateData
{
    forecastDays = 2; //default for now
    climateZoneNames = [NSArray arrayWithObjects:@"defaultZone", @"desert", @"southeast", @"northeast", @"midwest", @"mountainWest", @"pacificNW", @"midatlantic", nil];

    currentConditions = [[allData objectForKey:@"current_condition"] objectAtIndex:0];
    forecastConditions = [allData objectForKey:@"weather"];
    nearest_area = [[allData objectForKey:@"nearest_area"] objectAtIndex:0];
    
    _pessimizedCurrentConditions = [[NSMutableDictionary alloc] initWithDictionary:currentConditions];
    _pessimizedForecastConditions = [[NSMutableArray alloc] initWithCapacity:forecastDays];

    NSMutableDictionary *tempDictionary;
    for (NSDictionary *day in forecastConditions)
        {
            tempDictionary = [[NSMutableDictionary alloc] initWithDictionary:day];
            [_pessimizedForecastConditions addObject:tempDictionary];
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
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"wxcodes" ofType:@"plist"];
    //should check if plistPath is valid
    
    climateZoneCodeDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *descriptionsArray = [self descriptionsForWeatherCode:
                                   [currentConditions objectForKey:@"weatherCode"]];
    [_pessimizedCurrentConditions setObject:descriptionsArray[0] forKey:@"description"];
    
    int i = 0;
    for (NSDictionary *day in forecastConditions)
    {
        descriptionsArray = [self descriptionsForWeatherCode:
                              [day objectForKey:@"weatherCode"]];
        [_pessimizedForecastConditions[i] setObject:descriptionsArray[0] forKey:@"description"];
        i++;
    }
    
}

// **************************************************************************** descriptionsForWeatherCode
//would make sense to have a class method that does everything, for code and zone
- (NSArray *)descriptionsForWeatherCode:(NSString *)code
{
    NSArray *descriptions = [[[climateZoneCodeDictionary
                                objectForKey:climateZoneNames[climateZone]]
                               objectForKey:code]
                              objectForKey:@"descriptions"];
    
    //NSLog(@"Descriptions: %@", descriptions);
    return descriptions;
}


// ****************************************************************************** imageNameForWeatherCode
- (NSString *)imageNameForWeatherCode:(NSString *)code
{
    NSString *name = [[[climateZoneCodeDictionary
                        objectForKey:climateZoneNames[climateZone]]
                       objectForKey:code]
                      objectForKey:@"imageName"];
    return name;
}

// ******************************************************************************** isSummer
- (BOOL)isSummer
{
    return  ((self.dateComponents.month > 5) && (self.dateComponents.month < 9));
}

// ******************************************************************************** isWinter
- (BOOL)isWinter
{
    return  ((self.dateComponents.month == 12) || (self.dateComponents.month < 3));
}

- (void)dealloc
{
    

}

// ******************************************************************************** canConnect
+(BOOL)canConnect{
    NSError *error = nil;
    [NSData dataWithContentsOfURL: [NSURL URLWithString:@"http://api.worldweatheronline.com/free/v1/weather.ashx?q=85711&format=json&num_of_days=1&key=79shmj4zveymbv2mvzxhx6de"]
                      options:kNilOptions
                        error:&error];
    if (error) {
        //not connected to internet or server not available, used cached data, display message, etc
        NSLog(@"Connection to WWO failed");
        return NO;
    }
    return YES;
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


