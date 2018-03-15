//
//  EnmoBeaconDetail.h
//  enmo rules
//


#import <Foundation/Foundation.h>


@interface EnmoBeaconDetail : NSObject
{

}

@property ( readwrite, assign ) NSInteger deviceID;
@property ( readwrite, retain ) NSString * deviceName;
@property ( readwrite, retain ) NSString * deviceType;
@property ( readwrite, retain ) NSString * deviceManufacturer;
@property ( readwrite, retain ) NSString * deviceIDA;
@property ( readwrite, retain ) NSString * deviceIDB;
@property ( readwrite, retain ) NSString * deviceUUID;
@property ( readwrite, retain ) NSString * deviceMajor;
@property ( readwrite, retain ) NSString * deviceMinor;
@property ( readwrite, retain ) NSString * deviceTXPower;
@property ( readwrite, retain ) NSString * deviceAddressInstalled;
@property ( readwrite, retain ) NSString * devicePhoto;
@property ( readwrite, retain ) NSString * deviceComment;
@property ( readwrite, retain ) NSString * deviceBatteryLevel;
@property ( readwrite, retain ) NSString * status;
@property ( readwrite, retain ) NSString * currentProximity;

- ( id ) initWithDictionary: ( NSDictionary * ) dictBeacon;

- ( BOOL ) isGimbal;
- ( BOOL ) isIBeacon;
- ( BOOL ) isAltBeacon;
- ( BOOL ) isEddystone;
- ( BOOL ) isIoT;
- ( BOOL ) isCC2650;
- ( BOOL ) isSTM32Nucleo;
- ( BOOL ) isFujitsu;

@end
