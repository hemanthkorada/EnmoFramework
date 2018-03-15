//
//  EnmoAppId.m
//  enmo autolock
//


#import "EnmoAppId.h"


@implementation EnmoAppId

//==============================================================================
- ( id ) initWithDictionary: ( NSDictionary * ) dictAppID
{
    self = [ super init ];

    if( self )
    {
        self.ID                 = [ [ dictAppID objectForKey: @"id" ] integerValue ];
        self.appName            = [ dictAppID objectForKey: @"AppName" ];
        self.appID              = [ dictAppID objectForKey: @"AppID" ];
        self.timer              = [ [ dictAppID objectForKey: @"Timer" ] integerValue ];	// 0 - None, 3600 - Hourly, 86400 - Daily, 604800 - Weekly
        self.initialRegions     = [ dictAppID objectForKey: @"InitialRegions" ];
        self.initialHomePage    = [ dictAppID objectForKey: @"InitialHomePage" ];
		self.timestamp			= [ dictAppID objectForKey: @"TimeStamp" ];
	}

	return self;
}

@end
