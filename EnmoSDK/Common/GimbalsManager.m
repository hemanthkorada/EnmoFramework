//
//  GimbalsManager.m
//  enmo autolock
//


#import "GimbalsManager.h"
#import "ESSTimer.h"


#define GIMBALS_WITH_PLACES
#define GIMBALS_WITH_COMMUNICATIONS
#define GIMBALS_LOG_SIGHTNINGS
//#define GIMBALS_USE_DETECTION_BY_TIMER


GimbalsManager * gimbalsManager;


#ifdef GIMBAL_SDK_VERSION_1

@interface GimbalsManager() < FYXServiceDelegate, FYXVisitDelegate, FYXSightingDelegate >
{
	NSString * _applicationID;
	NSString * _secret;
	NSString * _callbackURLs;
	NSString * _apiKey;

	FYXVisitManager * _visitManager;
	FYXSightingManager * _sightingManager;

	NSInteger _dwellTimeTimeout;
	NSInteger _stayAwayTimeout;
	NSInteger _stayAwayTimeoutBG;
	NSInteger _enterSignalStrength;
	NSInteger _exitSignalStrength;
	NSInteger _signalStrengthWindow;
	
	NSString * _username;
	NSMutableArray * _allowedBeacons;
	NSMutableDictionary * _dictAvailableBeacons;
}

#else // GIMBAL_SDK_VERSION_2


@interface GimbalsManager()
< GMBLPlaceManagerDelegate, GMBLBeaconManagerDelegate, GMBLApplicationStatusDelegate, GMBLCommunicationManagerDelegate >
{
	NSMutableDictionary * _seenGimbalsCache;
	NSTimeInterval _onLostTimeout;
	NSString * _apiKey;
}

#endif

@end



@implementation GimbalsManager

//==============================================================================
+ ( GimbalsManager * ) shared
{
	if( gimbalsManager == nil )
		gimbalsManager = [ [ GimbalsManager alloc ] init ];

	return gimbalsManager;
}


//==============================================================================
- ( id ) init
{
	self = [ super init ];

	if( self )
	{

#ifdef GIMBAL_SDK_VERSION_1

//		QLContextCoreConnector *connector = [QLContextCoreConnector new];
//		[connector enableFromViewController:[UIApplication sharedApplication].delegate.window.rootViewController success:^
//		 {
//			 NSLog(@"Gimbal enabled");
//		 } failure:^(NSError *error) {
//			 NSLog(@"Failed to initialize gimbal %@", error);
//		 }];

		_dictAvailableBeacons = [ [ NSMutableDictionary alloc ] init ];
		_signalStrengthWindow = FYXSightingOptionSignalStrengthWindowNone;

#ifdef AUTOLOCK
		
		_applicationID = @"38fdbf73cd5afc82e97b38108d7b471373596509d85d719fac0059007ddc7492";
		_secret = @"93ed0c0c889a50126415ae4aa8c62cd945af180d45cf78df01abd3c361dfe42c";
		_callbackURLs = @"mobienmoautolock://authcode";
		_apiKey = @"a9489a19-ddf7-4a24-89ad-6d51a2671b84";

#else	// ENMO

		_applicationID = @"58cbf5d96797eefaf8ac9ea61a186ba366e08dea67a6b2a78f44d5b9f0fb04a0";
		_secret = @"e261556650e9df72c49b7e37a23f28c95e13542adde003d7fb39ad2f417df1af";
		_callbackURLs = @"mobienmoatmio://authcode";
		_apiKey = @"b01a8a29-a32f-4cea-9a6c-9f8bf434bb88";
#endif

		[ self readPreferences ];

#else // GIMBAL SDK 2


#ifdef AUTOLOCK
		_apiKey = @"a9489a19-ddf7-4a24-89ad-6d51a2671b84";
#else // ENMO
		_apiKey = @"b01a8a29-a32f-4cea-9a6c-9f8bf434bb88";
#endif
		[ Gimbal setAPIKey: _apiKey options: nil ];
		_seenGimbalsCache = [ [ NSMutableDictionary alloc ] init ];
		_onLostTimeout = 5.0;
#endif

		[ [ EmailManager shared ] addString: _apiKey ];
	}

	return self;
}


