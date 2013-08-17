//
//  WXPData.h
//  WeatherPessimist data object
//

#define debug(format, ...) CFShow((__bridge CFTypeRef)([NSString stringWithFormat:format, ## __VA_ARGS__]));


@interface WXPData : NSObject
{

}
//functions to return the ones you want instead of copying them into a new array?
@property (strong, nonatomic) NSMutableArray *maxTempF;
@property (strong, nonatomic) NSMutableArray *minTempF;
@property (strong, nonatomic) NSMutableArray *precipMM;
@property (strong, nonatomic) NSMutableArray *windspeedMiles;
@property (strong, nonatomic) NSMutableArray *windDir;

@property (strong, nonatomic) NSMutableArray *sadMaxTempF;
@property (strong, nonatomic) NSMutableArray *sadMinTempF;
@property (strong, nonatomic) NSMutableArray *sadPrecipMM;
@property (strong, nonatomic) NSMutableArray *sadWindspeedMiles;

//ditto functions to return the one you want instead of copying?
@property (strong, nonatomic) NSMutableArray *descriptionsArrays;
@property (strong, nonatomic) NSMutableArray *imageNames;

+(BOOL)canConnect;
-(id)initWithData:(NSDictionary *)jsondata;
-(id)initWithQuery:(NSString *)query;

- (void)setClimateZoneByLatLong;
- (void)setClimateZoneByZip:(NSNumber *)zipCode;
- (NSString *)descriptionForDay:(int)day;
- (NSDate *)dateForDay:(int)day;
- (NSString *)locationString;

- (void)pessimizeData;

@end

