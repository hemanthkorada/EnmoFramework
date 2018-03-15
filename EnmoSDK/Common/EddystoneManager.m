//
//  EddystoneManager.m
//  enmo autolock
//
//  Copyright (c) 2015 enmo Technologies. All rights reserved.
//

#import "EddystoneManager.h"
#import "ESSEddystone.h"
#import "BLEDevice.h"
#import "BLEDevice+CBPeripheralDelegate.h"
//#import "MainViewController.h"
#import "ESSTimer.h"

NSString * KEY_FJ =	@"FWM8BL";


EddystoneManager * eddystoneManager;

@interface EddystoneManager() < BLEDeviceDelegate >
{
	NSMutableDictionary * _dictRules;
	NSMutableDictionary * _dictBLEDevices;
}

@end


@implementation EddystoneManager

//==============================================================================
+ ( EddystoneManager * ) shared
{	
	if( eddystoneManager == nil )
		eddystoneManager = [ [ EddystoneManager alloc ] init ];

	return eddystoneManager;
}


//==============================================================================
- ( id ) init
{
	self = [ super init ];

	if( self )
	{
		_dictBLEDevices = [ [ NSMutableDictionary alloc ] init ];
		_dictRules = [ [ NSMutableDictionary alloc ] init ];
	}

	return self;
}


//==============================================================================
- ( void ) startScanning
{
	if( _eddystoneScanner == nil )
	{
		_eddystoneScanner = [ [ ESSBeaconScanner alloc ] init ];
		_eddystoneScanner.delegate = self;
	}

	[ _eddystoneScanner startScanning ];
}


//==============================================================================
- ( void ) stopScanning
{
	[ _eddystoneScanner stopScanning ];
}


#pragma mark - Discovery of Eddystones (ESSBeaconScannerDelegate)
// NOTE: Those delegates are called when real Eddystone is discovered

