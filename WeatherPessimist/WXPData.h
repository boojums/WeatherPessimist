//
//  WXPData.h
//  WeatherPessimist data object
//


@interface WXPData : NSObject
{
    int             climateZone;
    NSArray         *climateZoneNames;
    NSDictionary    *allData;
    NSDictionary    *currentConditions;
    NSMutableArray  *forecastConditions;
    NSDictionary    *nearest_area;
    NSMutableArray  *weatherCodes;
    NSDictionary    *codeDictionary;
    NSMutableArray         *zoneDescriptions;
}


//pressimistic climate variables here - as properties
//single variable for current conditions, array for forecasted conditions (0 tomorrow, 1 next, etc)
//better as dictionaries?
@property int           tempF; // should probably all be NSNumbers for consistency with later
@property int           wind_mph;
@property int           humidity;
//@property int           precipMM;
@property (strong, nonatomic) NSMutableArray *maxTempsF;
@property (strong, nonatomic) NSMutableArray *minTempsF;
@property (strong, nonatomic) NSMutableArray *windsM;
@property (strong, nonatomic) NSMutableArray *precipMM;
@property (strong, nonatomic) NSMutableArray *descriptions;
@property (strong, nonatomic) NSDateComponents   *dateComponents;
@property (strong, nonatomic) NSString *imageName;

-(id)initWithData:(NSDictionary *)jsondata;
-(id)initWithQuery:(NSString *)query;

- (void)setClimateZoneByLatLong;
- (void)setClimateZoneByZip:(NSNumber *)zipCode;

- (void)pessimizeData;

@end

