//
//  BeaconsManager.m
//  enmo demo
//


#import "BeaconsManager.h"
#import "RulesManager.h"
#import "UIAlerter.h"


BeaconsManager * beaconsManager;
CLLocationManager * gLocationManager;
//CBCentralManager * centralManager;


@implementation BeaconsManager

//==============================================================================
+ ( BeaconsManager * ) shared
{
    if( beaconsManager == nil )
    {
        beaconsManager = [ [ BeaconsManager alloc ] init ];
        gLocationManager = [ [ CLLocationManager alloc ] init ];
        gLocationManager.delegate = beaconsManager;
    }

    return beaconsManager;
}


//==============================================================================
- ( id ) init
{
    self = [ super init ];

    if( self )
    {
        _arrayDelegates = [ [ NSMutableArray alloc ] init ];
        _arrayMonitoredRegions = [ [ NSMutableArray alloc ] init ];
    }

    return self;
}


//==============================================================================
- ( void ) addDelegate: ( id < BeaconsManagerDelegate > ) delegate
{
    if( delegate && ![ _arrayDelegates containsObject: delegate ] )
        [ _arrayDelegates addObject: delegate ];
}


//==============================================================================
- ( void ) removeDelegate: ( id < BeaconsManagerDelegate > ) delegate
{
    [ _arrayDelegates removeObject: delegate ];
}


//==============================================================================
- ( void ) checkLocationPermissions
{
	CLAuthorizationStatus locationAuthStatus = [ CLLocationManager authorizationStatus ];

	//	kCLAuthorizationStatusNotDetermined
	//	The user has not yet made a choice regarding whether this app can use location services.
	//
	//	kCLAuthorizationStatusRestricted
	//	This app is not authorized to use location services. The user cannot change this app’s status, possibly due to active restrictions such as parental controls being in place.
	//
	//	kCLAuthorizationStatusDenied
	//	The user explicitly denied the use of location services for this app or location services are currently disabled in Settings.
	//
	//	kCLAuthorizationStatusAuthorizedAlways
	//	This app is authorized to start location services at any time. This authorization allows you to use all location services, including those for monitoring regions and significant location changes.
	//
	//	kCLAuthorizationStatusAuthorizedWhenInUse
	//	This app is authorized to start most location services while running in the foreground. This authorization does not allow you to use APIs that could launch your app in response to an event, such as region monitoring and the significant location change services.

	if( locationAuthStatus == kCLAuthorizationStatusNotDetermined )
	{
		// Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
		if( [ gLocationManager respondsToSelector: @selector( requestAlwaysAuthorization ) ] )
			[ gLocationManager performSelector: @selector( requestAlwaysAuthorization ) ];
	}
	else if( locationAuthStatus == kCLAuthorizationStatusDenied || locationAuthStatus == kCLAuthorizationStatusRestricted )
	{
		// show an alert
		[ UIAlerter showOkSettingsAlertWithTitle: @"Usage of Location Services is restricted or denied for this App"
										 message: @"Please check your location permissions in Settings -> Location Services!"
										 okBlock: ^{}
								andSettingsBlock:
			 ^
			 {
//				 [ [ UIApplication sharedApplication ] openURL: [ NSURL URLWithString: UIApplicationOpenSettingsURLString ] ];
			 }
		 ];
	}
}


