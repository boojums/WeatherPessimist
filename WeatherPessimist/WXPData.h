//
//  WXPData.h
//  WeatherPessimist data object
//

#define debug(format, ...) CFShow((__bridge CFTypeRef)([NSString stringWithFormat:format, ## __VA_ARGS__]));


@interface WXPData : NSObject
{

}
//try a C-style array of ints instead, with methods for returning the values (as ints or strings)?
@property (strong, nonatomic) NSMutableArray *maxTempF;
@property (strong, nonatomic) NSMutableArray *minTempF;
@property (strong, nonatomic) NSMutableArray *precipMM;
@property (strong, nonatomic) NSMutableArray *windspeedMiles;
@property (strong, nonatomic) NSMutableArray *windDir;

@property (strong, nonatomic) NSMutableArray *sadMaxTempF;
@property (strong, nonatomic) NSMutableArray *sadMinTempF;
@property (strong, nonatomic) NSMutableArray *sadPrecipMM;
@property (strong, nonatomic) NSMutableArray *sadWindspeedMiles;

@property (strong, nonatomic) NSMutableArray *descriptionsArrays;
@property (strong, nonatomic) NSDateComponents   *dateComponents;
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