//==============================================================================
- ( void ) startMonitoring
{
	[ [ EmailManager shared ] addString: @"GIMBALS: startMonitoring" ];

#ifdef GIMBAL_SDK_VERSION_1

	[ FYX setAppId: _applicationID appSecret: _secret callbackUrl: _callbackURLs ];
	[ FYXLogging setLogLevel: FYX_LOG_LEVEL_VERBOSE ];
	[ FYX startService: self ];

#else

#ifdef GIMBALS_WITH_PLACES
	self.placeManager = [ GMBLPlaceManager new ];
	self.placeManager.delegate = self;
	[ GMBLPlaceManager startMonitoring ];
#endif
	
	self.beaconManager = [ GMBLBeaconManager new ];
	self.beaconManager.delegate = self;
	[ self.beaconManager startListening ];

#ifdef GIMBALS_WITH_COMMUNICATIONS
	self.communicationManager = [ GMBLCommunicationManager new ];
	self.communicationManager.delegate = self;
	[ GMBLCommunicationManager startReceivingCommunications ];
#endif

#endif
}


//==============================================================================
- ( void ) stopMonitoring
{
	[ [ EmailManager shared ] addString: @"GIMBALS: stopMonitoring" ];

#ifdef GIMBAL_SDK_VERSION_1

	[ _sightingManager stopScan ];
	[ _visitManager stop ];

#else

#ifdef GIMBALS_WITH_PLACES
	[ GMBLPlaceManager stopMonitoring ];
    [ self.beaconManager stopListening ];
#endif

	[ self.beaconManager stopListening ];
	
#ifdef GIMBALS_WITH_COMMUNICATIONS
	[ GMBLCommunicationManager stopReceivingCommunications ];
#endif

	
#ifdef GIMBALS_USE_DETECTION_BY_TIMER
	[ self clearRemainingTimers ];
#endif

#endif
}


#ifdef GIMBAL_SDK_VERSION_1

//==============================================================================
- ( void ) initVisitManager
{
	if( _visitManager == nil )
	{
		_visitManager = [ FYXVisitManager new ];
		_visitManager.delegate = self;
	}
	else
		[ _visitManager stop ];


	NSMutableDictionary * options = [ NSMutableDictionary new ];

//    NSLog( @"%d %d %d %d", FYXSightingOptionSignalStrengthWindowNone, FYXSightingOptionSignalStrengthWindowSmall, FYXSightingOptionSignalStrengthWindowMedium, FYXSightingOptionSignalStrengthWindowLarge );

	[ options setObject: [ NSNumber numberWithInteger: _signalStrengthWindow ]		forKey: FYXSightingOptionSignalStrengthWindowKey ];
	[ options setObject: [ NSNumber numberWithInteger: _stayAwayTimeout ]			forKey: FYXVisitOptionDepartureIntervalInSecondsKey ];
	[ options setObject: [ NSNumber numberWithInteger: _stayAwayTimeoutBG ]			forKey: FYXvVisitOptionBackgroundDepartureIntervalInSecondsKey ];

	if( _enterSignalStrength < 0 )
		[ options setObject: [ NSNumber numberWithInteger: _enterSignalStrength ]	forKey: FYXVisitOptionArrivalRSSIKey ];

	if( _exitSignalStrength < 0 )
		[ options setObject: [ NSNumber numberWithInteger: _exitSignalStrength ]	forKey: FYXVisitOptionDepartureRSSIKey ];

	[ _visitManager startWithOptions: options ];

	[ self initSightningManager ];
}


//==============================================================================
- ( void ) initSightningManager
{
	return;

	NSMutableDictionary * options = [ NSMutableDictionary new ];

	[ options setObject: [ NSNumber numberWithInt: FYXSightingOptionSignalStrengthWindowMedium ]
				 forKey: FYXSightingOptionSignalStrengthWindowKey ];

	if( _sightingManager == nil )
	{
		_sightingManager = [ [ FYXSightingManager alloc ] init ];
		_sightingManager.delegate = self;
	}

	[ _sightingManager scanWithOptions: options ];
}


//==============================================================================
- ( void ) handleOpenURL: ( NSURL * ) url
{
	[ FYX handleOpenURL: url ];
}


#pragma mark - Preferences