//==============================================================================
- ( void ) startRangingRegionsFromArray: ( NSArray * ) regions
{
	[ self stopRangingForBeacons ];
	[ self checkLocationPermissions ];

	[ [ NSUserDefaults standardUserDefaults ] setObject: ( regions ? [ NSKeyedArchiver archivedDataWithRootObject: regions ] : nil ) forKey: @"lastMonitoredRegions" ];
	[ [ NSUserDefaults standardUserDefaults ] synchronize ];

    // Setup all regions for hardcoded beacons.
	for( id region in regions )
	{
		if( [ region isKindOfClass: [ EnmoBeaconDetail class ] ] )
		{
			EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) region;

			if( beacon.isGimbal )
				continue;

			NSLog(@"starting ranging of: %@", beacon);

			// setup region for beacon - one region per one beacon allows to identify beacons more accurately
			// NOTE: as UUID CLBeaconRegion accepts PROXIMITY UUID - make sure you provide valid values here,
			// otherwise region will not work properly (so just will not find beacon).

			CLBeaconRegion * beaconRegion = nil;

			if( beacon.deviceMajor.integerValue <= 0 || beacon.deviceMajor.length == 0 ) // so major is empty value
				beaconRegion = [ [ CLBeaconRegion alloc ] initWithProximityUUID: [ [ NSUUID alloc ] initWithUUIDString: beacon.deviceUUID ]
																	 identifier: beacon.deviceName ];
			else if( beacon.deviceMinor.integerValue <= 0 || beacon.deviceMinor.length == 0 ) // so major is not empty
				beaconRegion = [ [ CLBeaconRegion alloc ] initWithProximityUUID: [ [ NSUUID alloc ] initWithUUIDString: beacon.deviceUUID ]
																		  major: beacon.deviceMajor.integerValue
																	 identifier: beacon.deviceName ];
			else // so major and minor both are not empty
				beaconRegion = [ [ CLBeaconRegion alloc ] initWithProximityUUID: [ [ NSUUID alloc ] initWithUUIDString: beacon.deviceUUID ]
																		  major: beacon.deviceMajor.integerValue
																		  minor: beacon.deviceMinor.integerValue
																	 identifier: beacon.deviceName ];
			beaconRegion.notifyEntryStateOnDisplay = YES;

			[ Logger logToConsole: [ NSString stringWithFormat: @"START RANGING of REGION: %@", beacon.deviceName ] ];
			[ Logger logToConsole: [ NSString stringWithFormat: @"beacon Region /////////////////////////%@", beaconRegion.identifier ] ];
			
			[ _arrayMonitoredRegions addObject: beaconRegion ];

			NSLog(@"START region: %@", beaconRegion.identifier);

			[ gLocationManager startMonitoringForRegion: beaconRegion ];
			[ gLocationManager startRangingBeaconsInRegion: beaconRegion ];
			
//			[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"NOW MONITORING: %@",beaconRegion.identifier ] ];
			
			// NSLog( @"Number of region monitoring @@@@@@ %lu", ( unsigned long ) [ [ gLocationManager monitoredRegions ] count ] );

		} // if( [ region isKindOfClass: [ EnmoBeaconDetail class ] ] )

		else if( [ region isKindOfClass: [ EnmoGeofence class ] ] )
		{
//			if( ![ CLLocationManager regionMonitoringAvailable ] )
//				[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"MONITORING NOT AVAILABLE" ] ];
//
//			if( ( [ CLLocationManager authorizationStatus ] != kCLAuthorizationStatusAuthorized )
//				 && ( [ CLLocationManager authorizationStatus ] != kCLAuthorizationStatusNotDetermined ) )
//				[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"AUTH NOT DONE" ] ];

			EnmoGeofence * geofence = ( EnmoGeofence * ) region;

			CLLocationDegrees latitude = geofence.geofenceLat.doubleValue;
			CLLocationDegrees longitude = geofence.geofenceLong.doubleValue;
			CLLocationCoordinate2D location = CLLocationCoordinate2DMake( latitude, longitude );

			[ Logger logToConsole: [ NSString stringWithFormat: @"Lat> %f & Long> %f", location.latitude, location.longitude ] ];

			CLCircularRegion * geofenceRegion = [ [ CLCircularRegion alloc ] initWithCenter: location
																					 radius: geofence.geofenceRadius
																				 identifier: geofence.geofenceName ];
			geofenceRegion.notifyOnEntry = YES;
			geofenceRegion.notifyOnExit = YES;

			[ Logger logToConsole: [ NSString stringWithFormat: @"START RANGING or GEOFENCE REGION: %@", geofence.geofenceName ] ];
			[ Logger logToConsole: [ NSString stringWithFormat: @"RANGE OF GEOFENCE REGION MAX: %f", gLocationManager.maximumRegionMonitoringDistance ] ];

			[ _arrayMonitoredRegions addObject: geofenceRegion ];
			[ gLocationManager startMonitoringForRegion: geofenceRegion ];

//			[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"NOW MONITORING: %@", geofenceRegion.identifier ] ];

		} // else if( [ region isKindOfClass: [ EnmoGeofence class ] ] )

//		[ Logger logToConsole: [ NSString stringWithFormat: @"Number of geofence monitoring %lu", ( unsigned long ) [ [ gLocationManager monitoredRegions ] count ] ] ];

	} // for( id region in regions )

//    [ _locationManager startUpdatingHeading ];
    [ gLocationManager startUpdatingLocation ];
}


