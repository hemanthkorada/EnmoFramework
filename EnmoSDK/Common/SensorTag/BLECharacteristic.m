//
//  BLECharacteristic.m
//  enmo
//


#import "BLECharacteristic.h"


@implementation BLECharacteristic

//==============================================================================
- ( id ) initWithCBCharacteristic: ( CBCharacteristic * ) characteristic
{
    self = [ super init ];

    if( self )
    {
        self.uuid = [ characteristic.UUID UUIDString ];
        self.cbCharacteristic = characteristic;
    }

    return self;
}

/*
 !
 *  @enum CBCharacteristicProperties
 *
 *	@discussion Characteristic properties determine how the characteristic value can be	used, or how the descriptor(s) can be accessed. Can be combined. Unless
 *				otherwise specified, properties are valid for local characteristics published via @link CBPeripheralManager @/link.
 *
 *	@constant CBCharacteristicPropertyBroadcast						Permits broadcasts of the characteristic value using a characteristic configuration descriptor. Not allowed for local characteristics.
 *	@constant CBCharacteristicPropertyRead							Permits reads of the characteristic value.
 *	@constant CBCharacteristicPropertyWriteWithoutResponse			Permits writes of the characteristic value, without a response.
 *	@constant CBCharacteristicPropertyWrite							Permits writes of the characteristic value.
 *	@constant CBCharacteristicPropertyNotify						Permits notifications of the characteristic value, without a response.
 *	@constant CBCharacteristicPropertyIndicate						Permits indications of the characteristic value.
 *	@constant CBCharacteristicPropertyAuthenticatedSignedWrites		Permits signed writes of the characteristic value
 *	@constant CBCharacteristicPropertyExtendedProperties			If set, additional characteristic properties are defined in the characteristic extended properties descriptor. Not allowed for local characteristics.
 *	@constant CBCharacteristicPropertyNotifyEncryptionRequired		If set, only trusted devices can enable notifications of the characteristic value.
 *	@constant CBCharacteristicPropertyIndicateEncryptionRequired	If set, only trusted devices can enable indications of the characteristic value.
 *

typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
	CBCharacteristicPropertyBroadcast												= 0x01,
	CBCharacteristicPropertyRead													= 0x02,
	CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
	CBCharacteristicPropertyWrite													= 0x08,
	CBCharacteristicPropertyNotify													= 0x10,
	CBCharacteristicPropertyIndicate												= 0x20,
	CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
	CBCharacteristicPropertyExtendedProperties										= 0x80,
	CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
	CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
};

 */

//==============================================================================
- ( BOOL ) isWritable
{
	return ( ( ( self.cbCharacteristic.properties & CBCharacteristicPropertyWrite )
			  || ( self.cbCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse ) ) != 0 ) ? YES : NO;
}


//==============================================================================
- ( BOOL ) isNotify
{
	return ( ( self.cbCharacteristic.properties & CBCharacteristicPropertyNotify ) != 0 ) ? YES : NO;
}


//==============================================================================
- ( BOOL ) isReadable
{
	return ( ( self.cbCharacteristic.properties & CBCharacteristicPropertyRead ) != 0 ) ? YES : NO;
}

@end
