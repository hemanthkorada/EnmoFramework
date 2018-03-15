//
//  BLEDevice.m
//  enmo
//


#import "BLEDevice.h"


@interface BLEDevice()
{
	NSTimer * _lostCommandHandlingTimer;
}

@end



@implementation BLEDevice

//==============================================================================
- ( id ) initWithCBPeripheral: ( CBPeripheral * ) peripheral
{
    self = [ super init ];

    if( self )
    {
        self.cbPeripheral = peripheral;
        self.dictGATTServices = [ [ NSMutableDictionary alloc ] init ];
        self.dictGATTCharacteristics = [ [ NSMutableDictionary alloc ] init ];

		_arrayDelegates = [ [ NSMutableArray alloc ] init ];
	}

    return self;
}


//==============================================================================
- ( void ) addDelegate: ( id < BLEDeviceDelegate > ) delegate
{
	if( delegate && ![ _arrayDelegates containsObject: delegate ] )
		[ _arrayDelegates addObject: delegate ];
}


//==============================================================================
- ( void ) removeDelegate: ( id < BLEDeviceDelegate > ) delegate
{
	[ _arrayDelegates removeObject: delegate ];
}


//==============================================================================
- ( BOOL ) isConnected
{
	return ( self.cbPeripheral.state == CBPeripheralStateConnected );
}

#pragma mark - UUIDs

//==============================================================================
+ ( NSString * ) TIScanPacketServiceUUID
{
	return @"AA80";
}

//==============================================================================
+ ( NSString * ) TIMovementServiceUUID
{
	return @"F000AA80-0451-4000-B000-000000000000";
}

//==============================================================================
+ ( NSString * ) TIMovementCharacteristicUUID
{
	return @"F000AA81-0451-4000-B000-000000000000";
}

//==============================================================================
+ ( NSString * ) TINotifyCharacteristicUUID
{
	return @"F000AA01-0451-4000-B000-000000000000";
}

//==============================================================================
+ ( NSString * ) TITemperatureServiceUUID
{
	return @"F000AA00-0451-4000-B000-000000000000";
}

//==============================================================================
+ ( NSString * ) TITemperatureCharacteristicUUID
{
	return @"F000AA02-0451-4000-B000-000000000000";
}

//==============================================================================
+ ( NSString * ) STMNotifyServiceUUID
{
	return @"00000000-0001-11E1-9AB4-0002A5D5C51B";
}

//==============================================================================
+ ( NSString * ) STMNotifyCharacteristicUUID
{
	return @"00E00000-0001-11E1-AC36-0002A5D5C51B";
}

//==============================================================================
+ ( NSString * ) FJAdvertisementServiceUUID
{
	return @"FEAB";
}

//==============================================================================
+ ( NSString * ) FJNotifyServiceUUID
{
	return @"0000FC00-B8A4-4078-874C-14EFBD4B510A";
}

//==============================================================================
+ ( NSString * ) FJSNotifyCharacteristicUUID
{
	return @"0000FCF1-B8A4-4078-874C-14EFBD4B510A";
}

//==============================================================================
+ ( NSString * ) FJSWriteCharacteristicUUID
{
	return @"0000FCF0-B8A4-4078-874C-14EFBD4B510A";
}

@end
