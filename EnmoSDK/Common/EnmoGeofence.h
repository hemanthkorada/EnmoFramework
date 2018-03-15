//
//  EnmoGeofence.h
//  enmo rules
//


#import <Foundation/Foundation.h>


@interface EnmoGeofence : NSObject
{

}

@property ( readwrite, assign ) NSInteger geofenceID;
@property ( readwrite, retain ) NSString * geofenceName;
@property ( readwrite, retain ) NSString * geofenceLat;
@property ( readwrite, retain ) NSString * geofenceLong;
@property ( readwrite, assign ) float geofenceRadius;
@property ( readwrite, retain ) NSString * beaconRegionOrder;
@property ( readwrite, retain ) NSString * geofenceRegionOrder;
@property ( readwrite, retain ) NSString * status;

- ( id ) initWithDictionary: ( NSDictionary * ) dictGeofence;

@end