//==============================================================================
- ( void ) stopRangingForBeacons
{
	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];
    NSString * pushDone = [ settings objectForKey: @"pushDone" ];

	[ Logger logToConsole: [ NSString stringWithFormat: @"push done %@", pushDone ] ];

	if( [ pushDone isEqual: @"YES" ] )
	{
        [ Logger logToConsole: @"In push done restart" ];

		NSData * data = [ settings objectForKey: @"arrayOfRegionsToRemember" ];
        [ Logger logToConsole: [ NSString stringWithFormat: @"In push done data %@", data ] ];

        NSArray * arrayOfObtainedRegions = [ NSKeyedUnarchiver unarchiveObjectWithData: data ];
        _arrayMonitoredRegions = [ arrayOfObtainedRegions mutableCopy ];
        [ Logger logToConsole: [ NSString stringWithFormat: @"After push array size %lu", ( unsigned long ) _arrayMonitoredRegions.count ] ];
        [ settings setObject: @"NO" forKey: @"pushDone" ];
    }

    [ Logger logToConsole: [ NSString stringWithFormat: @"Stop monitoring %lu regions*************************", ( unsigned long ) _arrayMonitoredRegions.count ] ];

	for( id region in _arrayMonitoredRegions )
	{
		[ gLocationManager stopMonitoringForRegion: region ];

		if( [ region isKindOfClass: [ CLBeaconRegion class ] ] ) {
			CLBeaconRegion * reg = (CLBeaconRegion *) region;
			NSLog(@"STOP region: %@", reg.identifier);
			[ gLocationManager stopRangingBeaconsInRegion: ( CLBeaconRegion * ) region ];
		}
		else if([region isKindOfClass:[CLCircularRegion class]])
			[ gLocationManager stopMonitoringForRegion: ( CLCircularRegion * ) region ];

//		[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"STOP MONITORING: %@",region ] ];
	}

	[ gLocationManager stopUpdatingLocation ];

    [ _arrayMonitoredRegions removeAllObjects ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"END Final monitoring %lu regions*************************", ( unsigned long ) _arrayMonitoredRegions.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"END OF STOP RANGING FOR BEACON ````````````````` %lu", ( unsigned long ) [ [ gLocationManager monitoredRegions ] count ] ] ];
}


//==============================================================================
- ( void ) startRangingLastMonitoredRegions
{
	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];

	[ Logger logToConsole: @"startRangingLastMonitoredRegions" ];

	NSData * data = [ settings objectForKey: @"lastMonitoredRegions" ];
	NSArray * regions = [ NSKeyedUnarchiver unarchiveObjectWithData: data ];
	[ Logger logToConsole: [ NSString stringWithFormat: @"Starting ranging of: \n%@", regions ] ];

	[ self startRangingRegionsFromArray: regions ];
}


//==============================================================================
- ( void ) saveMonitoredRegions
{
    [ Logger logToConsole: @"In remember list of regions" ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"In remember monitoring region count %lu", ( unsigned long ) _arrayMonitoredRegions.count ] ];

    NSArray * arrayOfRegions = [ NSArray arrayWithArray: _arrayMonitoredRegions ];
	[ Logger logToConsole: [ NSString stringWithFormat: @"In remember nsarray %@", arrayOfRegions ] ];

	NSData * data = [ NSKeyedArchiver archivedDataWithRootObject: arrayOfRegions ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"In remember data %@", data ] ];

    [ [ NSUserDefaults standardUserDefaults ] setObject: data forKey: @"arrayOfRegionsToRemember" ];

    // [ [ NSUserDefaults standardUserDefaults ] setObject: arrayOfGeofences forKey: @"arrayOfGeofenceToRemember" ];
	// [ [ NSUserDefaults standardUserDefaults ] synchronize ];
}

#pragma mark - CLLocationManagerDelegate

////==============================================================================
//- ( void ) locationManager: ( CLLocationManager * ) manager
//         didDetermineState: ( CLRegionState ) state
//                 forRegion: ( CLRegion * ) region
//{
//    if( state == CLRegionStateInside )
//    {
//
//#ifdef DEBUG
//        NSLog( @"locationManager didDetermineState INSIDE for %@", region.identifier );
//
//        [ [ RulesManager shared ] checkEntryRuleForRegionWithName: region.identifier ];
//#endif
//    }
//    else if( state == CLRegionStateOutside )
//    {
//
//#ifdef DEBUG
//        NSLog( @"locationManager didDetermineState OUTSIDE for %@", region.identifier );
//#endif
//
//        [ [ RulesManager shared ] checkExitRuleForRegionWithName: region.identifier ];
//    }
//    else
//    {
//
//#ifdef DEBUG
//        NSLog( @"locationManager didDetermineState OTHER for %@", region.identifier );
//#endif
//    }
//}


