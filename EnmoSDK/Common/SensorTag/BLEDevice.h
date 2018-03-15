//
//  BLEDevice.h
//  enmo
//


#import "BLEService.h"
#import "BLECharacteristic.h"


@class BLEDevice;
@class UIImage;
@class SmartCommand;




typedef enum BLEDeviceOperationType
{
	otNoOperation		= 0,
	otVideoRecording	= 1,
	otBurst				= 2,
	otTimeLapse			= 3,

} BLEDeviceOperationType;



@protocol BLEDeviceDelegate < NSObject >

@optional

- ( void ) bleDevice: (BLEDevice *) device didReceiveRecordsFromTI:(NSArray *)records;
- ( void ) bleDevice: (BLEDevice *) device didReceiveRecordsFromST:(NSArray *)records;
- ( void ) bleDevice: (BLEDevice *) device didReceiveRecordsFromFJ:(NSArray *)records;
- ( void ) bleDevice: (BLEDevice *) device didReceiveDuration: (NSNumber *) duration;

- ( void ) bleDeviceDidDiscoverServices: ( BLEDevice * ) device;

- ( void ) bleDevice: ( BLEDevice * ) device
didUpdateSettingsWithCommand: ( unsigned int ) command
	   andResultCode: ( unsigned int ) resultCode;

- ( void ) bleDevice: ( BLEDevice * ) device
didReceiveResponseForCommand: ( unsigned int ) command
			withData: ( NSData * ) data
		 description: ( NSString * ) description
	   andResultCode: ( unsigned int ) resultCode;

- ( void ) bleDevice: ( BLEDevice * ) device
didUpdateCharacteristic: ( BLECharacteristic * ) characteristic
			withData: ( NSData * ) data;

- ( void ) bleDevice: ( BLEDevice * ) sevice
didDidDiscoverCharacteristicsForService: ( BLEService * ) service;

@end




NS_CLASS_AVAILABLE(NA, 8_0)
@interface BLEDevice : NSObject
{
	// NOTE: Don't move it to .m file, as we have protocols, which also need access to them!
	NSMutableArray * _arrayDelegates;
}

@property ( readwrite, retain ) CBPeripheral * cbPeripheral;
@property ( readwrite, retain ) CBCharacteristic * cbCharact;

// Device services - main storage is dictionary, which allows fast access by UUID key.
@property ( readwrite, retain ) NSMutableDictionary * dictGATTServices;

// dictGATTCharacteristics - ALL device characteristics from ALL available services.
// CBPeripheral allows direct access to characteristic, so we do not need to iterate all services, to find characteristic
// main storage is dictionary, which allows fast access by UUID key.
@property ( readwrite, retain ) NSMutableDictionary * dictGATTCharacteristics;

// Device readable characteristics, which are shown in UI
@property ( readwrite, retain ) NSString * name;
@property ( readwrite, retain ) NSString * nameAdvertised;
@property ( readwrite, retain ) NSNumber * RSSI;
@property ( readwrite, assign ) BOOL isFavourite;
@property ( readwrite, retain ) NSDictionary * lastAdvPacket;
@property ( readwrite, retain ) NSString * key;
@property ( readwrite, retain ) NSString * firmwareVersion;


- ( id ) initWithCBPeripheral: ( CBPeripheral * ) peripheral;

- ( void ) addDelegate: ( id < BLEDeviceDelegate > ) delegate;
- ( void ) removeDelegate: ( id < BLEDeviceDelegate > ) delegate;

- ( BOOL ) isConnected;

// TI UUIDs
+ ( NSString * ) TIScanPacketServiceUUID;
+ ( NSString * ) TIMovementServiceUUID;
+ ( NSString * ) TIMovementCharacteristicUUID;
+ ( NSString * ) TINotifyCharacteristicUUID;
+ ( NSString * ) TITemperatureServiceUUID;
+ ( NSString * ) TITemperatureCharacteristicUUID;

// STM UUIDs
+ ( NSString * ) STMNotifyServiceUUID;
+ ( NSString * ) STMNotifyCharacteristicUUID;

// Fujitsu UUIDs
+ ( NSString * ) FJAdvertisementServiceUUID;
+ ( NSString * ) FJNotifyServiceUUID;
+ ( NSString * ) FJSNotifyCharacteristicUUID;
+ ( NSString * ) FJSWriteCharacteristicUUID;

@end

