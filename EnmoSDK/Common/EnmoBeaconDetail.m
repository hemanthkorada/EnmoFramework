//
//  EnmoBeaconDetail.m
//  enmo rules
//


#import "EnmoBeaconDetail.h"


@implementation EnmoBeaconDetail

//==============================================================================
- ( id ) initWithDictionary: ( NSDictionary * ) dictBeacon
{
    self = [ super init ];

    if( self )
    {
        self.deviceID               = [ [ dictBeacon objectForKey: @"DeviceID" ] integerValue ];
        self.deviceName             = [ dictBeacon objectForKey: @"DeviceName" ];
        self.deviceType             = [ dictBeacon objectForKey: @"DeviceType" ];

		if( [ self.deviceType isEqualToString: @"Eddystone" ] )
			NSLog( @"Eddystone" );

        self.deviceManufacturer     = [ dictBeacon objectForKey: @"DeviceManufacturer" ];

		self.deviceIDA				= [ dictBeacon objectForKey: @"DeviceIDA" ];
		self.deviceIDB				= [ dictBeacon objectForKey: @"DeviceIDB" ];

        self.deviceUUID             = [ dictBeacon objectForKey: @"DeviceUUID" ];

        self.deviceMajor            = [ dictBeacon objectForKey: @"DeviceMajor" ];

//        NSNumber * minor = [ dictBeacon objectForKey: @"DeviceMinor" ];
        self.deviceMinor            = [ dictBeacon objectForKey: @"DeviceMinor" ];

		if( self.isEddystone && self.deviceMinor.length == 0 )
			self.deviceMinor = @"NA";

		self.deviceTXPower          = [ dictBeacon objectForKey: @"DeviceTXPower" ];
        self.deviceAddressInstalled = [ dictBeacon objectForKey: @"DeviceAddressInstalled" ];
        self.devicePhoto            = [ dictBeacon objectForKey: @"DevicePhoto" ];
        self.deviceComment          = [ dictBeacon objectForKey: @"DeviceComment" ];
        self.deviceBatteryLevel     = [ dictBeacon objectForKey: @"DeviceBatteryLevel" ];
        self.status                 = [ dictBeacon objectForKey: @"Status" ];
        self.currentProximity       = 0;
    }

    return self;
}


//==============================================================================
- ( void ) encodeWithCoder: ( NSCoder * ) aCoder
{
	[ aCoder encodeObject: [ NSNumber numberWithInteger: self.deviceID ]	forKey: @"DeviceID" ];
	[ aCoder encodeObject: self.deviceName									forKey: @"DeviceName" ];
	[ aCoder encodeObject: self.deviceType									forKey: @"DeviceType" ];
	[ aCoder encodeObject: self.deviceManufacturer							forKey: @"DeviceManufacturer" ];
	[ aCoder encodeObject: self.deviceIDA									forKey: @"DeviceIDA" ];
	[ aCoder encodeObject: self.deviceIDB									forKey: @"DeviceIDB" ];
	[ aCoder encodeObject: self.deviceUUID									forKey: @"DeviceUUID" ];
	[ aCoder encodeObject: self.deviceMajor									forKey: @"DeviceMajor" ];
	[ aCoder encodeObject: self.deviceMinor									forKey: @"DeviceMinor" ];
	[ aCoder encodeObject: self.deviceTXPower								forKey: @"DeviceTXPower" ];
	[ aCoder encodeObject: self.deviceAddressInstalled						forKey: @"DeviceAddressInstalled" ];
	[ aCoder encodeObject: self.devicePhoto									forKey: @"DevicePhoto" ];
	[ aCoder encodeObject: self.deviceComment								forKey: @"DeviceComment" ];
	[ aCoder encodeObject: self.deviceBatteryLevel							forKey: @"DeviceBatteryLevel" ];
	[ aCoder encodeObject: self.status										forKey: @"Status" ];
	//[ aCoder encodeObject: self.currentProximity       = 0;
}


//==============================================================================
- ( id ) initWithCoder: ( NSCoder * ) aDecoder
{
	self = [ self initWithDictionary: nil ];

	self.deviceID               = [ [ aDecoder decodeObjectForKey: @"DeviceID" ] integerValue ];
	self.deviceName             = [ aDecoder decodeObjectForKey: @"DeviceName" ];
	self.deviceType             = [ aDecoder decodeObjectForKey: @"DeviceType" ];
	self.deviceManufacturer     = [ aDecoder decodeObjectForKey: @"DeviceManufacturer" ];
	self.deviceIDA				= [ aDecoder decodeObjectForKey: @"DeviceIDA" ];
	self.deviceIDB				= [ aDecoder decodeObjectForKey: @"DeviceIDB" ];
	self.deviceUUID             = [ aDecoder decodeObjectForKey: @"DeviceUUID" ];
	self.deviceMajor			= [ aDecoder decodeObjectForKey: @"DeviceMajor" ];
	self.deviceMinor			= [ aDecoder decodeObjectForKey: @"DeviceMinor" ];
	self.deviceTXPower          = [ aDecoder decodeObjectForKey: @"DeviceTXPower" ];
	self.deviceAddressInstalled = [ aDecoder decodeObjectForKey: @"DeviceAddressInstalled" ];
	self.devicePhoto            = [ aDecoder decodeObjectForKey: @"DevicePhoto" ];
	self.deviceComment          = [ aDecoder decodeObjectForKey: @"DeviceComment" ];
	self.deviceBatteryLevel     = [ aDecoder decodeObjectForKey: @"DeviceBatteryLevel" ];
	self.status                 = [ aDecoder decodeObjectForKey: @"Status" ];
	self.currentProximity       = 0;

	return self;
}


//==============================================================================
- ( BOOL ) isGimbal
{
	return [ self.deviceType isEqualToString: @"Gimbal" ];
}


//==============================================================================
- ( BOOL ) isIBeacon
{
	return [ self.deviceType isEqualToString: @"iBeacon" ] || [ self isIoT ];
}


//==============================================================================
- ( BOOL ) isAltBeacon
{
	return [ self.deviceType isEqualToString: @"AltBeacon" ];
}


//==============================================================================
- ( BOOL ) isEddystone
{
	return [ self.deviceType isEqualToString: @"Eddystone" ];
}


//==============================================================================
- ( BOOL ) isIoT
{
	return [self isCC2650] || [self isSTM32Nucleo] || [self isFujitsu];
}


//==============================================================================
- ( BOOL ) isCC2650
{
	if([[self.deviceUUID lowercaseString] isEqualToString: [@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0" lowercaseString]] )
		return YES;

	return		[ self.deviceType isEqualToString: @"TISensorTag"]
			||	[ self.deviceType isEqualToString: @"TICC2650STK" ]
			||	( [ self.deviceType rangeOfString: @"CC2650" ].location != NSNotFound );
}


//==============================================================================
- ( BOOL ) isSTM32Nucleo
{
	return		[ self.deviceType isEqualToString: @"STM32 Nucleo"]
	||	[ self.deviceType isEqualToString: @"STM32NUCLEO" ]
	||	( [ self.deviceType rangeOfString: @"STM32" ].location != NSNotFound );
}


//==============================================================================
- ( BOOL ) isFujitsu
{
    // TODO: FUJITSU - check if name is correct
	return [ self.deviceType isEqualToString: @"Fujitsu"];
}


//==============================================================================
- ( NSString * ) description
{
	return [ NSString stringWithFormat: @"EnmoBeaconDetail: %@", self.deviceName ];
}

@end
