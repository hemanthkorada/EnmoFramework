//
//  BLEDevice+CBPeripheralDelegate.m
//  enmo
//


#import "BLEDevice+CBPeripheralDelegate.h"


CBCharacteristic * cbCharacteristicTempConfig = nil;
CBCharacteristic * cbCharacteristicMovData = nil;
CBCharacteristic * cbCharacteristicNotify = nil;
CBCharacteristic * cbCharacteristicFJWrite = nil;

@implementation BLEDevice ( CBPeripheralDelegate )

#pragma mark - CBPeripheralDelegate

//==============================================================================
- ( void ) peripheral: ( CBPeripheral * ) peripheral
  didDiscoverServices: ( NSError * ) error
{
    [ self.dictGATTServices removeAllObjects ];
    [ self.dictGATTCharacteristics removeAllObjects ];

    [ self.cbPeripheral.services enumerateObjectsUsingBlock:
        ^ ( CBService * cbService, NSUInteger idx, BOOL * stop )
        {
            BLEService * service = [ [ BLEService alloc ] initWithCBService: cbService ];

            [ self.dictGATTServices setObject: service forKey: [ cbService.UUID UUIDString ] ];
            [ self.dictGATTCharacteristics removeAllObjects ];

			[ peripheral discoverCharacteristics: nil forService: cbService ];
        }
     ];

	[ _arrayDelegates enumerateObjectsUsingBlock:
		^ ( id < BLEDeviceDelegate > delegate, NSUInteger idx, BOOL * stop )
		{
			if( [ delegate respondsToSelector: @selector( bleDeviceDidDiscoverServices: ) ] )
				[ delegate bleDeviceDidDiscoverServices: self ];
		}
	 ];
}

//==============================================================================
- ( void ) peripheral: ( CBPeripheral * ) peripheral
didDiscoverCharacteristicsForService: ( CBService * ) cbService
                error: ( NSError * ) error
{
	NSLog( @"didDiscoverCharacteristicsForService: %@", [ cbService.UUID UUIDString ] );

    __block BLEService * service = [ self.dictGATTServices objectForKey: [ cbService.UUID UUIDString ] ];

    for( CBCharacteristic * cbCharacteristic in cbService.characteristics )
	{
		BLECharacteristic * characteristic = [ [ BLECharacteristic alloc ] initWithCBCharacteristic: cbCharacteristic ];

		NSLog( @"didDiscoverCharacteristic: %@, Is Writable: %@, Is Notify: %@, Is Readable: %@",
			  [ cbCharacteristic.UUID UUIDString ],
			  characteristic.isWritable ? @"YES" : @"NO",
			  characteristic.isNotify ? @"YES" : @"NO",
			  characteristic.isReadable ? @"YES" : @"NO"
			  );

		[ service.dictCharacteristics setObject: characteristic
										 forKey: [ cbCharacteristic.UUID UUIDString ] ];

		[ self.dictGATTCharacteristics setObject: characteristic
										  forKey: [ cbCharacteristic.UUID UUIDString ] ];

		if( [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice TIMovementCharacteristicUUID] ] )
		{
			[ peripheral setNotifyValue: YES forCharacteristic: cbCharacteristic ];
			cbCharacteristicMovData = cbCharacteristic;
		}

		if(   [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice TINotifyCharacteristicUUID] ]
           || [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice STMNotifyCharacteristicUUID] ]
           || [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice FJSNotifyCharacteristicUUID] ] )
		{
            // TODO: FUJITSU - when we will know which method will be used to wake up writing from device
            // - modify here or below (f.e. send command bytes as for TI)

			sensorsData = nil;
			[ peripheral setNotifyValue: YES forCharacteristic: cbCharacteristic ];
			cbCharacteristicNotify = cbCharacteristic;
		}

		if( [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice FJSWriteCharacteristicUUID] ] )
		{
			[ peripheral setNotifyValue: YES forCharacteristic: cbCharacteristic ];
			cbCharacteristicFJWrite = cbCharacteristic;
		}

		if( [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice TITemperatureCharacteristicUUID] ] )
			cbCharacteristicTempConfig = cbCharacteristic;

		if(cbCharacteristicMovData && cbCharacteristicTempConfig)
		{
			UInt8 bytes[1] = { 0xFE };
			NSData * data = [ NSData dataWithBytes: &bytes length: 1 ];
			[ peripheral writeValue: data forCharacteristic: cbCharacteristicTempConfig type: CBCharacteristicWriteWithResponse ];
		}

		if(cbCharacteristicFJWrite)
		{
			UInt8 bytes[1] = { 0xFF };
			NSData * data = [ NSData dataWithBytes: &bytes length: 1 ];
			[ peripheral writeValue: data forCharacteristic: cbCharacteristicFJWrite type: CBCharacteristicWriteWithResponse ];
		}

	} // for( CBCharacteristic * cbCharacteristic in cbService.characteristics )

	for( id < BLEDeviceDelegate > delegate in _arrayDelegates )
	{
		if( [ delegate respondsToSelector: @selector( bleDevice: didDidDiscoverCharacteristicsForService: ) ] )
			[ delegate bleDevice: self didDidDiscoverCharacteristicsForService: service ];
	}
}


