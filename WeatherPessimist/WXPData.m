//
//  WXPData.m
//  WeatherPessimist
//
//  Pessimizes current conditions and forecast based on climate area
//  To use: initialize with a query string
//

/*
 To do list:
- use C arrays for variables with getter functions, eg (int)maxTempF forDay:(int)day
- change climate zones to be more general
- add climate zones mappings to climate_class.plist
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
#define kJSONStringURLEnd @"&format=json&num_of_days=5&key=79shmj4zveymbv2mvzxhx6de&includeLocation=yes"

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
        debug(@"%@", [error localizedDescription]);
        }
    }
    
    //redunant
    if(JSONdata == nil) {
        debug(@"Failed to load data with url");
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
    int             forecastDays;
    int             descriptionIndices[5];
    int             climateZone;
    NSString        *koppenClass;
    NSArray         *climateZoneNames;
    NSDictionary    *climateZoneCodeDictionary;

    NSDictionary    *allData;
    NSDictionary    *currentConditions;
    NSMutableArray  *forecastConditions;
    NSDictionary    *nearest_area;
}

@end

#pragma mark -
#pragma WXPData implimentation
@implementation WXPData

-(id)initWithQuery:(NSString *)query
{
    self = [super init];
    
    _maxTempF = [[NSMutableArray alloc] init];
    _minTempF = [[NSMutableArray alloc] init];
    _precipMM = [[NSMutableArray alloc] init];
    _windspeedMiles = [[NSMutableArray alloc] init];
    _windDir = [[NSMutableArray alloc] init];
    _sadMaxTempF = [[NSMutableArray alloc] init];
    _sadMinTempF = [[NSMutableArray alloc] init];
    _sadPrecipMM = [[NSMutableArray alloc] init];
    _sadWindspeedMiles = [[NSMutableArray alloc] init];
    _descriptionsArrays = [[NSMutableArray alloc] init];
    
    if(self){
        NSString *queryURL = [NSString stringWithFormat:@"%@%@%@",kJSONStringURLBeginning, query, kJSONStringURLEnd];
        //should be added to queue for async handling?
        debug(@"QueryURL: %@", queryURL);
        queryURL = [queryURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseData = [NSDictionary dictionaryWithContentsOfJSONURLString:queryURL];
        
        if (responseData == nil) {
            return nil;
        }
        
        allData = [responseData objectForKey:@"data"];
        
        NSString *errorMsg = [[[allData objectForKey:@"error"] objectAtIndex:0] objectForKey:@"msg"];
        if (errorMsg) {
            debug(@"Error message from WWO:%@", errorMsg);
            return nil;
        }
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
        debug(@"nearest area null");
        return;
    }
    
    //check for area code query and use that?
    
    NSString *latitude = [nearest_area objectForKey:@"latitude"];
    NSString *longitude = [nearest_area objectForKey:@"longitude"];
        
    double latitude_dbl = [latitude doubleValue];
    double longitude_dbl = [longitude doubleValue];
    
    latitude = [NSString stringWithFormat:@"%.2f", [self roundToQuarter:latitude_dbl]];
    longitude = [NSString stringWithFormat:@"%.2f", [self roundToQuarter:longitude_dbl]];
    
    debug(@"rounded latitude and longitude strings are is %@, %@", latitude, longitude);
    
    koppenClass = [[climate_classification objectForKey:latitude] objectForKey:longitude];
    NSString *climate = [[climate_classification objectForKey:@"codes"] objectForKey:koppenClass];
    debug(@"climate classification is: %@", climate);
    
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
    //OR -- better to have one method that does things based on koppen class?
    SEL s = NSSelectorFromString(self->climateZoneNames[climateZone]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:s];
#pragma clang diagnostic pop
}

// ************************************************************************* pessimizeDescription

- (void)pessimizeDescriptions
{
    int count;
    int i = 0;
    for (NSArray *day in _descriptionsArrays)
    {
        count = [day count];
        if (count > 1) {
            descriptionIndices[i] = (arc4random() % (count -1)) + 1; //any except the 0 index
        } else {
            descriptionIndices[i] = 0;
        }
        i++;
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
    int maxTemp = 0;
    int precip = 0;
    int windspeed = 0;
    for (int i=0; i < 5; i++) {
        maxTemp = [_maxTempF[i] intValue];
        precip = [_precipMM[i] intValue];
        windspeed = [_windspeedMiles[i] intValue];
        if ([self isSummer]) {
            if (maxTemp > 80) {
                maxTemp += 7;
            } else if (maxTemp < 70) {
                maxTemp -= 6;
            }
            
        }
        if ([self isWinter]) {
            if ((maxTemp > 32) && (maxTemp < 43)) {
                maxTemp = maxTemp + ((maxTemp - 32) / 2);
            } else {
                maxTemp -= 8;
            }
            windspeed += 5;
            //calculate windchill?
        }
        precip += 5;

        //NSLog(@"temp: %d", maxTemp);
        _sadMaxTempF[i] = [NSNumber numberWithInt:maxTemp];
        _sadPrecipMM[i] = [NSNumber numberWithInt:precip];
        _sadWindspeedMiles[i] = [NSNumber numberWithInt:windspeed];
    }
    
    //old current conditions code
    /*
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
*/    
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
    forecastDays = 5; //default for now
    climateZoneNames = [NSArray arrayWithObjects:@"defaultZone", @"desert", @"southeast", @"northeast", @"midwest", @"mountainWest", @"pacificNW", @"midatlantic", nil];

    currentConditions = [[allData objectForKey:@"current_condition"] objectAtIndex:0];
    forecastConditions = [allData objectForKey:@"weather"];
    nearest_area = [[allData objectForKey:@"nearest_area"] objectAtIndex:0];
    
    for (NSDictionary *day in forecastConditions)
        {            
            [_maxTempF addObject:day[@"tempMaxF"]];
            [_minTempF addObject:day[@"tempMinF"]];
            [_precipMM addObject:day[@"precipMM"]];
            [_windspeedMiles addObject:day[@"windspeedMiles"]];
            [_windDir addObject:day[@"winddirection"]];
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
    
    //NSLog(@"climateZone set to %i, %@", climateZone, climateZoneNames[climateZone]);
    
    //should check if plistPath is valid
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"wxcodes" ofType:@"plist"];
    climateZoneCodeDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        
    int i = 0;
    for (NSDictionary *day in forecastConditions)
    {
        _descriptionsArrays[i] = [self descriptionsForWeatherCode:day[@"weatherCode"]];
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
- (BOOL)isWinter //redundant... !isSummer is the same thing
{
    return  ((self.dateComponents.month == 12) || (self.dateComponents.month < 3));
}

- (void)dealloc
{
    _sadWindspeedMiles = nil;
    _sadMaxTempF = nil;
    _sadMinTempF = nil;
    _sadPrecipMM = nil;

}

// ******************************************************************************** dateForDay
- (NSDate *)dateForDay:(int)day
{
    NSString *dateString = [forecastConditions[day] objectForKey:@"date"];
    debug(@"date string: %@", dateString);
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate *date =[dateFormat dateFromString:dateString];
    debug(@"date: %@", date);
    return date;
}

// ******************************************************************************** descriptionForDay
- (NSString *)descriptionForDay:(int)day
{
    int index = descriptionIndices[day];
    return _descriptionsArrays[day][index];
}

// ******************************************************************************** descriptionForDay
- (NSString *)locationString
{
    NSString *city = nearest_area[@"areaName"][0][@"value"];
    NSString *country = nearest_area[@"country"][0][@"value"];
    NSString *region = nearest_area[@"region"][0][@"value"];
    NSString *location;
    
    if ( ([country isEqualToString:@"USA"]) || ([country isEqualToString:@"United States Of America"])){
        location = [NSString stringWithFormat:@"%@, %@", city, region];
    } else {
        location = [NSString stringWithFormat:@"%@, %@", city, country];
    }
    
    debug(@"location: %@", location);
    return location;
}

// ******************************************************************************** canConnect
+(BOOL)canConnect{
    NSError *error = nil;
    [NSData dataWithContentsOfURL: [NSURL URLWithString:@"http://api.worldweatheronline.com/free/v1/weather.ashx?q=85711&format=json&num_of_days=1&key=79shmj4zveymbv2mvzxhx6de"]
                      options:kNilOptions
                        error:&error];
    if (error) {
        //not connected to internet or server not available, used cached data, display message, etc
        debug(@"Connection to WWO failed");
        return NO;
    }
    return YES;
}

@end