//==============================================================================
- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner didFindBeacon: ( id ) beaconInfo
{
	NSLog( @"I Saw an Eddystone!: %@", beaconInfo );

	ESSBeaconInfo * beacon = ( ESSBeaconInfo * ) beaconInfo;
	NSString * string = [ NSString stringWithFormat: @"%@", beacon.beaconID.beaconID ];

	string = [ string stringByReplacingOccurrencesOfString: @"<" withString: @"" ];
	string = [ string stringByReplacingOccurrencesOfString: @">" withString: @"" ];
	string = [ string stringByReplacingOccurrencesOfString: @" " withString: @"" ];

	NSString * namespace = [ string substringWithRange: NSMakeRange( 0, 20 ) ];
	NSString * instance = [ string substringWithRange: NSMakeRange( 20, 12 ) ];

	[ Logger logToConsole: [ NSString stringWithFormat: @"ESS Place EN: %@", beacon.beaconID ] ];

//	NSData * data = beacon.beaconID.beaconID;
//	NSUInteger capacity = data.length * 2;
//	NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
//	const unsigned char *buf = data.bytes;
//	NSInteger i;
//	for (i=2; i<data.length; ++i) {
//		[sbuf appendFormat:@"%02lX", (unsigned long)buf[i]];
//	}

	NSString * key = [[NSString stringWithFormat:@"%@%@", namespace, instance] lowercaseString];

	BLEDevice * device = _dictBLEDevices[key];

	// NOTE: Konstantin
	// Check if this device was seen already.
	if( device == nil )
	{
		[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: %@", key ] ];

		BLEDevice * device = [ [ BLEDevice alloc ] initWithCBPeripheral: beacon.peripheral ];
		device.key = [NSString stringWithString: key];
		device.name = beacon.peripheral.name;
		NSLog(@"DEVICE KEY 1: %@", device.key);

		// Parse firmware version - support for FW version for each new device should be added here.
		if(beacon.peripheral.name)
		{
			// TODO: FUJITSU - check with correct name
			if([beacon.peripheral.name.lowercaseString rangeOfString:@"fujitsu"].location != NSNotFound)
				device.firmwareVersion = [beacon.peripheral.name.lowercaseString stringByReplacingOccurrencesOfString: @"fujitsu" withString: @"" ];
		}
		else
			device.name = @"Unknown";

		beacon.peripheral.delegate = device;
		[device addDelegate: self];
		_dictBLEDevices[key] = device;

//		if( shouldConnectDeviceUponDiscovery )
//		{
//			shouldConnectDeviceUponDiscovery = NO;
//			bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
//					  ^
//					  {
//						  [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in connectBLEDevice:%f", [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];
//						  [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
//						  bgTask = UIBackgroundTaskInvalid;
//					  }];
//			[ _eddystoneScanner connectBLEDevice: device ];
//		}
	}

//	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"ESS Place EN: %@", beaconInfo ] ];
	[ [ RulesManager shared ] checkEntryRuleForEddystoneWithNamespace: namespace andInstance: instance ];
}


//==============================================================================
- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner
		 didUpdateBeacon: ( id ) beaconInfo
{
	NSLog( @"I Updated an Eddystone!: %@", beaconInfo );
}


//==============================================================================
- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner
		   didLoseBeacon: ( id ) beaconInfo
{
	ESSBeaconInfo * beacon = ( ESSBeaconInfo * ) beaconInfo;
	
	NSString * string = [ NSString stringWithFormat: @"%@", beacon.beaconID.beaconID ];

	string = [ string stringByReplacingOccurrencesOfString: @"<" withString: @"" ];
	string = [ string stringByReplacingOccurrencesOfString: @">" withString: @"" ];
	string = [ string stringByReplacingOccurrencesOfString: @" " withString: @"" ];

	NSString * namespace = [ string substringWithRange: NSMakeRange( 0, 20 ) ];
	NSString * instance = [ string substringWithRange: NSMakeRange( 20, 12 ) ];
	
	[ Logger logToConsole: [ NSString stringWithFormat: @"ESS Place EX: %@", beacon.beaconID ] ];
//	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"ESS Place EX: %@", beaconInfo ] ];
	[ [ RulesManager shared ] checkExitRuleForEddystoneWithNamespace: namespace andInstance: instance ];
}

/*
//==============================================================================
- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner
didEnterSensorTagWithIdA: ( NSString * ) idA
				  andIdB: ( NSString * ) idB
			  peripheral: ( CBPeripheral * ) peripheral
{
	NSArray * params = @[idA, idB, peripheral];
	[ self performSelectorOnMainThread: @selector( handleBLEEntry: ) withObject: params waitUntilDone: NO ];
}


//==============================================================================
- ( void ) handleBLEEntry: ( NSArray * ) params
{
	NSString * idA = params[0];
	NSString * idB = params[1];
	CBPeripheral * peripheral = params[2];

	if( _dictBLEs == nil )
		_dictBLEs = [ [ NSMutableDictionary alloc ] init ];

	NSString * key = [ [ idA stringByAppendingString: idB ] lowercaseString ];

	BLEDevice * device = _dictBLEs[key];

	if(device == nil)
	{
		NSLog(@"peripheral.name: %@", peripheral.name);
		device = [ [ BLEDevice alloc ] initWithCBPeripheral: peripheral ];
		device.key = [NSString stringWithString: key];
		NSLog(@"DEVICE KEY 2: %@", device.key);

		if(peripheral.name) {
			if([peripheral.name rangeOfString:@"CC2650"].location != NSNotFound)
				device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"Enmo CC2650 " withString: @"" ];
			else if([peripheral.name rangeOfString:@"STM"].location != NSNotFound)
				device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"enmoSTM " withString: @"" ];
		}
		peripheral.delegate = device;
		_dictBLEs[key] = device;
		[device addDelegate: self];

//		if([_dictRules objectForKey: key] )
//		{
//			NSArray * array = _dictRules[key];
//			[ self readDataFromSensor:array[1] rule:array[0]];
//		}
	}

	[ Logger logToConsole: [ NSString stringWithFormat: @"TI EN: %@-%@", idA, idB ] ];
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"TI EN: %@-%@", idA, idB ] ];
	[ [ RulesManager shared ] checkEntryRuleForEddystoneWithNamespace: idA andInstance: idB ];
}


//==============================================================================
- ( void ) beaconScanner:(ESSBeaconScanner *)scanner didExitSensorTagWithIdA:(NSString *)idA andIdB:(NSString *)idB
{
	NSArray * params = @[idA, idB];
	[ self performSelectorOnMainThread: @selector( handleBLEExit: ) withObject: params waitUntilDone: NO ];
}


//==============================================================================
- ( void ) handleBLEExit: ( NSArray * ) params
{
	NSString * idA = params[0];
	NSString * idB = params[1];

	[ Logger logToConsole: [ NSString stringWithFormat: @"TI EX: %@-%@", idA, idB ] ];
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"TI EX: %@-%@", idA, idB ] ];
	[ [ RulesManager shared ] checkExitRuleForEddystoneWithNamespace: idA andInstance: idB ];
}


//==============================================================================
- ( void ) beaconScanner:(ESSBeaconScanner *)scanner didUpdateSensorTagWithIdA:(NSString *)idA andIdB:(NSString *)idB
{

}
*/

#pragma mark - Discovery of IoT devices
UIBackgroundTaskIdentifier bgTask;
BOOL shouldConnectDeviceUponDiscovery = NO;

//==============================================================================
- (void)beaconScanner:(ESSBeaconScanner *)scanner
 didFindBLEPeripheral:(CBPeripheral*)peripheral
		withAdvPacket:(NSDictionary *)advPacket
{
	NSString * localName = advPacket[CBAdvertisementDataLocalNameKey];
	NSString * peripheralName = [localName rangeOfString: KEY_FJ].location != NSNotFound ? localName : peripheral.name;

//	NSLog(@"peripheralName = %@", peripheralName);
//	NSLog(@"advPacket = %@", advPacket);

	if(peripheralName == nil) return;

	if([peripheralName rangeOfString:@"EST" ].location != NSNotFound
	   || [peripheralName rangeOfString:@"Kontakt" ].location != NSNotFound
	   || [peripheralName.lowercaseString rangeOfString:@"macbook" ].location != NSNotFound
	   ) { return; }

	if(_dictBLEDevices == nil) _dictBLEDevices = [ [ NSMutableDictionary alloc ] init ];

	// 1. Parse UUID
	NSData * data = advPacket[CBAdvertisementDataManufacturerDataKey];
	NSUInteger capacity = data.length * 2;
	NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
	const unsigned char *buf = data.bytes;
	NSInteger i;
	for (i=2; i<data.length; ++i) {
		[sbuf appendFormat:@"%02lX", (unsigned long)buf[i]];
	}

	NSString * key = [peripheralName rangeOfString: KEY_FJ].location != NSNotFound ? KEY_FJ : [sbuf lowercaseString];

	BLEDevice * device = _dictBLEDevices[key];

	// NOTE: Konstantin
	// Check if this device was seen already.
	if( device == nil && key.length > 0)
	{
		[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: Key 1 %@", key ] ];

		device = [ [ BLEDevice alloc ] initWithCBPeripheral: peripheral ];
		device.key = [NSString stringWithString: key];
		device.name = peripheral.name;
		NSLog(@"DEVICE KEY 3: %@", device.key);

		// Parse firmware version - support for FW version for each new device should be added here.
		if(peripheral.name)
		{
			if([peripheral.name rangeOfString:@"CC2650"].location != NSNotFound)
				device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"Enmo CC2650 " withString: @"" ];
			else if([peripheral.name rangeOfString:@"STM"].location != NSNotFound)
				device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"STM" withString: @"" ];
            else if([peripheral.name rangeOfString:@"STa2em1"].location != NSNotFound)
                device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"STa2em" withString: @"" ];
			else if([peripheral.name rangeOfString:@"enmoST"].location != NSNotFound)
				device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"enmoST" withString: @"" ];
			else if([peripheral.name rangeOfString:@"enmoNC"].location != NSNotFound)
				device.firmwareVersion = [peripheral.name stringByReplacingOccurrencesOfString: @"enmoNC" withString: @"" ];

            // TODO: FUJITSU - check with correct name
            else if([peripheral.name.lowercaseString rangeOfString:@"fujitsu"].location != NSNotFound)
                device.firmwareVersion = [peripheral.name.lowercaseString stringByReplacingOccurrencesOfString: @"fujitsu" withString: @"" ];
			else if(peripheral.name.length > 3)
				device.firmwareVersion = [peripheral.name substringFromIndex: peripheral.name.length - 3];
		}

		peripheral.delegate = device;
		[device addDelegate: self];
		_dictBLEDevices[key] = device;

		if( shouldConnectDeviceUponDiscovery )
		{
			[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: Shld Cnct 1 %@", key ] ];

			shouldConnectDeviceUponDiscovery = NO;
			bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
					  ^
					  {
						  [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in connectBLEDevice:%f", [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];
						  [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
						  bgTask = UIBackgroundTaskInvalid;
					  }];
			[ _eddystoneScanner connectBLEDevice: device ];
		}
	}
}


