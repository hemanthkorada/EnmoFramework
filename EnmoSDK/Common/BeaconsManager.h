//
//  BeaconsManager.h
//  enmo demo
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@protocol BeaconsManagerDelegate < NSObject >

@optional
- ( void ) beaconsManagerDidAddBeacon: ( EnmoBeaconDetail * ) beacon shouldReload: ( BOOL ) shouldReload;
- ( void ) beaconsManagerDidRemoveBeacon: ( EnmoBeaconDetail * ) beacon;

@end



@interface BeaconsManager : NSObject < CLLocationManagerDelegate, CBCentralManagerDelegate >
{
    NSMutableArray * _arrayDelegates;
}

@property ( readwrite, retain ) NSMutableArray * arrayMonitoredRegions;

+ ( BeaconsManager * ) shared;

- ( void ) addDelegate: ( id < BeaconsManagerDelegate > ) delegate;
- ( void ) removeDelegate: ( id < BeaconsManagerDelegate > ) delegate;

- ( void ) startRangingRegionsFromArray: ( NSArray * ) regions;
- ( void ) stopRangingForBeacons;
- ( void ) startRangingLastMonitoredRegions;
- ( void ) saveMonitoredRegions;

@end