//==============================================================================
- ( void ) readPreferences
{
	NSUserDefaults * userDefaults = [ NSUserDefaults standardUserDefaults ];

	_dwellTimeTimeout = [ userDefaults integerForKey: @"dwellTimeTimeout" ];

    if( _dwellTimeTimeout == 0 )
        _dwellTimeTimeout = 1;

	_stayAwayTimeout = [ userDefaults integerForKey: @"stayAwayTimeout" ];

    if( _stayAwayTimeout == 0 )
        _stayAwayTimeout = 20;

	_stayAwayTimeoutBG = [ userDefaults integerForKey: @"stayAwayTimeoutBG" ];

    if( _stayAwayTimeoutBG == 0 )
        _stayAwayTimeoutBG = 20;

	_enterSignalStrength = [ userDefaults integerForKey: @"enterSignalStrength" ];

    if( _enterSignalStrength == 0 )
        _enterSignalStrength = -70;

	_exitSignalStrength = [ userDefaults integerForKey: @"exitSignalStrength" ];

    if( _exitSignalStrength == 0 )
        _exitSignalStrength = -85;

	_signalStrengthWindow = [ userDefaults integerForKey: @"signalStrengthWindow" ];

	if( _signalStrengthWindow == 0 )
		_signalStrengthWindow = FYXSightingOptionSignalStrengthWindowSmall;

	_username = [ userDefaults objectForKey: @"username" ];

	if( _username == nil )
		_username = @"";

	_allowedBeacons = [ userDefaults objectForKey: @"allowedBeacons" ];

	if( _allowedBeacons == nil )
		_allowedBeacons = [ [ NSMutableArray alloc ] init ];
}


//==============================================================================
- ( void ) savePreferences
{
	NSUserDefaults * userDefaults = [ NSUserDefaults standardUserDefaults ];

	[ userDefaults setInteger: _dwellTimeTimeout        forKey: @"dwellTimeTimeout" ];
	[ userDefaults setInteger: _stayAwayTimeout         forKey: @"stayAwayTimeout" ];
	[ userDefaults setInteger: _stayAwayTimeoutBG       forKey: @"stayAwayTimeoutBG" ];
	[ userDefaults setInteger: _enterSignalStrength     forKey: @"enterSignalStrength" ];
	[ userDefaults setInteger: _exitSignalStrength      forKey: @"exitSignalStrength" ];
	[ userDefaults setInteger: _signalStrengthWindow    forKey: @"signalStrengthWindow" ];
	[ userDefaults setObject: _username                 forKey: @"username" ];
	[ userDefaults setObject: _allowedBeacons			forKey: @"allowedBeacons" ];

	[ userDefaults synchronize ];
}


//==============================================================================
- ( void ) serviceStarted
{
	// this will be invoked if the service has successfully started
	// bluetooth scanning will be started at this point.
	NSLog( @"FYX Service Successfully Started" );

	[ self performSelector: @selector( initVisitManager )
				  onThread: [ NSThread mainThread ]
				withObject: nil
			 waitUntilDone: NO ];
}


//==============================================================================
- ( void ) startServiceFailed: ( NSError * ) error
{
	// this will be called if the service has failed to start
	NSLog(@"%@", error);
}


#pragma mark - FYXVisitDelegate

//==============================================================================
- ( void ) didArrive: ( FYXVisit * ) visit
{
	NSString * name = visit.transmitter.name;

	FYXVisit * visit1 = [ _dictAvailableBeacons objectForKey: name ];

	if( visit1 == nil )
	{
		[ _dictAvailableBeacons setObject: visit forKey: name ];

		NSString * string = [ NSString stringWithFormat: @"GB Visit EN: %@", name ];
		[ [ EmailManager shared ] addString: string ];
		[ Logger logToConsole: string ];
		[ RulesManager showTestLocalNotificationWithText: string ];
		[ [ RulesManager shared ] checkEntryRuleForRegionWithName: name ];
	}
}


//==============================================================================
- ( void ) receivedSighting: ( FYXVisit * ) visit
				 updateTime: ( NSDate * ) updateTime
					   RSSI: ( NSNumber * ) RSSI
{

}


//==============================================================================
- ( void ) didDepart: ( FYXVisit * ) visit
{
	NSLog( @"didDepart: %f", visit.dwellTime );

	if( visit.dwellTime >= _dwellTimeTimeout )
	{
		NSString * name = visit.transmitter.name;
		NSString * string = [ NSString stringWithFormat: @"GB Visit EX: %@", name ];
		[ [ EmailManager shared ] addString: string ];
		[ Logger logToConsole: string ];
		[ RulesManager showTestLocalNotificationWithText: string ];
		[ [ RulesManager shared ] checkExitRuleForRegionWithName: name ];

		[ _dictAvailableBeacons removeObjectForKey: visit.transmitter.name ];
	}
}


#pragma mark - FYXSightingDelegate

//==============================================================================
- ( void ) didReceiveSighting: ( FYXTransmitter * ) transmitter
						 time: ( NSDate * ) time
						 RSSI: ( NSNumber * ) RSSI
{
//          FYXTransmitter
//
//    Property Name     Description
//
//    identifier        Unique identifier for this transmitter
//    name              Name assigned to this transmitter
//    ownerId           Unique identifier of the owner of the transmitter
//    iconUrl           URL to an icon image (optional)
//    battery           Battery level indication. 0=LOW, 1=MED/LOW, 2=MED/HIGH, 3=HIGH (optional)
//    temperature       Temperature of transmitter in fahrenheit (optional)
}