//==============================================================================
- ( void ) locationManager: ( CLLocationManager * ) manager
           didRangeBeacons: ( NSArray * ) beacons
                  inRegion: ( CLBeaconRegion * ) region
{
    // NOTE: this works only when app is in foreground, and not called when app is in background.
    // In background it is only possible to catch if we entered to or exited from region, assigned to beacon.

//	[ Logger logToConsole: [ NSString stringWithFormat: @"Ranged iBeacons in Region %@\n - %@\n\n", region.identifier, beacons ] ];

    if( beacons.count )
    {
#ifdef DEBUG
//        [ Logger logToConsole: [ NSString stringWithFormat: @"Ranged iBeacons in Region %@\n - %@\n\n", region.identifier, beacons ] ];
#endif

        [ beacons enumerateObjectsUsingBlock: // as we have one region per beacon - there can be only one beacon in array
            ^ ( CLBeacon * beacon, NSUInteger idx, BOOL * stop )
            {
                id beaconRegion = [ [ RulesManager shared ] regionWithName: region.identifier ];

                if( [ beaconRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )
                {
                    EnmoBeaconDetail * region = ( EnmoBeaconDetail * ) beaconRegion;

                    switch ( beacon.proximity )
                    {
                        case CLProximityUnknown:
                            region.currentProximity = @"Unknown";
                            break;
                        case CLProximityImmediate:
                            region.currentProximity = @"Immediate";
                            break;
                        case CLProximityNear:
                            region.currentProximity = @"Near";
                            break;
                        case CLProximityFar:
                            region.currentProximity = @"Far";
                            break;
                        default:
                            break;

                    } // switch ( beacon.proximity )
                } // if( [ beaconRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )
            } // ^ ( CLBeacon * beacon, NSUInteger idx, BOOL * stop )
         ]; // [ beacons enumerateObjectsUsingBlock:
        
    } // if( beacons.count )

    else
    {
#ifdef DEBUG
//        [ Logger logToConsole: [ NSString stringWithFormat: @"Ranged empty region - %@", region.identifier ] ];
#endif
    }

    //[ RulesManager showTestLocalNotificationWithText: @"RANGE" ];
}


//==============================================================================
- ( void ) locationManager: ( CLLocationManager * ) manager
            didEnterRegion: ( CLRegion * ) region
{
    [ Logger logToConsole: [ NSString stringWithFormat: @"didEnterRegion of %@:", region.identifier ] ];

	if( ![ region.identifier isEqualToString: @"com.gimbal.beacon.id" ] )
		[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"EN: %@", region.identifier ] ];

	[ [ RulesManager shared ] checkEntryRuleForRegionWithName: region.identifier ];
}


//==============================================================================
- ( void ) locationManager: ( CLLocationManager * ) manager
             didExitRegion: ( CLRegion * ) region
{
	[ Logger logToConsole: [ NSString stringWithFormat: @"didExitRegion of %@:", region.identifier ] ];

	if( ![ region.identifier isEqualToString: @"com.gimbal.beacon.id" ] )
		[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"EX: %@", region.identifier ] ];

	[ [ RulesManager shared ] checkExitRuleForRegionWithName: region.identifier ];
}


//==============================================================================
- ( void ) locationManager: ( CLLocationManager * ) manager
        didUpdateLocations: ( NSArray * ) locations
{
   // [ Logger logToConsole: [ NSString stringWithFormat: @"didUpdateLocations: %@", locations ] ];

    [ RulesManager shared ].currentLocation = [ locations lastObject ];
}


//==============================================================================
- ( void ) locationManager: ( CLLocationManager * ) manager
		 didDetermineState: ( CLRegionState ) state
				 forRegion: ( CLRegion * ) region
{
	NSLog( @"didDetermineState: %ld forRegion: %@", (long)state, region );
}


#pragma mark - CBCentralManagerDelegate

//==============================================================================
- ( void ) centralManagerDidUpdateState: ( CBCentralManager * ) central
{
	if( central.state == CBCentralManagerStatePoweredOff )
	{
		[ UIAlerter showOkSettingsAlertWithTitle: @"Turn On Bluetooth to Allow App to Range Beacons."
										 message: @"You can switch it on in Settings -> Bluetooth!"
										 okBlock: ^{}
								andSettingsBlock:
			 ^
			 {
//				 [ [ UIApplication sharedApplication ] openURL: [ NSURL URLWithString: UIApplicationOpenSettingsURLString ] ];
			 }
		 ];
	}
}


#pragma mark - ESSBeaconScannerDelegate

@end
