//
//  EddystoneManager.h
//  enmo autolock
//
//  Copyright (c) 2015 enmo Technologies. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "ESSBeaconScanner.h"


@interface EddystoneManager : NSObject < ESSBeaconScannerDelegate >
{
	ESSBeaconScanner * _eddystoneScanner;
}

+ ( EddystoneManager * ) shared;

- ( void ) startScanning;
- ( void ) stopScanning;

- ( void ) readDataFromIoTDevice: ( EnmoBeaconDetail * ) beacon rule: ( EnmoRule * ) rule;
- ( void ) readDataFromEddystoneIoTDevice: (EnmoBeaconDetail *) beacon rule: (EnmoRule *) rule;

@end
