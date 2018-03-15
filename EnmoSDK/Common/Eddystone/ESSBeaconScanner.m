// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <CoreBluetooth/CoreBluetooth.h>

#import "ESSBeaconScanner.h"
#import "ESSEddystone.h"
#import "ESSTimer.h"
#import "BLEDevice.h"


static const char *const kBeaconsOperationQueueName = "kESSBeaconScannerBeaconsOperationQueueName";

static NSString *const kESSEddystoneServiceID = @"FEAA";
//static NSString *const kTIServiceID = @"F000AA80-0451-4000-B000-000000000000";
//static NSString *const kTIServiceID = @"AA80";
//static NSString *const kTIServiceID2 = @"AA00";

static NSString *const kSeenCacheBeaconInfo = @"beacon_info";
static NSString *const kSeenCacheOnLostTimer = @"on_lost_timer";

/**
 *=-----------------------------------------------------------------------------------------------=
 * Private Additions to ESSBeaconScanner
 *=-----------------------------------------------------------------------------------------------=
 */
@interface ESSBeaconScanner () <CBCentralManagerDelegate, CBPeripheralDelegate> {
  CBCentralManager *_centralManager;
  dispatch_queue_t _beaconOperationsQueue;

  /**
   * This cache maps Core Bluetooth deviceIDs to NSData objects containing Eddystone telemetry.
   * Then, the next time we see a UID frame for that Eddystone, we can add the most recently seen
   * telemetry frame to the sighting.
   */
  NSMutableDictionary *_deviceIDCache;

  /**
   * Beacons we've seen already. If we see an Eddystone and notice that we've seen it before, we
   * won't fire a beaconScanner:didFindBeacon:, but instead will fire a
   * beaconScanner:didUpdateBeacon: for those listening (it's optional).
   */
  NSMutableDictionary *_seenEddystoneCache;

	NSMutableDictionary *_seenSensorTagsCache;

  BOOL _shouldBeScanning;
}

@end

/**
 *=-----------------------------------------------------------------------------------------------=
 * Implementation for ESSBeaconScanner
 *=-----------------------------------------------------------------------------------------------=
 */
@implementation ESSBeaconScanner

- (instancetype)init
{
  if ((self = [super init]) != nil)
  {
    _onLostTimeout = 15.0;
	_onLostTimeoutBLE = 20.0;
    _deviceIDCache = [NSMutableDictionary dictionary];
    _seenEddystoneCache = [NSMutableDictionary dictionary];
	  _seenSensorTagsCache = [NSMutableDictionary dictionary];
    _beaconOperationsQueue = dispatch_queue_create(kBeaconsOperationQueueName, NULL);
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                           queue:_beaconOperationsQueue];
  }

  return self;
}

#pragma mark - Scanning Start/Stop
- (void)startScanning
{
  dispatch_async(_beaconOperationsQueue, ^{
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
      NSLog(@"CBCentralManager state is %ld, cannot start or stop scanning",
            (long)_centralManager.state);
      _shouldBeScanning = YES;
    } else {
      NSLog(@"Starting to scan for Eddystones");
      NSArray *services = @[
          [CBUUID UUIDWithString:kESSEddystoneServiceID],
		  [CBUUID UUIDWithString:[BLEDevice TIScanPacketServiceUUID]],
		  [CBUUID UUIDWithString:[BLEDevice FJAdvertisementServiceUUID]] // NOT clear what is here
      ];

      // We do not want multiple discoveries of the same beacon to be coalesced into one.
      // (Unfortunately this is ignored when we are in the background.)
      NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES };
	  // TODO: remove nil later
      [_centralManager scanForPeripheralsWithServices:services options:options];
    }
  });
}

- (void)stopScanning
{
  _shouldBeScanning = NO;
  [_centralManager stopScan];
  [self clearRemainingTimers];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  if (central.state == CBCentralManagerStatePoweredOn && _shouldBeScanning)
  {
    [self startScanning];
  }
}

- (void)clearRemainingTimers
{
	for (ESSBeaconID *beaconID in _seenEddystoneCache)
	{
		[_seenEddystoneCache[beaconID][kSeenCacheOnLostTimer] cancel];
	}

	_seenEddystoneCache = nil;
}

