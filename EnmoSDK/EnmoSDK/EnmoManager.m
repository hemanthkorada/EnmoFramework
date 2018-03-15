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

- ( void ) start3rdPartyRanging
{
    [ [ GimbalsManager shared ] startMonitoring ];
    //#ifndef AUTOLOCK
    [ [ EddystoneManager shared ] startScanning ];
    //#endif
}

- ( void ) stop3rdPartyRanging
{
    [ [ GimbalsManager shared ] stopMonitoring ];
    //#ifndef AUTOLOCK
    [ [ EddystoneManager shared ] stopScanning ];
    //#endif
}


@end
