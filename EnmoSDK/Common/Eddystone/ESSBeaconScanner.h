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

#import <Foundation/Foundation.h>

@class ESSBeaconScanner;

// Delegates to the ESSBeaconScanner should implement this protocol.
@protocol ESSBeaconScannerDelegate <NSObject>

@optional

- (void)beaconScanner:(ESSBeaconScanner *)scanner
        didFindBeacon:(id)beaconInfo;
- (void)beaconScanner:(ESSBeaconScanner *)scanner
        didLoseBeacon:(id)beaconInfo;

- (void)beaconScanner:(ESSBeaconScanner *)scanner
      didUpdateBeacon:(id)beaconInfo;

- (void)beaconScanner:(ESSBeaconScanner *)scanner
 didFindBLEPeripheral:(CBPeripheral*)peripheral
		withAdvPacket: ( NSDictionary * ) advPacket;

//- (void)beaconScanner:(ESSBeaconScanner *)scanner
// didLooseBLEPeripheral:(CBPeripheral*)peripheral;

- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner
didEnterSensorTagWithIdA: ( NSString * ) idA
				  andIdB: ( NSString * ) idB
			  peripheral: ( CBPeripheral * ) peripheral;

- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner
 didExitSensorTagWithIdA: ( NSString * ) idA
				  andIdB: ( NSString * ) idB;

- ( void ) beaconScanner: ( ESSBeaconScanner * ) scanner
didUpdateSensorTagWithIdA: ( NSString * ) idA
				  andIdB: ( NSString * ) idB;


@end


@class BLEDevice;


@interface ESSBeaconScanner : NSObject

@property(nonatomic, weak) id<ESSBeaconScannerDelegate> delegate;

@property(nonatomic, assign) NSTimeInterval onLostTimeout;
@property(nonatomic, assign) NSTimeInterval onLostTimeoutBLE;

- (void)startScanning;
- (void)stopScanning;
- (void) connectBLEDevice: (BLEDevice*) device;
- (void) disconnectBLEDevice:(BLEDevice *)device;
- (void) rescheduleTimerForBLEDeviceWithIdA:(NSString *)idA andIdB: ( NSString * ) idB;

@end