#else // GIMBAL_SDK_VERSION_2


#pragma mark - GMBLPlaceManagerDelegate

//==============================================================================
- ( void ) placeManager: ( GMBLPlaceManager * ) manager
		  didBeginVisit: ( GMBLVisit * ) visit
{
	NSString * string = [ NSString stringWithFormat: @"GB Place EN: %@", visit.place.name ];
	[ [ EmailManager shared ] addString: string ];
	[ Logger logToConsole: string ];
	[ RulesManager showLocalNotificationWithText: string ];
	[ [ RulesManager shared ] checkEntryRuleForRegionWithName: visit.place.name ];
}


//==============================================================================
- ( void ) placeManager: ( GMBLPlaceManager * ) manager
didReceiveBeaconSighting: ( GMBLBeaconSighting * ) sighting
			  forVisits: ( NSArray * ) visits
{
	NSString * string = [ NSString stringWithFormat: @"GB Place Sighted: %@ in Visits", sighting.beacon.name ];
	[ [ EmailManager shared ] addString: string ];

//	[ RulesManager showLocalNotificationWithText: string ];
////	[ [ RulesManager shared ] checkEntryRuleForRegionWithName: sighting.beacon.name ];
//	[ Logger logToConsole: string ];
}


//==============================================================================
- ( void ) placeManager: ( GMBLPlaceManager * ) manager
			didEndVisit: ( GMBLVisit * ) visit
{
	NSString * string = [ NSString stringWithFormat: @"GB Place EX: %@", visit.place.name ];
	[ [ EmailManager shared ] addString: string ];
	[ Logger logToConsole: string ];
	[ RulesManager showLocalNotificationWithText: string ];
	[ [ RulesManager shared ] checkExitRuleForRegionWithName: visit.place.name ];
}


#pragma mark - GMBLBeaconManagerDelegate

//==============================================================================
- ( void ) beaconManager: ( GMBLBeaconManager * ) manager
didReceiveBeaconSighting: ( GMBLBeaconSighting * ) sighting
{
	NSString * string = [ NSString stringWithFormat:
						 @"GB Sighted:\nName: %@, UUID: %@, Identifier: %@.",
						 sighting.beacon.name, sighting.beacon.uuid, sighting.beacon.identifier ];
	
#ifdef GIMBALS_LOG_SIGHTNINGS
	static int blocker = 5;

	if( blocker == 0 )
	{
		blocker = 5;
//		[ RulesManager showTestLocalNotificationWithText: string ];
		[ [ EmailManager shared ] addString: string ];
	}

	blocker--;
#endif
	
//	[ Logger logToConsole: string ];

#ifdef GIMBALS_USE_DETECTION_BY_TIMER
	[ self checkIfEventIsNecessaryForGimbalSighting: sighting ];
#endif
	
//	[ RulesManager showLocalNotificationWithText: string ];
//	[ [ RulesManager shared ] checkEntryRuleForRegionWithName: sighting.beacon.name ];
}


#ifdef GIMBALS_USE_DETECTION_BY_TIMER

static NSString *const kSeenCacheBeaconInfo2 = @"beacon_info";
static NSString *const kSeenCacheOnLostTimer2 = @"on_lost_timer";