//==============================================================================
- ( void ) readDataFromIoTDevice: (EnmoBeaconDetail *) beacon rule: (EnmoRule *) rule
{
//	NSString * key = [ [ beacon.deviceUUID stringByReplacingOccurrencesOfString: @"-" withString: @"" ] lowercaseString ];
//	key = [ key stringByAppendingFormat: @"%0.2d%0.2d", beacon.deviceMajor.intValue, beacon.deviceMinor.intValue ];

//	if(beacon.isFujitsu)
//		return;

	bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
			  ^
			  {
				  [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in readDataFromIoTDevice: %f", [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];
				  [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
				  bgTask = UIBackgroundTaskInvalid;
			  }];

	NSString * key = beacon.isFujitsu ? KEY_FJ : [ [ NSString stringWithFormat: @"%@%@", beacon.deviceIDA, beacon.deviceIDB ] lowercaseString ];

	BLEDevice * device = _dictBLEDevices[key];

	if(_dictRules == nil) _dictRules = [[NSMutableDictionary alloc] init];

	if(rule && beacon) _dictRules[key] = @[rule, beacon];

	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: readDataFromIoTDevice key: %@", key ]];

	if(device == nil)
	{
		[ RulesManager showTestLocalNotificationWithText: @"IoT: device=nil: shld conct=1" ];
		// Should connect device when firstly discovered
		shouldConnectDeviceUponDiscovery = YES;
	}
	else
	{
		[ RulesManager showTestLocalNotificationWithText: @"IoT: device!=nil: connecting" ];
		[ _eddystoneScanner connectBLEDevice: device ];
	}
}

//==============================================================================
- ( void ) readDataFromEddystoneIoTDevice: (EnmoBeaconDetail *) beacon
									 rule: (EnmoRule *) rule
{
	//	NSString * key = [ [ beacon.deviceUUID stringByReplacingOccurrencesOfString: @"-" withString: @"" ] lowercaseString ];
	//	key = [ key stringByAppendingFormat: @"%0.2d%0.2d", beacon.deviceMajor.intValue, beacon.deviceMinor.intValue ];

	bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
			  ^
			  {
				  [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in readDataFromEddystoneIoTDevice: %f", [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];
				  [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
				  bgTask = UIBackgroundTaskInvalid;
			  }];

	NSString * key = [ [ NSString stringWithFormat: @"%@%@", beacon.deviceIDA, beacon.deviceIDB ] lowercaseString ];

	BLEDevice * device = _dictBLEDevices[[key lowercaseString]];

	if( _dictRules == nil )
		_dictRules = [ [ NSMutableDictionary alloc ] init ];

	if(rule && beacon)
		_dictRules[key] = @[rule, beacon];

	[ _eddystoneScanner connectBLEDevice: device ];
}

/*
//==============================================================================
- ( void ) onNoPeripheralTimer: ( NSTimer * ) timer
{
	NSDictionary * userInfo = [ timer userInfo ];
	NSString * key = userInfo[@"key"];

	BLEDevice * device = _dictBLEs[[key lowercaseString]];

	if( _dictRules == nil )
		_dictRules = [ [ NSMutableDictionary alloc ] init ];

	bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
			  ^
			  {
				  [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in connectBLEDevice:%f", [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];
				  [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
				  bgTask = UIBackgroundTaskInvalid;
			  }];

	[ _eddystoneScanner connectBLEDevice: device ];
}
*/

#pragma mark - Data Parsing Delegates

//==============================================================================
- ( void ) bleDevice: (BLEDevice *) device didReceiveDuration: (NSNumber *) duration
{
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: Read Duration: %@", duration ] ];
	[ _eddystoneScanner disconnectBLEDevice:device];
	[_dictBLEDevices removeObjectForKey: device.key ];

	NSArray * params = _dictRules[[device.key lowercaseString]];

	if(params.count == 2)
	{
		NSMutableArray * params2 = [ [ NSMutableArray alloc ] init ];
		[ params2 addObject: params[0] ];
		[ params2 addObject: params[1] ];
		[ params2 addObject: duration ? duration : [ NSNumber numberWithUnsignedInteger: 0 ] ];

		[ [ RulesManager shared ] performSelectorOnMainThread: @selector( processTIRuleWithParamsDuration: )
												   withObject: params2
												waitUntilDone: NO ];

		[ _dictRules removeObjectForKey: device.key ];
	}

	[ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
	bgTask = UIBackgroundTaskInvalid;

}

//==============================================================================
- ( void ) bleDevice: ( BLEDevice * ) device didReceiveRecordsFromST: ( NSArray * ) records
{
	NSLog( @"STM TAG => didReceiveRecordsFromST: %@", records );
	[ RulesManager showTestLocalNotificationWithText: @"STM Tag: Did Read Records" ];
	[ _eddystoneScanner disconnectBLEDevice:device];
	[_dictBLEDevices removeObjectForKey: device.key ];

	int numRecords = 0;
	NSString * recordsString = @"";

	for(int n = 0; n < MIN(50,records.count); n++)
	{
		NSString * string = records[n];
		if(string.length == 29*2)
		{
			numRecords++;

			NSData * data = nil;
			char scratchVal[256];
//						press		hum		temp2	temp1	accX	accY	accZ	gyrX	gyrY	gyrZ	magX	magY	magZ
//			string = @"d7880100		d002	0c01	1101	27ff	edff	d103	f2ff	1400	1c00	9800	b6fe	0100";
//                     96860100     6402    3601    2901    a4ff    6dff    2804    0e00    e3ff    0200    10ff    73ff    33fc 2b
			NSString * pressureString = [string substringWithRange: NSMakeRange(0, 6)]; // 0...5 // really - 8, but use 6 to be as for TI - just for now
			NSString * humidityString = [string substringWithRange: NSMakeRange(8, 4)]; // 8...11
			NSString * tempString = [ string substringWithRange: NSMakeRange(12, 8) ];  // 12...19
			NSString * accString = [string substringWithRange: NSMakeRange(20, 12)];    // 20...31
			NSString * gyroString = [string substringWithRange: NSMakeRange(32, 12)];   // 32...43
			NSString * magString = [string substringWithRange: NSMakeRange(44, 12)];    // 44...55

			NSString * finalTIString = [NSString stringWithFormat: @"%@%@%@%@0000%@000000%@00000",
										tempString, gyroString, accString, magString, humidityString, pressureString];
			NSLog(@"FINAL STM STRING: %@, length: %ld", finalTIString, (unsigned long)finalTIString.length);
			recordsString = [recordsString stringByAppendingString:finalTIString];

			{
				// Object temperature
				NSString * objectTempFull = [ string substringWithRange: NSMakeRange(12, 4) ];
				data = [ EddystoneManager dataFromHexString: objectTempFull ];
				[ data getBytes: &scratchVal length:data.length ];
				int16_t objTemp = ((scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00));

				// Ambient temperature first
				NSString * ambientTempFull = [ string substringWithRange: NSMakeRange(16, 4) ];
				data = [ EddystoneManager dataFromHexString: ambientTempFull ];
				[ data getBytes: &scratchVal length:data.length ];
				int16_t ambTemp = ((scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00));

				float objectTemperature = (float)objTemp;
				float ambientTemperature = (float)ambTemp;

				NSLog( @"\nTemp 2: %0.1f°C, Temp 1: %0.1f°C", objectTemperature, ambientTemperature );
			}

			{
				NSString * movementFull = [string substringWithRange: NSMakeRange(20, 36)];
				data = [ EddystoneManager dataFromHexString: movementFull ];
				[data getBytes:scratchVal length:data.length];

				typedef struct Point3D_ {
					CGFloat x,y,z;
				} Point3D;

				Point3D accPoint;
				Point3D gyroPoint;
				Point3D magPoint;

//				accPoint.x = (float)((scratchVal[0] & 0xFF) | ((scratchVal[1] << 8) & 0xFF00));
//				accPoint.y = (float)((scratchVal[2] & 0xFF) | ((scratchVal[3] << 8) & 0xFF00));
//				accPoint.z = (float)((scratchVal[4] & 0xFF) | ((scratchVal[5] << 8) & 0xFF00));

				accPoint.x = (((float)((int16_t)((scratchVal[0] & 0xff) | (((int16_t)scratchVal[1] << 8) & 0xff00)))/ (float) 32768) * 8) * 1;
				accPoint.y = (((float)((int16_t)((scratchVal[2] & 0xff) | (((int16_t)scratchVal[3] << 8) & 0xff00))) / (float) 32768) * 8) * 1;
				accPoint.z = (((float)((int16_t)((scratchVal[4] & 0xff) | (((int16_t)scratchVal[5] << 8) & 0xff00)))/ (float) 32768) * 8) * 1;

				gyroPoint.x = (float)((scratchVal[6] & 0xFF)  | (((int16_t)scratchVal[7] << 8) & 0xFF00));
				gyroPoint.y = (float)((scratchVal[8] & 0xFF)  | (((int16_t)scratchVal[9] << 8) & 0xFF00));
				gyroPoint.z = (float)((scratchVal[10] & 0xFF) | (((int16_t)scratchVal[11] << 8) & 0xFF00));

				magPoint.x = (float)((scratchVal[12] & 0xFF) | (((int16_t)scratchVal[13] << 8) & 0xFF00));
				magPoint.y = (float)((scratchVal[14] & 0xFF) | (((int16_t)scratchVal[15] << 8) & 0xFF00));
				magPoint.z = (float)((scratchVal[16] & 0xFF) | (((int16_t)scratchVal[17] << 8) & 0xFF00));

				NSLog(@"\nACC : X: %f, Y: %f, Z: %f\nMAG : X: %f, Y: %f, Z: %f\nGYR : X: %f, Y: %f, Z: %f",
					  accPoint.x,accPoint.y,accPoint.z,magPoint.x,magPoint.y,magPoint.z,gyroPoint.x,gyroPoint.y,gyroPoint.z);
			}

			{
				NSString * humidityFull = [string substringWithRange: NSMakeRange(8, 4)];
				data = [ EddystoneManager dataFromHexString: humidityFull ];
				[data getBytes:&scratchVal length:data.length];

				UInt16 humidity = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);

				NSLog(@"Humidity: %0.1f",(float)humidity/10.0);
			}

			{
				NSString * barometerFull = [string substringWithRange: NSMakeRange(0, 8)];
				data = [ EddystoneManager dataFromHexString: barometerFull ];
				[data getBytes:&scratchVal length:data.length];

				uint32_t press = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00) | ((scratchVal[2] << 16) & 0xff0000);
				NSLog(@"Pressure: %0.1f mBar",(float)press/100.0);
			}

		} // if(string.length == 28*2)
	} // for(int n = 0; n < records.count; n++)

	NSArray * params = _dictRules[[device.key lowercaseString]];

	if(params.count == 2)
	{
		NSMutableArray * params2 = [ [ NSMutableArray alloc ] init ];
		[ params2 addObject: params[0] ];
		[ params2 addObject: params[1] ];
		[ params2 addObject: [ recordsString stringByAppendingFormat: @"---%@---%d", device ? device.firmwareVersion : @"Unknown" , numRecords ] ];

		[ [ RulesManager shared ] performSelectorOnMainThread: @selector( processTIRuleWithParams: )
												   withObject: params2
												waitUntilDone: NO ];

		[ _dictRules removeObjectForKey: device.key ];
	}

	if(recordsString.length == 0)
	{
		NSLog(@"EMPTY RECORDS STRING");
	}

	[ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
	bgTask = UIBackgroundTaskInvalid;
}

//==============================================================================
- ( void ) bleDevice: ( BLEDevice * ) device didReceiveRecordsFromFJ: ( NSArray * ) records
{
    // TODO: FUJITSU - test and polish parsing

    NSLog(@"Fujitsu TAG => didReceiveRecordsFromFJ:\nkey: %@ \n%@", device.key, records);

    [ RulesManager showTestLocalNotificationWithText: @"FJS Tag: Did Read Records" ];
    [ _eddystoneScanner disconnectBLEDevice:device]; // Konstantin: FJ disconnects by itself seems, but in another version of FW - seems not.
	[_dictBLEDevices removeObjectForKey: KEY_FJ ];

    int numRecords = 0;
    NSString * recordsString = @"";

    for(int n = 0; n < MIN(50,records.count); n++)
    {
        NSString * string = records[n];
        if(string.length == 16) // Fujitsu has 10 bytes for 1 data chunk
        {
            numRecords++;

            NSData * data = nil;
            char scratchVal[256];

            NSString * accString = [string substringWithRange: NSMakeRange(4, 12)];
            NSString * tempString = [ string substringWithRange: NSMakeRange(0, 4) ];

//            NSString * tempStringSwapped = [NSString stringWithFormat: @"%@%@",
//                                            [tempString substringWithRange: NSMakeRange(2, 2)],
//                                            [tempString substringWithRange: NSMakeRange(0, 2)]
//                                            ];
            NSString * finalTIString = [NSString stringWithFormat: @"0000%@000000000000%@0000000000000000000000000000000000000",
                                        tempString,
                                        accString];
            NSLog(@"FINAL FJS STRING: %@, length: %ld", finalTIString, (unsigned long)finalTIString.length);
            recordsString = [recordsString stringByAppendingString:finalTIString];

            {
                // Object temperature
//                NSString * objectTempFull = [ string substringWithRange: NSMakeRange(0, 4) ];
                data = [EddystoneManager dataFromHexString: tempString];
                [ data getBytes: &scratchVal length:data.length ];
                float objTemp = (((float)((int16_t)((scratchVal[0] & 0xFF) | (((int16_t)scratchVal[1] << 8) & 0xFF00)))/ (float) 333.872744140625)) + 21.0;
                NSLog( @"\nTemperature: %0.1f°C", objTemp );
            }

            {
                NSString * movementFull = [string substringWithRange: NSMakeRange(4, 12)];
                data = [ EddystoneManager dataFromHexString: movementFull ];
                [data getBytes:scratchVal length:data.length];

                typedef struct Point3D_ {
                    CGFloat x,y,z;
                } Point3D;

                Point3D accPoint;
                accPoint.x = (((float)((int16_t)((scratchVal[0] & 0xFF) | (((int16_t)scratchVal[1] << 8) & 0xFF00))) / 2048.0)) * 1;
                accPoint.y = (((float)((int16_t)((scratchVal[2] & 0xFF) | (((int16_t)scratchVal[3] << 8) & 0xFF00))) / 2048.0)) * 1;
                accPoint.z = (((float)((int16_t)((scratchVal[4] & 0xFF) | (((int16_t)scratchVal[5] << 8) & 0xFF00))) / 2048.0)) * 1;

                NSLog(@"\nACC : X: %f, Y: %f, Z: %f", accPoint.x,accPoint.y,accPoint.z);
            }
        } // if(string.length == 20)
    } // for(int n = 0; n < records.count; n++)
    
    NSArray * params = _dictRules[KEY_FJ];
    
    if(params.count == 2)
    {
        NSMutableArray * params2 = [ [ NSMutableArray alloc ] init ];
        [ params2 addObject: params[0] ];
        [ params2 addObject: params[1] ];
        [ params2 addObject: [ recordsString stringByAppendingFormat: @"---%@---%d", device.firmwareVersion ? device.firmwareVersion : @"Unknown" , numRecords ] ];
        
        [ [ RulesManager shared ] performSelectorOnMainThread: @selector( processTIRuleWithParams: )
                                                   withObject: params2
                                                waitUntilDone: NO ];
        
        [ _dictRules removeObjectForKey: KEY_FJ ];
    }
    
    if(recordsString.length == 0)
    {
        NSLog(@"EMPTY RECORDS STRING");
    }
    
    [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
    bgTask = UIBackgroundTaskInvalid;
}

//==============================================================================
- ( void ) bleDevice: ( BLEDevice * ) device didReceiveRecordsFromTI: ( NSArray * ) records
{
	NSLog( @"TI TAG => didReceiveRecordsFromTI: %@", records );
	[ RulesManager showTestLocalNotificationWithText: @"IoT: TI read records" ];
	[ _eddystoneScanner disconnectBLEDevice:device];
	[_dictBLEDevices removeObjectForKey: device.key ];

//	[_dictBLEDevices removeObjectForKey: KEY_FJ ];

	NSLog(@"DEVICE KEY 4: %@", device.key);

	int numRecords = 0;
	NSString * recordsString = @"";

	 //	for(int n = 0; n < (records.count >= 30 ? 20 : records.count); n++)
	for(int n = 0; n < records.count; n++)
	{
		NSString * string = records[n];
		if(string.length == 69)
		{
			recordsString = [recordsString stringByAppendingString:string];

			numRecords++;

			// NOTE: Konstantin:
			// Perform some test processing
			NSData * data = nil;
			char scratchVal[256];

//			string = @"D40CA40CFD0542A22E1DB02DA830B414E5000DF916F53062F49CD40900648C015B020";

			{
				NSString * objectTempFull = [ string substringWithRange: NSMakeRange(0, 8) ];
				data = [ EddystoneManager dataFromHexString: objectTempFull ];
				[ data getBytes: &scratchVal length:data.length ];

				int16_t ambTemp;
				int16_t objTemp;
				float tObj;

				// Ambient temperature first
				ambTemp = ((scratchVal[2] & 0xff)| ((scratchVal[3] << 8) & 0xff00));
				// Then object temperature
				objTemp = ((scratchVal[0] & 0xff)| ((scratchVal[1] << 8) & 0xff00));
				objTemp >>= 2;
				tObj = ((float)objTemp) * 0.03125;

				float objectTemperature = tObj;
				float ambientTemperature = ambTemp / 128.0f;

				NSLog( @"\nIR Temp Ambient: %0.1f°C, IR Temp Object: %0.1f°C", ambientTemperature, objectTemperature );
			}

			{
				NSString * movementFull = [string substringWithRange: NSMakeRange(8, 36)];
				data = [ EddystoneManager dataFromHexString: movementFull ];
				[data getBytes:scratchVal length:data.length];

				typedef struct Point3D_ {
					CGFloat x,y,z;
				} Point3D;

				Point3D gyroPoint;

				gyroPoint.x = ((float)((int16_t)((scratchVal[0] & 0xff) | (((int16_t)scratchVal[1] << 8) & 0xff00)))/ (float) 32768) * 255 * 1;
				gyroPoint.y = ((float)((int16_t)((scratchVal[2] & 0xff) | (((int16_t)scratchVal[3] << 8) & 0xff00)))/ (float) 32768) * 255 * 1;
				gyroPoint.z = ((float)((int16_t)((scratchVal[4] & 0xff) | (((int16_t)scratchVal[5] << 8) & 0xff00)))/ (float) 32768) * 255 * 1;

				Point3D accPoint;

				accPoint.x = (((float)((int16_t)((scratchVal[6] & 0xff) | (((int16_t)scratchVal[7] << 8) & 0xff00)))/ (float) 32768) * 8) * 1;
				accPoint.y = (((float)((int16_t)((scratchVal[8] & 0xff) | (((int16_t)scratchVal[9] << 8) & 0xff00))) / (float) 32768) * 8) * 1;
				accPoint.z = (((float)((int16_t)((scratchVal[10] & 0xff) | (((int16_t)scratchVal[11] << 8) & 0xff00)))/ (float) 32768) * 8) * 1;

				Point3D magPoint;
				magPoint.x = (((float)((int16_t)((scratchVal[12] & 0xff) | (((int16_t)scratchVal[13] << 8) & 0xff00))) / (float) 32768) * 4912);
				magPoint.y = (((float)((int16_t)((scratchVal[14] & 0xff) | (((int16_t)scratchVal[15] << 8) & 0xff00))) / (float) 32768) * 4912);
				magPoint.z = (((float)((int16_t)((scratchVal[16] & 0xff) | (((int16_t)scratchVal[17] << 8) & 0xff00))) / (float) 32768) * 4912);

				NSLog(@"\nACC : X: %+6.1f, Y: %+6.1f, Z: %+6.1f\nMAG : X: %+6.1f, Y: %+6.1f, Z: %+6.1f\nGYR : X: %+6.1f, Y: %+6.1f, Z: %+6.1f",
					  accPoint.x,accPoint.y,accPoint.z,magPoint.x,magPoint.y,magPoint.z,gyroPoint.x,gyroPoint.y,gyroPoint.z);
			}

			{
				NSString * humidityFull = [string substringWithRange: NSMakeRange(44, 8)];
				data = [ EddystoneManager dataFromHexString: humidityFull ];
				[data getBytes:&scratchVal length:data.length];

				UInt16 temp = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
				float tmp = ((double)(int16_t)temp / 65536)*165 - 40;

				UInt16 hum = (scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00);
				float humidity = (float)((float)hum/(float)65535) * 100.0f;

				NSLog(@"Humidity: %0.1f%%rH; Temperature: %0.1f",(float)humidity, tmp);
			}

			{
				NSString * barometerFull = [string substringWithRange: NSMakeRange(52, 12)];
				data = [ EddystoneManager dataFromHexString: barometerFull ];
				[data getBytes:&scratchVal length:data.length];

				uint32_t temp = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00) | ((scratchVal[2] << 16) & 0xff0000);
				float tmp = temp / 100.0f;

				uint32_t pres = (scratchVal[3] & 0xff) | ((scratchVal[4] << 8) & 0xff00) | ((scratchVal[5] << 16) & 0xff0000);
				float airPressure =  (float)pres / 100.0f;

				NSLog(@"Pressure: %0.1f mBar; Temperature: %0.1f",(float)airPressure, (float)tmp);
			}

			{
				NSString * optFull = [string substringWithRange: NSMakeRange(64, 4)];
				data = [ EddystoneManager dataFromHexString: optFull ];
				[data getBytes:scratchVal length:data.length];
				uint16_t dat;
				dat = ((uint16_t)scratchVal[1] & 0xFF) << 8;
				dat |= (uint16_t)(scratchVal[0] & 0xFF);

				float lightLevel = (float)[EddystoneManager sfloatExp2ToDouble:dat];
				NSLog(@"Amb: %0.1f Lux",(float)lightLevel);
			}

			{
				NSString * relay = [string substringWithRange: NSMakeRange(68, 1)];
				NSLog(@"reedRelay: %@", relay.intValue > 0 ? @"ON " : @"OFF");
			}

		} // if(string.length == 69)
	} // for(int n = 0; n < records.count; n++)

	NSArray * params = _dictRules[[device.key lowercaseString]];
//	params = _dictRules[KEY_FJ];

	if(params.count == 2)
	{
		NSMutableArray * params2 = [ [ NSMutableArray alloc ] init ];
		[ params2 addObject: params[0] ];
		[ params2 addObject: params[1] ];
		[ params2 addObject: [ recordsString stringByAppendingFormat: @"---%@---%d", device ? device.firmwareVersion : @"Unknown" , numRecords ] ];

		[ [ RulesManager shared ] performSelectorOnMainThread: @selector( processTIRuleWithParams: )
												   withObject: params2
												waitUntilDone: NO ];

		[ _dictRules removeObjectForKey: device.key ];
	}

	[ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
	bgTask = UIBackgroundTaskInvalid;
}

#pragma mark - Data Conversion
+ ( NSData * ) dataFromHexString: ( NSString * ) hexString
{
	if(hexString == nil)
		return nil;

	hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];

	NSMutableData *hexData= [[NSMutableData alloc] init];
	unsigned char whole_byte;
	char byte_chars[3] = {'\0','\0','\0'};
	int i;

	for (i=0; i < [hexString length]/2; i++) {
		byte_chars[0] = [hexString characterAtIndex:i*2];
		byte_chars[1] = [hexString characterAtIndex:i*2+1];
		whole_byte = strtol(byte_chars, NULL, 16);
		[hexData appendBytes:&whole_byte length:1];
	}

	NSLog(@"%@", hexData);

	return hexData;
}


+ ( double ) sfloatExp2ToDouble: ( uint16_t ) sfloat
{
	uint16_t mantissa;
	uint8_t exponent;

	mantissa = sfloat & 0x0FFF;
	exponent = sfloat >> 12;

#ifdef SIGNED
	if (exponent >= 0x0008) {
		exponent = -((0x000F + 1) - exponent);
	}
#endif

#ifdef SIGNED
	if (mantissa >= 0x0800) {
		mantissa = -((0x0FFF + 1) - mantissa);
	}
#endif

	double output;
	double magnitude = pow(2.0f, exponent);
	output = (mantissa * magnitude);

	return output / 100.0f;
}

@end