#pragma mark - Discovery
// This will be called from the |beaconsOperationQueue|.
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{

	NSDictionary *serviceData = advertisementData[CBAdvertisementDataServiceDataKey];

	// If it's a telemetry (TLM) frame, then save it into our cache so that the next time we get a
	// UID frame (i.e. an Eddystone "sighting"), we can include the telemetry with it.
	ESSFrameType frameType = [ESSBeaconInfo frameTypeForFrame:serviceData];

	if (frameType == kESSEddystoneTelemetryFrameType)
	{
		_deviceIDCache[peripheral.identifier] = [ESSBeaconInfo telemetryDataForFrame:serviceData];
	}
	else if (frameType == kESSEddystoneUIDFrameType)
	{
		// TODO: remove when done with fujitsu
//		return;

		CBUUID *eddystoneServiceUUID = [ESSBeaconInfo eddystoneServiceID];
		NSData *eddystoneServiceData = serviceData[eddystoneServiceUUID];

		// If we have telemetry data for this Eddystone, include it in the construction of the
		// ESSBeaconInfo object. Otherwise, nil is fine.
		NSData *telemetry = _deviceIDCache[peripheral.identifier];

		ESSBeaconInfo *beaconInfo = [ESSBeaconInfo beaconInfoForUIDFrameData:eddystoneServiceData
																   telemetry:telemetry
																		RSSI:RSSI];

		if (beaconInfo != nil)
		{
			beaconInfo.peripheral = peripheral;

			// NOTE: At this point you can choose whether to keep or get rid of the telemetry data. You
			//       can either opt to include it with every single beacon sighting for this beacon, or
			//       delete it until we get a new / "fresh" TLM frame. We'll treat it as "report it only
			//       when you see it", so we'll delete it each time.
			[_deviceIDCache removeObjectForKey:peripheral.identifier];

			// If we haven't seen this Eddystone before, fire a beaconScanner:didFindBeacon: and mark it as seen.
			if (!_seenEddystoneCache[beaconInfo.beaconID])
			{
//				[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"ESS ENTRY" ] ];

				if ([_delegate respondsToSelector:@selector(beaconScanner:didFindBeacon:)])
					[_delegate beaconScanner:self didFindBeacon:beaconInfo];

				ESSTimer *onLostTimer = [ESSTimer scheduledTimerWithDelay:_onLostTimeout
																  onQueue:dispatch_get_main_queue()
																	block:^(ESSTimer *timer)
				{
					ESSBeaconInfo *lostBeaconInfo = _seenEddystoneCache[beaconInfo.beaconID][kSeenCacheBeaconInfo];

					if (lostBeaconInfo)
					{
						if ([_delegate respondsToSelector:@selector(beaconScanner:didLoseBeacon:)])
						{
//							[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"ESS EXIT" ] ];
							[_delegate beaconScanner:self didLoseBeacon:lostBeaconInfo];
						}
						[_seenEddystoneCache removeObjectForKey:beaconInfo.beaconID];
				  }
				}
										 ];

				_seenEddystoneCache[beaconInfo.beaconID] = @{kSeenCacheBeaconInfo: beaconInfo,
															 kSeenCacheOnLostTimer: onLostTimer,};
			} // if (!_seenEddystoneCache[beaconInfo.beaconID])
			else
			{
				// Reset the onLost timer.
				[_seenEddystoneCache[beaconInfo.beaconID][kSeenCacheOnLostTimer] reschedule];

				// Otherwise, we've seen it, so fire a beaconScanner:didUpdateBeacon: instead.
				if ([_delegate respondsToSelector:@selector(beaconScanner:didUpdateBeacon:)])
				{
					[_delegate beaconScanner:self didUpdateBeacon:beaconInfo];
				}
			}
		} // if (beaconInfo != nil)
	} // else if (frameType == kESSEddystoneUIDFrameType)

#ifdef ATMIO
	else
	{
		// NOTE: Konstantin
		// Here we handle tracking of our custom BLE devices in -IoT Over Beacon™- mode
		if( [ _delegate respondsToSelector: @selector( beaconScanner: didFindBLEPeripheral:withAdvPacket: ) ] )
			[_delegate beaconScanner: self didFindBLEPeripheral: peripheral withAdvPacket: advertisementData ];
	}
#endif

}

#pragma mark - Connect/Disconnect
- ( void ) connectBLEDevice:(BLEDevice *)device
{
	NSLog( @"CONNECTING IoT => %@", device.key );
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: CONNECTING: %@", device.key ] ];

	if(device == nil)
		return;

	[_centralManager connectPeripheral:device.cbPeripheral options:nil];
}

- ( void ) disconnectBLEDevice:(BLEDevice *)device
{
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"IoT: DISCONNECTING: %@", device.key ] ];

	if(device == nil)
		return;

	[_centralManager cancelPeripheralConnection:device.cbPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	[ RulesManager showTestLocalNotificationWithText: @"IoT: Did Connect, Reading" ];

	[peripheral discoverServices:@[
								   // 2 services for TI FW
								   [CBUUID UUIDWithString: [BLEDevice TIMovementServiceUUID] ],
								   [CBUUID UUIDWithString: [BLEDevice TITemperatureServiceUUID] ],
								   // 1 service for STM Nucleo FW
								   [CBUUID UUIDWithString: [BLEDevice STMNotifyServiceUUID] ],
                                   // 1 service for Fujitsu
								   [CBUUID UUIDWithString: [BLEDevice FJNotifyServiceUUID] ],
								   ]];
}

- ( void ) centralManager: ( CBCentralManager * ) central
didFailToConnectPeripheral: ( CBPeripheral * ) peripheral
					error: ( nullable NSError * ) error
{
	[ RulesManager showTestLocalNotificationWithText: @"IoT: Connection Failed" ];
}

- ( void ) centralManager:(CBCentralManager *)central
  didDisconnectPeripheral:(CBPeripheral *)peripheral
					error:(NSError *)error
{
	[ RulesManager showTestLocalNotificationWithText: @"IoT: Did Disconnect" ];
}

#pragma mark - Timers
- (void) rescheduleTimerForBLEDeviceWithIdA:(NSString *)idA andIdB: ( NSString * ) idB
{
	NSString * uuid = [ [ idA stringByAppendingString: idB ] lowercaseString ];
	NSLog(@"RESCHEDULING TI TAG: %@ : %@", [idA lowercaseString], [idB lowercaseString]);
	[_seenSensorTagsCache[uuid][kSeenCacheOnLostTimer] reschedule];
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
	
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
	
}

@end