//==============================================================================
- ( void ) checkIfEventIsNecessaryForGimbalSighting: ( GMBLBeaconSighting * ) sighting
{
	EnmoBeaconDetail * beaconInfo = [ [ RulesManager shared ] gimbalWithUUID: sighting.beacon.identifier ];
	
	NSLog( @"checkIfEventIsNecessaryForGimbalSighting: %@", beaconInfo );
	
	if( beaconInfo != nil )
	{
		// If we haven't seen this Gimbal before
		if( !_seenGimbalsCache[beaconInfo.deviceUUID] )
		{
			[ Logger logToConsole: [ NSString stringWithFormat: @"GB Place EN: %@", beaconInfo.deviceName ] ];
			[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"GB Place EN: %@", beaconInfo.deviceName ] ];
			[ [ RulesManager shared ] checkEntryRuleForRegionWithName: beaconInfo.deviceName ];
			
			
			ESSTimer * onLostTimer = [ ESSTimer scheduledTimerWithDelay: _onLostTimeout
																onQueue: dispatch_get_main_queue()
																  block:
										 ^( ESSTimer * timer )
										 {
											 EnmoBeaconDetail * lostBeaconInfo = _seenGimbalsCache[beaconInfo.deviceUUID][kSeenCacheBeaconInfo2];

											 if( lostBeaconInfo )
											 {
												 [ _seenGimbalsCache[lostBeaconInfo.deviceUUID][kSeenCacheOnLostTimer2] cancel ];

												 [ Logger logToConsole: [ NSString stringWithFormat: @"GB Place EX: %@", lostBeaconInfo.deviceName ] ];
												 [ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"GB Place EX: %@", lostBeaconInfo.deviceName ] ];
												 [ [ RulesManager shared ] checkExitRuleForRegionWithName: lostBeaconInfo.deviceName ];

												 [ _seenGimbalsCache removeObjectForKey: lostBeaconInfo.deviceUUID ];
											 }
										 }
									  ];
			
			_seenGimbalsCache[beaconInfo.deviceUUID] = @{
														 kSeenCacheBeaconInfo2: beaconInfo,
														 kSeenCacheOnLostTimer2: onLostTimer,
														 };
		} // if( !_seenGimbalsCache[beaconInfo.deviceUUID] )
		else
		{
			// Reset the onLost timer.
			[ _seenGimbalsCache[beaconInfo.deviceUUID][kSeenCacheOnLostTimer2] reschedule ];
			
		} // Gimbal is in cache already
		
	} // if( beaconInfo != nil )
}


//==============================================================================
- ( void ) clearRemainingTimers
{
	for( NSString *beaconID in _seenGimbalsCache )
	{
		[ _seenGimbalsCache[beaconID][kSeenCacheOnLostTimer2] cancel ];
	}
	
	_seenGimbalsCache = nil;
}

#endif


#pragma mark - GMBLApplicationStatusDelegate
#pragma mark - GMBLCommunicationManagerDelegate

//==============================================================================
- ( NSArray * ) communicationManager: ( GMBLCommunicationManager * ) manager
presentLocalNotificationsForCommunications: ( NSArray * ) communications
							forVisit: ( GMBLVisit * ) visit
{
	[ [ EmailManager shared ] addString: [ NSString stringWithFormat: @"GB Communic: %@", visit.place.name ] ];
//	[ RulesManager showLocalNotificationWithText: [ NSString stringWithFormat: @"GB Communic: %@", visit.place.name ] ];
	return [ NSArray array ];
}


#endif



#ifdef GIMBAL_SDK_VERSION_1

#pragma mark - Getters/Setters

//==============================================================================
- ( NSInteger ) dwellTimeTimeout
{
	return _dwellTimeTimeout;
}


//==============================================================================
- ( NSInteger ) stayAwayTimeout
{
	return _stayAwayTimeout;
}


//==============================================================================
- ( NSInteger ) stayAwayTimeoutBG
{
	return _stayAwayTimeoutBG;
}


//==============================================================================
- ( NSInteger ) enterSignalStrength
{
	return _enterSignalStrength;
}


//==============================================================================
- ( NSInteger ) exitSignalStrength
{
	return _exitSignalStrength;
}


//==============================================================================
- ( NSInteger ) signalStrengthWindow
{
	return _signalStrengthWindow;
}


//==============================================================================
- ( void ) setDwellTimeTimeout: ( NSInteger ) dwellTimeTimeout
{
	_dwellTimeTimeout = dwellTimeTimeout;
	[ self savePreferences ];
}


//==============================================================================
- ( void ) setStayAwayTimeout: ( NSInteger ) stayAwayTimeout
{
	_stayAwayTimeout = stayAwayTimeout;
	[ self savePreferences ];
}


//==============================================================================
- ( void ) setStayAwayTimeoutBG: ( NSInteger ) stayAwayTimeoutBG
{
	_stayAwayTimeoutBG = stayAwayTimeoutBG;
	[ self savePreferences ];
}


//==============================================================================
- ( void ) setEnterSignalStrength: ( NSInteger ) enterSignalStrength
{
	_enterSignalStrength = enterSignalStrength;
	[ self savePreferences ];
}


//==============================================================================
- ( void ) setExitSignalStrength: ( NSInteger ) exitSignalStrength
{
	_exitSignalStrength = exitSignalStrength;
	[ self savePreferences ];
}


//==============================================================================
- ( void ) setSignalStrengthWindow: ( NSInteger ) signalStrengthWindow
{
	_signalStrengthWindow = signalStrengthWindow;
	[ self savePreferences ];
}

#endif

@end
