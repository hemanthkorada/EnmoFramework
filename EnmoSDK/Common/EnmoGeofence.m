//
//  EnmoGeofence.m
//  enmo rules
//


#import "EnmoGeofence.h"


@implementation EnmoGeofence

//==============================================================================
- ( id ) initWithDictionary: ( NSDictionary * ) dictGeofence
{
    self = [ super init ];

    if( self )
    {
        self.geofenceID             = [ [ dictGeofence objectForKey: @"GeofenceID" ] integerValue ];
        self.geofenceName           = [ dictGeofence objectForKey: @"GeofenceName" ];
        self.geofenceLat            = [ dictGeofence objectForKey: @"GeofenceLat" ];
        self.geofenceLong           = [ dictGeofence objectForKey: @"GeofenceLong" ];
        self.geofenceRadius         = [ [ dictGeofence objectForKey: @"GeofenceRadius" ] floatValue ];
        self.beaconRegionOrder      = [ dictGeofence objectForKey: @"BeaconRegionOrder" ];
        self.geofenceRegionOrder    = [ dictGeofence objectForKey: @"GeofenceRegionOrder" ];
        self.status                 = [ dictGeofence objectForKey: @"Status" ];
    }

    return self;
}


//==============================================================================
- ( void ) encodeWithCoder: ( NSCoder * ) aCoder
{
	[ aCoder encodeObject: [ NSNumber numberWithInteger: self.geofenceID ]      forKey: @"GeofenceID" ];
	[ aCoder encodeObject: self.geofenceName									forKey: @"GeofenceName" ];
	[ aCoder encodeObject: self.geofenceLat										forKey: @"GeofenceLat" ];
	[ aCoder encodeObject: self.geofenceLong									forKey: @"GeofenceLong" ];
	[ aCoder encodeObject: [ NSNumber numberWithInteger: self.geofenceRadius ]	forKey: @"GeofenceRadius" ];
	[ aCoder encodeObject: self.beaconRegionOrder								forKey: @"BeaconRegionOrder" ];
	[ aCoder encodeObject: self.geofenceRegionOrder								forKey: @"GeofenceRegionOrder" ];
	[ aCoder encodeObject: self.status											forKey: @"Status" ];
}


//==============================================================================
- ( id ) initWithCoder: ( NSCoder * ) aDecoder
{
	self = [ self initWithDictionary: nil ];

	self.geofenceID             = [ [ aDecoder decodeObjectForKey: @"GeofenceID" ] integerValue ];
	self.geofenceName           = [ aDecoder decodeObjectForKey: @"GeofenceName" ];
	self.geofenceLat            = [ aDecoder decodeObjectForKey: @"GeofenceLat" ];
	self.geofenceLong           = [ aDecoder decodeObjectForKey: @"GeofenceLong" ];
	self.geofenceRadius         = [ [ aDecoder decodeObjectForKey: @"GeofenceRadius" ] floatValue ];
	self.beaconRegionOrder      = [ aDecoder decodeObjectForKey: @"BeaconRegionOrder" ];
	self.geofenceRegionOrder    = [ aDecoder decodeObjectForKey: @"GeofenceRegionOrder" ];
	self.status                 = [ aDecoder decodeObjectForKey: @"Status" ];

	return self;
}

@end