NSMutableData * sensorsData = nil;

//==============================================================================
- ( void ) peripheral: ( CBPeripheral * ) peripheral
didUpdateValueForCharacteristic: ( CBCharacteristic * ) cbCharacteristic
                error: ( NSError * ) error
{
	NSData * data = cbCharacteristic.value;
	NSLog( @"\nDidUpdateValueForCharacteristic: %@, data %@", cbCharacteristic.UUID, data );

	// Convert bytes to hex string
	NSUInteger capacity = data.length * 2;
	NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
	const unsigned char *buf = data.bytes;
	NSInteger i;
	for (i=0; i<data.length; ++i)
	{
		[sbuf appendFormat:@"%02X", buf[i]];
	}

	NSLog(@"sbuf: %@", sbuf);

	static BOOL shouldIgnoreFirstData = NO;
	static BOOL canAppendData = NO;

	uint32_t value[1];

	if( [ [ cbCharacteristic.UUID UUIDString ] isEqualToString: [BLEDevice TIMovementCharacteristicUUID] ] )
		canAppendData = YES;

	// Check which device it is - in future - move it to separate class - so one class for each device
	BOOL isTIBroom = self.name ? [[self.name lowercaseString] rangeOfString: @"broom"].location != NSNotFound : NO;
	BOOL isTISensorTag = self.name ? [[self.name lowercaseString] rangeOfString: @"cc2650"].location != NSNotFound : NO;
	BOOL isST = self.name ? ([[self.name lowercaseString] rangeOfString: @"stm"].location != NSNotFound
                             || [[self.name lowercaseString] rangeOfString: @"sta2em1"].location != NSNotFound
							 || [[self.name lowercaseString] rangeOfString: @"1234567"].location != NSNotFound
							 || [[self.name lowercaseString] rangeOfString: @"enmost"].location != NSNotFound
							 || [[self.name lowercaseString] rangeOfString: @"enmonc"].location != NSNotFound) : NO;
	// TODO: FUJITSU - compare with correct name
//	BOOL isFujitsu = self.name	? [[self.name lowercaseString] rangeOfString: @"fujitsu"].location != NSNotFound
//								: ((self.dictGATTServices[[BLEDevice FJNotifyServiceUUID]] != nil) ? YES : NO );
	BOOL isFujitsu = ((self.dictGATTServices[[BLEDevice FJNotifyServiceUUID]] != nil) ? YES : NO );
	NSLog(@"self.name = %@", self.name);

	if(([sbuf rangeOfString:@"AAAAAAAA"].location != NSNotFound)				// Start bytes for TI devices
	   || (isFujitsu && sensorsData.length == 0)								// Start for Fujitsu devices as they send count of writes to be done
	   )
	{
		sensorsData = [ NSMutableData data ];
		if(isFujitsu)
			[sensorsData appendData:data];

//		shouldIgnoreFirstData = YES;
	}
	else if([sbuf rangeOfString:@"FFEEDDCC"].location != NSNotFound) // Final ("closing") bytes for ALL IoT devices
	{
		NSMutableArray * substrings = [ [ NSMutableArray alloc ] init ];

		// the end - process data
		if(isTIBroom)
		{
			// parse duration
			memcpy(value, (uint32_t *)sensorsData.bytes, sensorsData.length);
			NSLog(@"DURATION: %u", value[0]);

			static uint32_t duration = 0;
			duration = value[0];

			for(id <BLEDeviceDelegate> delegate in _arrayDelegates)
			{
				if( [ delegate respondsToSelector: @selector( bleDevice: didReceiveDuration: ) ] )
					[ delegate bleDevice: self didReceiveDuration: [ NSNumber numberWithUnsignedInteger: duration ] ];
			}
		} // if(isTIBroom)
		else if(isTISensorTag)
		{
			NSUInteger capacity2 = sensorsData.length * 2;
			NSMutableString *sbuf2 = [NSMutableString stringWithCapacity:capacity2];
			const unsigned char *buf2 = sensorsData.bytes;
			NSInteger i2;

			for (i2=0; i2<sensorsData.length; i2++)
			{
				[sbuf2 appendFormat:@"%02x", buf2[i2]];
			}

			// Then - divide string by chunks, 40 chars each.
			// Cut out 68th char and last 27 ones.

			NSUInteger len = sbuf2.length;
			NSUInteger divider = 18*2*2;

			NSMutableString * finalString = [ [ NSMutableString alloc ] init ];

			for (int i = 0; i < len; i += divider)
			{
				if(i + divider > sbuf2.length)
					break;

				// You should do some validation to make sure your location and length is in range f string length
				NSRange ran = NSMakeRange(i, divider);
				NSString * res = [sbuf2 substringWithRange:ran];
				NSUInteger reslen = res.length;

				NSLog( @"res initial: %@ , length %ld", res, (unsigned long)reslen);
				res = [ res stringByReplacingCharactersInRange: NSMakeRange(68, 1) withString: @""];
				NSLog( @"res - removed half byte: %@ , length %ld", res, (unsigned long)res.length);
				res = [ res stringByReplacingCharactersInRange:NSMakeRange(res.length - 2, 2) withString: @""];
				NSLog( @"res - removed tail bytes: %@ , length %ld", res, (unsigned long)res.length);

				[finalString appendString:res];

				[substrings addObject:res];
			}

			NSLog( @"final substrings:\n%@", substrings);
			NSLog( @"final bytes string:\n%@", finalString);

			for(id <BLEDeviceDelegate> delegate in _arrayDelegates)
			{
				if( [ delegate respondsToSelector: @selector( bleDevice: didReceiveRecordsFromTI: ) ] )
					[ delegate bleDevice: self didReceiveRecordsFromTI: substrings ];
			}
		} // else if(isTISensorTag)
		else if(isST)
		{
			NSUInteger capacity2 = sensorsData.length * 2;
			NSMutableString *sbuf2 = [NSMutableString stringWithCapacity:capacity2];
			const unsigned char *buf2 = sensorsData.bytes;
			NSInteger i2;

			for (i2=0; i2<sensorsData.length; i2++)
			{
				[sbuf2 appendFormat:@"%02x", buf2[i2]];
			}

			NSUInteger len = sbuf2.length;
//			NSUInteger divider = 28*2;
			NSUInteger divider = 20*2*2;
			NSUInteger extraBytes = 11*2;

			NSMutableString * finalString = [ [ NSMutableString alloc ] init ];

			for (int i = 0; i < len; i += divider)
			{
				if(i + divider > sbuf2.length)
					break;

				// You should do some validation to make sure your location and length is in range f string length
				NSRange ran = NSMakeRange(i, divider - extraBytes);
				NSString * res = [sbuf2 substringWithRange:ran];
				[finalString appendString:res];
				[substrings addObject:res];
			}

			NSLog( @"final substrings:\n%@", substrings);
			NSLog( @"final bytes string:\n%@", finalString);

			for(id <BLEDeviceDelegate> delegate in _arrayDelegates)
			{
				if( [ delegate respondsToSelector: @selector( bleDevice: didReceiveRecordsFromST: ) ] )
					[ delegate bleDevice: self didReceiveRecordsFromST: substrings ];
			}
		} // else if(isST)

		if(cbCharacteristicTempConfig) [ peripheral setNotifyValue: NO forCharacteristic: cbCharacteristicTempConfig ];
		if(cbCharacteristicMovData) [ peripheral setNotifyValue: NO forCharacteristic: cbCharacteristicMovData ];
		if(cbCharacteristicNotify) [ peripheral setNotifyValue: NO forCharacteristic: cbCharacteristicNotify ];

		sensorsData = [ NSMutableData data ];
	} // else if([sbuf rangeOfString:@"FFEEDDCC"].location != NSNotFound)
	else if([sbuf.lowercaseString rangeOfString:@"ddccbbaa"].location != NSNotFound) // Final ("closing") bytes for Fujitsu devices
	{
		NSMutableArray * substrings = [ [ NSMutableArray alloc ] init ];

		if(isFujitsu)
		{
			NSUInteger capacity2 = sensorsData.length * 2;
			NSMutableString *sbuf2 = [NSMutableString stringWithCapacity:capacity2];
			const unsigned char *buf2 = sensorsData.bytes;
			NSInteger i2;

			for (i2=0; i2<sensorsData.length; i2++) { [sbuf2 appendFormat:@"%02x", buf2[i2]]; }

			NSUInteger len = sbuf2.length;
			NSUInteger divider = 34;

			for (int i = 0; i < len; i += divider)
			{
				if(sbuf2.length == 18) {
					NSString * substring = [sbuf2 substringWithRange:NSMakeRange(0, 18)];
					NSString * values1 = [substring substringWithRange:NSMakeRange(2, 16)];
					[substrings addObject:values1];
					break;
				}
				else if(i + divider > sbuf2.length)
					break;

				// You should do some validation to make sure your location and length is in range f string length
				NSString * substring = [sbuf2 substringWithRange:NSMakeRange(i, divider)];

                NSString * values1 = [substring substringWithRange:NSMakeRange(2, 16)];
                [substrings addObject:values1];
                
                NSString * values2 = [substring substringWithRange:NSMakeRange(18, 16)];
                [substrings addObject:values2];
			}

			NSLog( @"final substrings:\n%@", substrings);

			for(id <BLEDeviceDelegate> delegate in _arrayDelegates)
			{
				if( [ delegate respondsToSelector: @selector( bleDevice: didReceiveRecordsFromFJ: ) ] )
					[ delegate bleDevice: self didReceiveRecordsFromFJ: substrings ];
			}
		} // else if(isFujitsu)

		if(cbCharacteristicNotify)
			[ peripheral setNotifyValue: NO forCharacteristic: cbCharacteristicNotify ];

		sensorsData = [ NSMutableData data ];
	} // else if([sbuf rangeOfString:@"DDCCBBAA"].location != NSNotFound) // Fujitsu
	else
	{
		if(sensorsData == nil)
			sensorsData = [ NSMutableData data ];

//		if(canAppendData && !shouldIgnoreFirstData)
		[sensorsData appendData:data];
		NSLog(@"sensorsData.length %ld", (unsigned long)sensorsData.length);
		shouldIgnoreFirstData = NO;
	}
}

//==============================================================================
- ( void ) peripheral: ( CBPeripheral * ) peripheral
didDiscoverIncludedServicesForService: ( CBService * ) service
				error: ( NSError * ) error
{

}

//==============================================================================
- ( void ) peripheral: ( CBPeripheral * ) peripheral
		  didReadRSSI: ( NSNumber * ) RSSI
				error: ( NSError * ) error
{
	self.RSSI = RSSI;
}

//- ( void ) peripheralDidUpdateName: ( CBPeripheral * ) peripheral {}
//- ( void ) peripheralDidInvalidateServices: ( CBPeripheral * ) peripheral {}
//- ( void ) peripheral: ( CBPeripheral * ) peripheral didModifyServices: ( NSArray * ) invalidatedServices {}
//- ( void ) peripheralDidUpdateRSSI: ( CBPeripheral * ) peripheral error: ( NSError * ) error {}

@end
