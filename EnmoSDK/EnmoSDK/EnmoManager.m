//
//  EnmoManager.m
//  EnmoSDK
//
//  Created by APPLE on 14/03/18.
//  Copyright © 2018 APPLE. All rights reserved.
//

#import "EnmoManager.h"
#import "GimbalsManager.h"
#import "EddystoneManager.h"


EnmoManager *enmoManager = nil;

@implementation EnmoManager

+ (EnmoManager *) shared {
    {
        if( enmoManager == nil )
            enmoManager = [ [ EnmoManager alloc ] init ];
        return enmoManager;
    }
}

- (BOOL) checkNewRules {
    return  [ [ RulesManager shared ] checkForNewRules ];
}


- ( void ) start3rdPartyRanging
{
    [ [ GimbalsManager shared ] startMonitoring ];
    [ [ EddystoneManager shared ] startScanning ];
}

- ( void ) stop3rdPartyRanging
{
    [ [ GimbalsManager shared ] stopMonitoring ];
    [ [ EddystoneManager shared ] stopScanning ];
}

- ( void ) loadRulesFromServer: (BOOL) isForced
{
    [ [ RulesManager shared ] getRulesFromServer: NO ];
}

- ( NSInteger ) appIdTimer{
    return  [ RulesManager shared ].currentAppId.timer;
}
- ( void ) setAdvertiserId: (int) advID {
    [ RulesManager shared ].advertiserId = advID;

}
- ( int ) getAdvertiserId {
    return (int)[ RulesManager shared ].advertiserId;
}

- (void)prepareForAppTerminate {
    [ [ RulesManager shared ] saveMonitoredRegions ];
}



@end
