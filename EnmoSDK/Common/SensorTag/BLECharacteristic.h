//
//  BLECharacteristic.h
//  enmo
//


@interface BLECharacteristic : NSObject
{

}

@property ( readwrite, retain ) NSString * name;
@property ( readwrite, retain ) NSString * uuid;
@property ( readwrite, retain ) CBCharacteristic * cbCharacteristic;

- ( id ) initWithCBCharacteristic: ( CBCharacteristic * ) characteristic;

- ( BOOL ) isWritable;
- ( BOOL ) isNotify;
- ( BOOL ) isReadable;

@end
