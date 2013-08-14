//
//  WXPData.h
//  WeatherPessimist data object
//


@interface WXPData : NSObject
{
    int             climateZone;
    int             forecastDays;
    NSArray         *climateZoneNames;
    NSDictionary    *allData;
    NSDictionary    *currentConditions;
    NSMutableArray  *forecastConditions;
    NSDictionary    *nearest_area;
    NSDictionary    *climateZoneCodeDictionary;
}

@property (strong, nonatomic) NSMutableDictionary *pessimizedCurrentConditions;
@property (strong, nonatomic) NSMutableArray *pessimizedForecastConditions;
@property (strong, nonatomic) NSDateComponents   *dateComponents;
@property (strong, nonatomic) NSMutableArray *imageNames; //should go in pessimized?

+(BOOL)canConnect;
-(id)initWithData:(NSDictionary *)jsondata;
-(id)initWithQuery:(NSString *)query;

- (void)setClimateZoneByLatLong;
- (void)setClimateZoneByZip:(NSNumber *)zipCode;

- (void)pessimizeData;

@end

