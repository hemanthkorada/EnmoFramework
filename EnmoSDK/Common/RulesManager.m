//
//  RulesManager.m
//  enmo rules
//


#import "RulesManager.h"
#import "BeaconsManager.h"
#import "EddystoneManager.h"
//#import "AppDelegate.h"
#import <sys/utsname.h>

//#define CHECK_FOR_RULES_UPON_EVENT

//#define SERVER_URL_ABHAY                      @"http://abhay.ideationts.com:8082/rules/RulesService.asmx/GetAllRulesAndRegions"

//Konstantin's serevr
#define GET_RULES_URL_KONSTANTIN                @"http://192.168.1.7:26457/rules/RulesService.asmx/GetAllRulesAndRegions?advertiserId=%@&idfv=%@"

#define SERVER_URL_POST_TOKEN_KONSTANTIN        @"http://192.168.1.7:26457/rules/RulesService.asmx/AddSubscriberToken?token=%@&advertiserId=%@"

#define MANUAL_LOCK_URL_KONSTANTIN				@"http://192.168.1.7:26457/AutoLock/AutoLockService.asmx/TestLockFromMobileClient?email=%@&advertiserId=%@"
/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Developer's server
#define GET_RULES_URL_TESTENMO                  @"http://kaushik.ideationts.com/atmio/rules/RulesService.asmx/GetAllRulesAndRegions?advertiserId=%@&idfv=%@"

#define GET_RULES_URL_ATMIO						@"http://kaushik.ideationts.com/rules/RulesService.asmx/GetAllRulesAndRegions?advertiserId=%@&idfv=%@"

#define SERVER_URL_POST_TOKEN_TESTENMO          @"http://kaushik.ideationts.com/rules/RulesService.asmx/AddSubscriberToken?token=%@&advertiserId=%@"

#define SERVER_URL_POST_TOKEN_ATMIO				@"http://kaushik.ideationts.com/rules/RulesService.asmx/AddSubscriberToken?token=%@&advertiserId=%@"

#define MANUAL_LOCK_URL_ATMIO					@"http://kaushik.ideationts.com//AutoLock/AutoLockService.asmx/TestLockFromMobileClient?email=%@&advertiserId=%@"

#define MANUAL_LOCK_URL_TESTENMO				@"http://testenmo.cloudapp.net/AutoLock/AutoLockService.asmx/TestLockFromMobileClient?email=%@&advertiserId=%@"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
//Production Server
#define GET_RULES_URL_ENMO						@"http://platform.enmo.mobi/rules/RulesService.asmx/GetAllRulesAndRegions?advertiserId=%@&idfv=%@"
#define GET_RULES_URL_TESTENMO                  @"http://testenmo.cloudapp.net/rules/RulesService.asmx/GetAllRulesAndRegions?advertiserId=%@&idfv=%@"

//#define SERVER_URL_POST_TOKEN_ENMO				@"http://platform.enmo.mobi/rules/RulesService.asmx/AddSubscriberToken?token=%@&advertiserId=%@"
//#define SERVER_URL_POST_TOKEN_TESTENMO          @"http://testenmo.cloudapp.net/rules/RulesService.asmx/AddSubscriberToken?token=%@&advertiserId=%@"

#define MANUAL_LOCK_URL_ENMO					@"http://platform.enmo.mobi/AutoLock/AutoLockService.asmx/TestLockFromMobileClient?email=%@&advertiserId=%@"
#define MANUAL_LOCK_URL_TESTENMO				@"http://testenmo.cloudapp.net/AutoLock/AutoLockService.asmx/TestLockFromMobileClient?email=%@&advertiserId=%@"
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


NSMutableData * responseData = nil;
RulesManager * rulesManager = nil;
NSFileHandle * file = nil;


@interface RulesManager()
{
	NSMutableArray * _arrayRules;
	NSMutableArray * _arrayGeofences;

	NSMutableArray * _arrayUpdatedRegions;

	NSMutableArray * _arrayBeacons;
	NSMutableArray * _arrayAppIDs;
	NSMutableArray * _arrayIDFVs;

	NSArray * _initialRegions;
	NSMutableArray * _beaconsInRange;
	NSMutableArray * _geofencesInRange;

	NSString * _lastEnterRegionName;
	NSString * _lastExitRegionName;

	UIBackgroundTaskIdentifier _badgeCheckBGTask;
}

@end


@implementation RulesManager

//==============================================================================
+ ( RulesManager * ) shared
{
    if( rulesManager == nil )
        rulesManager = [ [ RulesManager alloc ] init ];

    return rulesManager;
}


//==============================================================================
+ ( void ) showLocalNotificationWithText: ( NSString * ) text
{
    if( text )
    {
        UILocalNotification * notification = [ [ UILocalNotification alloc ] init ];
        notification.fireDate = [ NSDate date ];
        notification.alertAction = @"OK";
        notification.alertBody = text;
        [ [ UIApplication sharedApplication ] presentLocalNotificationNow: notification ];
    }
}


//==============================================================================
+ ( void ) showTestLocalNotificationWithText: ( NSString * ) text
{
#ifndef AUTOLOCK

	BOOL enabled = [ [ [ NSUserDefaults standardUserDefaults ] objectForKey: @"showDebugNotifications" ] boolValue ];

	if( enabled )
	{
		NSString * finalText = [ NSString stringWithFormat: @"TST: %@", text ];

		[ Logger logFileWritter: finalText ];
		[ RulesManager showLocalNotificationWithText: finalText ];
    }

#endif
}


//==============================================================================
- ( id ) init
{
    self = [ super init ];

    if( self )
    {
        _beaconsInRange = [ [ NSMutableArray alloc ] init ];
        _geofencesInRange = [ [ NSMutableArray alloc ] init ];

//        [ self startBadgeCheckTimer ];
    }

    return self;
}


//==============================================================================
- ( void ) getUsersAdvertiserIDWithCompletionBlock: ( void ( ^ ) ( void ) ) resultBlock
{
	[ UIAlerter showOkCancelTextFieldAlertWithTitle: @"Please enter Organization ID"
											message: @""
									 andResultBlock:
		^ ( CustomUIAlertView * alertView )
		{
			UITextField * textField = [ alertView textFieldAtIndex: 0 ];
			[ Logger logToConsole: [ NSString stringWithFormat: @"text in textfield %@", textField.text ] ];

			self.advertiserId = [ textField.text integerValue ];

			NSInteger advIDOld = [ [ [ NSUserDefaults standardUserDefaults ] objectForKey: @"advertiserId" ] integerValue ];
			[ [ NSUserDefaults standardUserDefaults ] setObject: [ NSNumber numberWithInteger: self.advertiserId ] forKey: @"advertiserId" ];

//			AppDelegate * appDelegate = ( AppDelegate * ) [ [ UIApplication sharedApplication ] delegate ];
//			[ appDelegate registerForPushNotifications ];

			if( advIDOld != self.advertiserId )
			{
				[ Logger logToConsole: @"get user advertiserID" ];
				[ self getRulesFromServer: NO ];
			}

			resultBlock();
		}
	 ];
}


//==============================================================================
- ( void ) getRulesFromServer: ( BOOL ) isForced
{
	[ RulesManager showTestLocalNotificationWithText: @"getRulesFromServer" ];

    self.isLoadingRules = YES;

    if( [ self.delegate respondsToSelector: @selector( rulesManagerDidStartRulesLoading ) ] )
        [ self.delegate rulesManagerDidStartRulesLoading ];

    __block UIBackgroundTaskIdentifier bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
                                         ^
                                         {
                                             [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in getRulesFromServer:%f", [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];
                                             [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
                                             bgTask = UIBackgroundTaskInvalid;
                                         }];

    NSString * IDFV = [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ];

#ifdef USE_TESTENMO_SERVER
	BOOL useTestenmo = YES;
#else
	BOOL useTestenmo = NO;
#endif

	NSURL * postURL = [ NSURL URLWithString: [ NSString stringWithFormat:
                                              //GET_RULES_URL_KONSTANTIN,
											  useTestenmo ? GET_RULES_URL_TESTENMO : GET_RULES_URL_ENMO,
                                              [ NSString stringWithFormat: @"%ld", (long)[ RulesManager shared ].advertiserId ], IDFV ]
                       ];
    
    [ Logger logToConsole: [ NSString stringWithFormat: @"The POST URL is >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> %@", postURL ] ];

    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                    ^
                    {
                        NSData * data = [ NSData dataWithContentsOfURL: postURL ];
                        
//                        [ Logger logToConsole: [ NSString stringWithFormat: @"The data is ----------------------------------- %@", data ] ];

						dispatch_async( dispatch_get_main_queue(),
                                       ^
                                       {
										   [ self parseRulesFromData: data isForced: isForced ];

                                           [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
                                           bgTask = UIBackgroundTaskInvalid;
                                       });

                        
						//AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

                        if( data == nil )
                        {
//                            if( [ self.delegate respondsToSelector: @selector( rulesManagerDidFailRulesParsing ) ] )
//                                [ self.delegate rulesManagerDidFailRulesParsing ];
//                            if(delegate.fetchCompletionHandler!=nil){
//                                NSLog(@"Sending fetch result failed");
//                                delegate.fetchCompletionHandler(UIBackgroundFetchResultFailed);
//                                delegate.fetchCompletionHandler = nil;
//                            }
                        }
                        else
                        {
                            if( [ self.delegate respondsToSelector: @selector( rulesManagerDidFinishRulesParsing ) ] )
                                [ self.delegate rulesManagerDidFinishRulesParsing ];
//                            if(delegate.fetchCompletionHandler!=nil){
//                                NSLog(@"Sending fetch result success new data");
//                                delegate.fetchCompletionHandler(UIBackgroundFetchResultNewData);
//                                delegate.fetchCompletionHandler = nil;
//                            }
                        }

                        // Do the work associated with the task, preferably in chunks.
                        [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
                        bgTask = UIBackgroundTaskInvalid;

                        self.isLoadingRules = NO;
                    }
                   );
}


#pragma mark - Parsing

//==============================================================================
- ( void ) parseRulesFromData: ( NSData * ) data
					 isForced: ( BOOL ) isForced
{
    [ Logger logToConsole: [ NSString stringWithFormat: @"In parse Rules from URL ================" ] ];
    
    NSString * string = [ [ NSString alloc ] initWithData: data encoding: NSUTF8StringEncoding ];
//    NSLog(@"the string before parsing %@",string);
    string = [ string stringByReplacingOccurrencesOfString: @"\r" withString: @"" ];
    string = [ string stringByReplacingOccurrencesOfString: @"\n" withString: @"" ];
    string = [ string stringByReplacingOccurrencesOfString: @"\t" withString: @"" ];
    string = [ string stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&" ];

    string = [ string stringByReplacingOccurrencesOfString: @"<?xml version=\"1.0\" encoding=\"utf-8\"?>" withString: @"" ];

    string = [ string stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://192.168.1.125:26457/rules/\">" withString: @"" ];
    string = [ string stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://abhay.ideationts.com:8082/rules/\">" withString: @"" ];
    string = [ string stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://enmo.cloudapp.net/rules/\">" withString: @"" ];

	string = [ string stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://atmio.com/rules/\">" withString: @"" ];
	string = [ string stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://testenmo.cloudapp.net/rules/\">" withString: @"" ];
	string = [ string stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://192.168.1.7/rules/\">" withString: @"" ];

    string = [ string stringByReplacingOccurrencesOfString: @"</string>" withString: @"" ];
    string = [ string stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding ];

	NSData * myData = [string dataUsingEncoding: NSUTF8StringEncoding ];
    NSError * error;
    NSDictionary * responseDict = [ NSJSONSerialization JSONObjectWithData: myData options: kNilOptions error: &error ];
    
    NSLog(@"the string after parsing %@",string);
//    NSLog(@"the data %@",myData);
//    NSLog(@"the error %@",error);
//    NSLog( @"responseString:%@", responseDict );
//    NSString * substring = [ string substringFromIndex: 1279 ];

    [ self parseRulesFromDictionary: responseDict isLocalLoad: NO isForced: isForced ];

//    if( _arrayInitialRegions.count == 0 )
//        [ self fillInitialRegions ];
    
    [ Logger logToConsole: @"END OF parse Rules from URL ================" ];
}


//==============================================================================
- ( void ) parseRulesFromDictionary: ( NSDictionary * ) dictJSON
                        isLocalLoad: ( BOOL ) isLocalLoad
						   isForced: ( BOOL ) isForced
{
//	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"parseRulesFromDictionary: %@", isLocalLoad ? @"Y" : @"N" ] ];

	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];

	__block BOOL shouldUpdateRules = isLocalLoad ? YES : NO;

	if( !isLocalLoad && dictJSON != nil )
	{
		NSArray * appIDs = [ dictJSON objectForKey: @"appids" ];

		// 3. Fill App IDs and initial regions to monitor
		__block NSString * bundleIdentifier = [ [ NSBundle mainBundle ] bundleIdentifier ];

		for( NSDictionary * dictAppID in appIDs )
		{
			EnmoAppId * appID = [ [ EnmoAppId alloc ] initWithDictionary: dictAppID ];

			if( [ appID.appID isEqualToString: bundleIdentifier ] )
			{
				if(   ( self.currentAppId == nil )
				   || ( self.currentAppId.timestamp == nil )
				   || ( ![ self.currentAppId.timestamp isEqualToString: appID.timestamp ] ) )
				{
					shouldUpdateRules = YES;
				}
			}
		}
	} // if( !isLocalLoad && dictJSON != nil )

	if( !shouldUpdateRules )
		return;
	
    // NOTE: Konstantin - when we update rules - we need to reset them, because we receive initial regions in AppID instance
    self.initialRulesJSON = dictJSON;

//    NSLog( @"!!!!! NEW RULES JSON !!!!!\n%@", dictJSON );

    [ self saveLocalRules ];
    [ self resetRules ];

    if( dictJSON == nil )
        return;


    [ Logger logToConsole: @"PARSING RULES" ];

    NSArray * geofences = [ dictJSON objectForKey: @"geofences" ];
    NSArray * beacons = [ dictJSON objectForKey: @"regions" ];
    NSArray * rules = [ dictJSON objectForKey: @"rules" ];
    NSArray * appIDs = [ dictJSON objectForKey: @"appids" ];
    NSArray * idfvs = [ dictJSON objectForKey: @"idfvs" ];

    // 1. Fill beacons
	for( NSDictionary * dictBeacon in beacons )
	{
		EnmoBeaconDetail * beacon = [ [ EnmoBeaconDetail alloc ] initWithDictionary: dictBeacon ];
		[ _arrayBeacons addObject: beacon ];
	}


    // 2. Fill geofences
	for( NSDictionary * dictGeofence in geofences )
	{
		EnmoGeofence * geofence = [ [ EnmoGeofence alloc ] initWithDictionary: dictGeofence ];
		[ _arrayGeofences addObject: geofence ];
	}


    // 3. Fill App IDs and initial regions to monitor
    __block NSString * bundleIdentifier = [ [ NSBundle mainBundle ] bundleIdentifier ];

	for( NSDictionary * dictAppID in appIDs )
	{
		EnmoAppId * appID = [ [ EnmoAppId alloc ] initWithDictionary: dictAppID ];

		if( [ appID.appID isEqualToString: bundleIdentifier ] )
		{
			[ Logger logToConsole: @"FOUND OUR APP ID" ];

			self.currentAppId = appID;
			[ Logger logToConsole: [ NSString stringWithFormat: @"initialRegions = %@", self.currentAppId.initialRegions ] ];

			_initialRegions = [ self parseInitialRegionsFromString: self.currentAppId.initialRegions ];

//			[ [ UIApplication sharedApplication ] setMinimumBackgroundFetchInterval: self.currentAppId.timer ];

//			NSString * urlString = self.currentAppId.initialHomePage;
//			if( [ urlString rangeOfString: @"http://" ].location == NSNotFound && [ urlString rangeOfString: @"https://" ].location == NSNotFound )
//				urlString = [ @"http://" stringByAppendingString: urlString ];
//
//			[ settings setObject: urlString forKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];
//			[ settings synchronize ];
		}

		[ _arrayAppIDs addObject: appID ];
	}


    // 4. Fill IDFVs
    __block NSString * IDFV = [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ];

	for( NSDictionary * dictIDFV in idfvs )
	{
		EnmoIDFV * idfv = [ [ EnmoIDFV alloc ] initWithDictionary: dictIDFV ];

		if( [ idfv.idfv isEqualToString: IDFV ] )
		{
			[ Logger logToConsole: @"FOUND OUR IDFV" ];
			self.currentIDFV = idfv;
		}

		[ _arrayIDFVs addObject: idfv ];
	}

    [ Logger logToConsole: [ NSString stringWithFormat: @"In parse rule before parsing size %lu", ( unsigned long ) _arrayRules.count ] ];


    // 5. Fill rules
	for( NSDictionary * dictRule in rules )
	{
		EnmoRule * rule = [ [ EnmoRule alloc ] initWithDictionary: dictRule ];

//		if( [ rule.ruleName rangeOfString: @"Eddystone" ].location != NSNotFound )
//			NSLog( @"rule.ruleName = %@", rule.ruleName );

		if( ( rule.appID == nil ) || ( rule.appID.integerValue == 0 ) || ( rule.appID.integerValue == self.currentAppId.ID ) )
		{
			if( ( rule.IDFV == nil ) || ( rule.IDFV.integerValue == 0 ) || ( rule.IDFV.integerValue == self.currentIDFV.ID ) )
			{
				NSString * email = [ settings objectForKey: @"email" ];

				if( ( rule.email.length == 0 )
				   || [ [ rule.email lowercaseString ] isEqualToString: @"all" ]
				   || ( email && [ rule.email isEqualToString: email ] ) )
				{
					[ _arrayRules addObject: rule ];

					NSString * ruleEach = [ NSString stringWithFormat: @"%@ for conditionRegionName %@", rule.ruleName, rule.conditionRegionName ];
					[ Logger logFileWritter: ruleEach ];

					if( rule.conditionType == ctTimer )
					{
						if( rule.IDFV == nil )
							self.timerRuleAll = rule;
						else if( [ rule.IDFV isEqualToString: self.currentIDFV.idfv ] )
							self.timerRule = rule;

					} // if( rule.conditionType == ctTimer )
				} // if( ( rule.email == nil ) || ( email && [ rule.email isEqualToString: email ] ) )
			} // if( ( rule.IDFV == 0 ) || ( rule.IDFV == self.currentIDFV.ID ) )
		} // if( ( rule.appID == 0 ) || ( rule.appID == self.currentAppId.ID ) )
	} // for( NSDictionary * dictRule in rules )

	[ Logger logToConsole: [ NSString stringWithFormat: @"In parse rule after parsing size %lu", ( unsigned long ) _arrayRules.count ] ];
    
    [ Logger logToConsole: [ NSString stringWithFormat: @"APP ID %ld", ( unsigned long ) _arrayAppIDs.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"IDFV %ld", ( unsigned long ) _arrayIDFVs.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"RULES %ld", ( unsigned long ) _arrayRules.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"GEOFENCES %ld", ( unsigned long ) _arrayGeofences.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"BEACONS %ld", ( unsigned long ) _arrayBeacons.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"INITIAL REGIONS %ld", ( unsigned long ) _initialRegions.count ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"INITIAL URL %@", self.currentAppId.initialHomePage ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"OUR IDFV %@", self.currentIDFV.idfv ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"\n\n" ] ];

    // NOTE: Konstantin - while we are parsing rules - Timer should work with OLD rules and be restarted only when new rules are parsed
//    [ self restartRulesCheckTimer ];

    NSString * didRestart = [ settings objectForKey: @"reStart" ];
    
    [ Logger logToConsole: [ NSString stringWithFormat: @"did restart %@", didRestart ] ];

	if( [ didRestart isEqual: @"NO" ] )
		[ Logger logToConsole: [ NSString stringWithFormat: @"number of regions to be monitored %lu", ( unsigned long ) _initialRegions.count ] ];

	if( isLocalLoad ) {
		// Should start ranging of regions, which were the last before app termination
		[ [ BeaconsManager shared ] startRangingLastMonitoredRegions ];
	}
	else {
		[ settings setDouble: [ NSDate timeIntervalSinceReferenceDate ] forKey: KEY_RULES_FETCH_TIMESTAMP ];
		[ [ BeaconsManager shared ] startRangingRegionsFromArray: _initialRegions ];
	}

	[ settings setObject: @"NO" forKey: @"reStart" ];
	[ settings synchronize ];


	// NOTE: Konstantin - changed here for not to load initial home page if we have some URL already called
	// NOTE 2: Konstantin - made rule calling only in case of external rules loading
	// show home page or last shown page
//    NSString * lastCalledURL = [ settings objectForKey: @"lastURL" ];
	if(!isLocalLoad)
	{
		[ self callRuleURL: self.currentAppId.initialHomePage
				   forRule: nil
		andTriggeredRegion: nil
			 isRulesUpdate: YES ];

		[ settings setObject: self.currentAppId.initialHomePage forKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];
		[ settings synchronize ];
	}
}


//==============================================================================
- ( NSArray * ) parseInitialRegionsFromString: ( NSString * ) initialRegionsString
{
    __block NSMutableArray * arrayRegionsFinal = [ [ NSMutableArray alloc ] init ];

    NSArray * regions = [ initialRegionsString componentsSeparatedByString: @";" ];

	for( NSString * component in regions )
	{
		if( [ component rangeOfString: @"G" ].location != NSNotFound )
		{
			NSInteger geofenceID = [ [ component stringByReplacingOccurrencesOfString: @"G" withString: @"" ] integerValue ];

			for( EnmoGeofence * geofence in _arrayGeofences )
			{
				if( geofence.geofenceID == geofenceID )
				{
					NSLog(@"Initial geofence: %@", geofence.geofenceName);
					[ arrayRegionsFinal addObject: geofence ];
					break;
				}
			}
		} // if( [ component rangeOfString: @"G" ].location != NSNotFound )
		else if( [ component rangeOfString: @"B" ].location != NSNotFound )
		{
			NSInteger beaconDetailID = [ [ component stringByReplacingOccurrencesOfString: @"B" withString: @"" ] integerValue ];

			for( EnmoBeaconDetail * beacon in _arrayBeacons )
			{
				if( beacon.deviceID == beaconDetailID )
				{
					NSLog(@"Initial beacon: %@", beacon.deviceName);
					[ arrayRegionsFinal addObject: beacon ];
					break;
				}
			}
		} // else if( [ component rangeOfString: @"B" ].location != NSNotFound )
	} // for( NSString * component in regions )

    return arrayRegionsFinal;
}


#pragma mark - Checking if Rule Met

//==============================================================================
- ( void ) processTIRuleWithParams: ( NSArray * ) params
{
	if(params.count >= 3 )
	{
		EnmoRule * rule = params[0];
		EnmoBeaconDetail * region = params[1];
		NSString * dataString = params[2];
		[ self processTIRule: rule andRegion: region andDataString: dataString ];
	}
}


//==============================================================================
- ( void ) processTIRuleWithParamsDuration: ( NSArray * ) params
{
	if(params.count >= 3 )
	{
		EnmoRule * rule = params[0];
		EnmoBeaconDetail * region = params[1];
		NSString * dataString = [ NSString stringWithFormat: @"%@", params[2] ];
		[ self processTIRule: rule andRegion: region andDurationString: dataString ];
	}
}


//==============================================================================
- ( void ) processTIRule: ( EnmoRule * ) rule andRegion: ( EnmoBeaconDetail * ) region andDataString: ( NSString * ) dataString
{
	[ self callRuleURL: rule.urlToCall forRule: rule andTriggeredRegion: region andDataString: dataString isRulesUpdate: NO ];

	if( rule.updateRegions.length )
	{
		[ Logger logToConsole: [ NSString stringWithFormat: @"TEST Update Regions for Entry Rule for region %@ are %@", region.deviceName, rule.updateRegions ] ];

		// launch monitoring update regions of this rule
		NSArray * regions = [ self parseInitialRegionsFromString: rule.updateRegions ];
		[ [ BeaconsManager shared ] startRangingRegionsFromArray: regions ];
	}
}


//==============================================================================
- ( void ) processTIRule: ( EnmoRule * ) rule andRegion: ( EnmoBeaconDetail * ) region andDurationString: ( NSString * ) durationString
{
	[ self callRuleURL: rule.urlToCall forRule: rule andTriggeredRegion: region andDurationString: durationString isRulesUpdate: NO ];

	if( rule.updateRegions.length )
	{
		[ Logger logToConsole: [ NSString stringWithFormat: @"TEST Update Regions for Entry Rule for region %@ are %@", region.deviceName, rule.updateRegions ] ];

		// launch monitoring update regions of this rule
		NSArray * regions = [ self parseInitialRegionsFromString: rule.updateRegions ];
		[ [ BeaconsManager shared ] startRangingRegionsFromArray: regions ];
	}
}


//==============================================================================
- ( void ) checkEntryRuleForRegionWithName: ( NSString * ) regionName
{
    [ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"CHECK ENTRY"] ];

	id region = [ self regionWithName: regionName ];

	BOOL isIoT = NO;

    if( region )
    {
        if( [ region isKindOfClass: [ EnmoBeaconDetail class ] ] && ![ _beaconsInRange containsObject: region ] )
		{
            [ _beaconsInRange addObject: region ];
			[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"BEACON FOUND"] ];

			if([region isIoT]) isIoT = YES;
		}
        else if( [ region isKindOfClass: [ EnmoGeofence class ] ] && ![ _geofencesInRange containsObject: region ] )
		{
            [ _geofencesInRange addObject: region ];
			[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"GEOFENCE FOUND"] ];
        }
    }

    __block UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];


    [ _arrayRules enumerateObjectsUsingBlock:
        ^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
        {
//			NSLog( @"rule.name = %@", rule.ruleName );

			if( ( rule.conditionType == ctEntry ) && [ rule.conditionRegionName isEqualToString: regionName ] )
            {
                [ Logger logToConsole: [ NSString stringWithFormat: @"TEST Found Entry Rule : %@ : for region %@, app state %@",
						rule.ruleName, regionName, state == UIApplicationStateActive ? @"Foreground" : @"Background" ] ];

				[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"RULE FOUND"] ];
				[ Logger logToConsole: @"\n\nRULE FOUND\n\n" ];

                [ Logger logFileWritter: [ NSString stringWithFormat: @"called rule is %@ for %@", rule.ruleName, regionName ] ];
                [ Logger logToConsole: [ NSString stringWithFormat: @"Rule writting for %@", regionName ] ];

				if(isIoT)
				{
					[ Logger logToConsole: @"IoT: Detected" ];
					[ RulesManager showTestLocalNotificationWithText: @"IoT: Detected" ];
					[ [ EddystoneManager shared ] readDataFromIoTDevice: region rule: rule ];
					*stop = YES;
					return;
				}

                [ self callRuleURL: rule.urlToCall forRule: rule andTriggeredRegion: region isRulesUpdate: NO ];

                if( rule.updateRegions.length )
                {
                    [ Logger logToConsole: [ NSString stringWithFormat: @"TEST Update Regions for Entry Rule for region %@ are %@", regionName, rule.updateRegions ] ];

					// launch monitoring update regions of this rule
                    NSArray * regions = [ self parseInitialRegionsFromString: rule.updateRegions ];
					[ [ BeaconsManager shared ] startRangingRegionsFromArray: regions ];
				}

                [ Logger logToConsole: [ NSString stringWithFormat: @"Enrty Rule Met for Region Name: %@", regionName ] ];

            } // if( ( rule.conditionType == ctEntry ) && [ rule.conditionRegionName isEqualToString: regionName ] )
        } // ^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
     ]; // [ _arrayRules enumerateObjectsUsingBlock:

#ifdef CHECK_FOR_RULES_UPON_EVENT
	[ self checkForNewRules ];
#endif
}


//==============================================================================
- ( void ) checkExitRuleForRegionWithName: ( NSString * ) regionName
{
	id region = [ self regionWithName: regionName ];

	// TODO: FJ - remove later
//	if( [ region isKindOfClass: [ EnmoBeaconDetail class ] ]) {
//		EnmoBeaconDetail * beacon = (EnmoBeaconDetail*) region;
//		if(beacon.isFujitsu)
//			return;
//	}

    __block UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

    [ _arrayRules enumerateObjectsUsingBlock:
        ^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
        {
            //[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"RULE FOUND"] ];
            if( ( rule.conditionType == ctExit ) && [ rule.conditionRegionName isEqualToString: regionName ] )
            {
				// [ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"RULE EXECUTING"] ];
                [ Logger logToConsole: [ NSString stringWithFormat: @"TEST Found Exit Rule for region %@, app state %@",
                        regionName, state == UIApplicationStateActive ? @"Foreground" : @"Background" ] ];

				[ Logger logFileWritter: [ NSString stringWithFormat: @"called rule is %@ for %@", rule.ruleName, regionName ] ];

                [ self callRuleURL: rule.urlToCall forRule: rule andTriggeredRegion: region isRulesUpdate: NO ];

                if( rule.updateRegions.length )
                {
                    [ Logger logToConsole: [ NSString stringWithFormat: @"TEST Update Regions for Exit Rule for region %@ are %@", regionName, rule.updateRegions ] ];
                    
//					[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"REGION UPDATING"] ];

					// Launch monitoring update regions of this rule
                    NSArray * regions = [ self parseInitialRegionsFromString: rule.updateRegions ];
                    [ [ BeaconsManager shared ] startRangingRegionsFromArray: regions ];
                }

                [ Logger logToConsole: [ NSString stringWithFormat: @"Exit Rule Met for Region Name: %@", regionName ] ];

            } // if( ( rule.conditionType == ctExit ) && [ rule.conditionRegionName isEqualToString: regionName ] )
        } // ^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
     ]; // [ _arrayRules enumerateObjectsUsingBlock:


    // We remove beacon after we call URL (if it should be called)
    if( region )
    {
        if( [ region isKindOfClass: [ EnmoBeaconDetail class ] ] && [ _beaconsInRange containsObject: region ] )
            [ _beaconsInRange removeObject: region ];
        else if( [ region isKindOfClass: [ EnmoGeofence class ] ] && [ _geofencesInRange containsObject: region ] )
            [ _geofencesInRange removeObject: region ];
    }

#ifdef CHECK_FOR_RULES_UPON_EVENT
	[ self checkForNewRules ];
#endif
}


//==============================================================================
- ( void ) checkEntryRuleForEddystoneWithNamespace: ( NSString * ) esNamespace
									   andInstance: ( NSString * ) esInstance
{
	EnmoBeaconDetail * beacon = [ self eddystoneWithNamespace: esNamespace andInstance: esInstance ];

	NSLog( @"beacon.deviceName = %@", beacon.deviceName );

//	if(!beacon.isEddystone)
//		return;

	BOOL isIoT = NO;

	if( beacon && ![ _beaconsInRange containsObject: beacon ] )
		[ _beaconsInRange addObject: beacon ];

	if( [ beacon isIoT ] )
		isIoT = YES;

	__block UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

	[ _arrayRules enumerateObjectsUsingBlock:
		^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
		{
//			NSLog( @"rule.name = %@", rule.ruleName );
//			NSLog( @"rule.conditionRegionName = %@", rule.conditionRegionName );

			if( ( rule.conditionType == ctEntry ) && [ rule.conditionRegionName isEqualToString: beacon.deviceName ] )
			{
				[ Logger logToConsole: [ NSString stringWithFormat: @"TEST Found Entry Rule : %@ : for region %@, app state %@",
										rule.ruleName, beacon.deviceName, state == UIApplicationStateActive ? @"Foreground" : @"Background" ] ];

				[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"RULE FOUND"] ];

				[ Logger logFileWritter: [ NSString stringWithFormat: @"called rule is %@ for %@", rule.ruleName, beacon.deviceName ] ];
				[ Logger logToConsole: [ NSString stringWithFormat: @"Rule writting for %@", beacon.deviceName ] ];

				if(isIoT)
				{
					[ Logger logToConsole: @"IoT: Detected" ];
					[ RulesManager showTestLocalNotificationWithText: @"IoT: Detected" ];

					[ [ EddystoneManager shared ] readDataFromEddystoneIoTDevice: beacon rule: rule ];
					*stop = YES;
					return;
				}


				[ self callRuleURL: rule.urlToCall forRule: rule andTriggeredRegion: beacon isRulesUpdate: NO ];

				if( rule.updateRegions.length )
				{
					[ Logger logToConsole: [ NSString stringWithFormat: @"TEST Update Regions for Entry Rule for region %@ are %@", beacon.deviceName, rule.updateRegions ] ];

					// launch monitoring update regions of this rule
					NSArray * regions = [ self parseInitialRegionsFromString: rule.updateRegions ];
					[ [ BeaconsManager shared ] startRangingRegionsFromArray: regions ];
				}

				[ Logger logToConsole: [ NSString stringWithFormat: @"Enrty Rule Met for Region Name: %@", beacon.deviceName ] ];

			} // if( ( rule.conditionType == ctEntry ) && [ rule.conditionRegionName isEqualToString: regionName ] )
		 } // ^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
	 ]; // [ _arrayRules enumerateObjectsUsingBlock:

#ifdef CHECK_FOR_RULES_UPON_EVENT
	[ self checkForNewRules ];
#endif
}


//==============================================================================
- ( void ) checkExitRuleForEddystoneWithNamespace: ( NSString * ) esNamespace
									  andInstance: ( NSString * ) esInstance
{
	EnmoBeaconDetail * beacon = [ self eddystoneWithNamespace: esNamespace andInstance: esInstance ];

	if(!beacon.isEddystone)
		return;

	NSLog( @"beacon.deviceName = %@", beacon.deviceName );

	__block UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

	[ _arrayRules enumerateObjectsUsingBlock:
		^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
		{
//			NSLog( @"rule.conditionRegionName = %@", rule.conditionRegionName );

			//[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"RULE FOUND"] ];
			if( ( rule.conditionType == ctExit ) && [ rule.conditionRegionName isEqualToString: beacon.deviceName ] )
			{
				// [ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"RULE EXECUTING"] ];
				[ Logger logToConsole: [ NSString stringWithFormat: @"TEST Found Exit Rule for region %@, app state %@",
										 beacon.deviceName, state == UIApplicationStateActive ? @"Foreground" : @"Background" ] ];

				[ Logger logFileWritter: [ NSString stringWithFormat: @"called rule is %@ for %@", rule.ruleName, beacon.deviceName ] ];

				[ self callRuleURL: rule.urlToCall forRule: rule andTriggeredRegion: beacon isRulesUpdate: NO ];

				if( rule.updateRegions.length )
				{
					[ Logger logToConsole: [ NSString stringWithFormat: @"TEST Update Regions for Exit Rule for region %@ are %@", beacon.deviceName, rule.updateRegions ] ];

//					[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"REGION UPDATING"] ];

					// launch monitoring update regions of this rule
					NSArray * regions = [ self parseInitialRegionsFromString: rule.updateRegions ];
					[ [ BeaconsManager shared ] startRangingRegionsFromArray: regions ];
				}

				[ Logger logToConsole: [ NSString stringWithFormat: @"Exit Rule Met for Region Name: %@", beacon.deviceName ] ];

			} // if( ( rule.conditionType == ctExit ) && [ rule.conditionRegionName isEqualToString: regionName ] )
		 } // ^ ( EnmoRule * rule, NSUInteger idx, BOOL * stop )
	 ]; // [ _arrayRules enumerateObjectsUsingBlock:


	// We remove beacon after we call URL (if it should be called)
	if( beacon.deviceName && [ _beaconsInRange containsObject: beacon ] )
		[ _beaconsInRange removeObject: beacon ];

#ifdef CHECK_FOR_RULES_UPON_EVENT
	[ self checkForNewRules ];
#endif
}


#pragma mark - Helpers

//==============================================================================
- ( void ) callRuleURL: ( NSString * ) urlStringIn
               forRule: ( EnmoRule * ) ruleIn
    andTriggeredRegion: ( id ) triggeredRegionIn
         isRulesUpdate: ( BOOL ) isRulesUpdate
{
	[ self callRuleURL: urlStringIn
			   forRule: ruleIn
	andTriggeredRegion: triggeredRegionIn
		 andDataString: @""
		 isRulesUpdate: isRulesUpdate ];
}


UIBackgroundTaskIdentifier bgUrlLoadTask;

//==============================================================================
- ( void ) callRuleURL: ( NSString * ) urlStringIn
			   forRule: ( EnmoRule * ) ruleIn
	andTriggeredRegion: ( id ) triggeredRegionIn
		 andDataString: ( NSString * ) dataString
		 isRulesUpdate: ( BOOL ) isRulesUpdate
{
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"CALL RULE" ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"CALL RULE" ] ];
	
	if(ruleIn.frequencyCapNum>0)
	{
		NSLog(@"Got a FREQ CAP of %ld PER %lu minutes", (long)ruleIn.frequencyCapNum, (long)ruleIn.frequencyCapPer);
		NSString *key = [NSString stringWithFormat:@"rules_freq_%ld", (long)ruleIn.ID];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSMutableArray *timestamps = [[userDefaults objectForKey:key] mutableCopy];
		if(timestamps==nil)
			timestamps = [[NSMutableArray alloc] init];
		NSLog(@"Last logged timestamps: %@", [timestamps description]);

		if([timestamps count] >= ruleIn.frequencyCapNum){
			NSLog(@"frequency exceeded cap!");
			NSInteger lastTimeInterval = [[timestamps objectAtIndex:(timestamps.count - ruleIn.frequencyCapNum)] integerValue];
			NSDate *lastTime = [[NSDate alloc] initWithTimeIntervalSince1970:lastTimeInterval];
			if([[NSDate date] timeIntervalSinceDate:lastTime] < ruleIn.frequencyCapPer * 60){
				[RulesManager showTestLocalNotificationWithText: @"HIT FREQ CAP in FREQ PERIOD" ];
				NSLog(@"HIT FREQ CAP inside FREQ PERIOD, not showing URL");
				return;
			} else {
				NSLog(@"Enough time has passed can show URL");
			}
		} else {
			NSLog(@"FREQ CAP NOT HIT, can show URL");
		}

		[timestamps addObject:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
		while([timestamps count]>5){
			[timestamps removeObjectAtIndex:0];
		}
		[userDefaults setObject:timestamps forKey:key];
		[userDefaults synchronize];
	} // if(ruleIn.frequencyCapNum>0)
	else
	{
		NSLog(@"No FREQ CAP on this rule");
	}


	if( urlStringIn.length == 0 )
    {
        [ Logger logToConsole: [ NSString stringWithFormat: @"URL string is ZERO" ] ];
        if( [ self.delegate respondsToSelector: @selector( rulesManagerDidCallURL: ) ] ){
            [ Logger logToConsole: [ NSString stringWithFormat: @"In ulesManagerDidCallURL: in If" ] ];
            [ self.delegate rulesManagerDidCallURL: @"" ];
        }

        return;
    }


	__block id triggeredRegionOut = triggeredRegionIn;
	__block EnmoRule * ruleOut = ruleIn;
    __block NSString * urlStringOut=urlStringIn;

    NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];
    NSString * lastCalledURL = [ settings objectForKey: @"lastURL" ];

    if( urlStringIn != lastCalledURL )
	{
		if(dataString.length > 0)
			urlStringOut= [ self addExtraFieldsToURL: urlStringIn
											withRule: ruleOut
								  andTriggeredRegion: triggeredRegionOut
									andIoTDataString: dataString ];
		else
			urlStringOut= [ self addExtraFieldsToURL: urlStringIn
											withRule: ruleOut
								  andTriggeredRegion: triggeredRegionOut ];
	}

	[ Logger logToConsole: [ NSString stringWithFormat: @"BASIC URL = %@", urlStringIn ] ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"URL to call = %@", urlStringOut ] ];

    if( [ urlStringOut rangeOfString: @"http://" ].location == NSNotFound && [ urlStringOut rangeOfString: @"https://" ].location == NSNotFound )
        urlStringOut = [ @"http://" stringByAppendingString: urlStringOut ];


    NSURL * urlToCall = [ NSURL URLWithString: [ urlStringOut stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding ] ];

    if( !urlToCall )
		return;

	UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

	// When app is in Background - we just show notification message
	// When app is in Foreground - we call URL and showing page in Web View

	if( state == UIApplicationStateActive )
	{
		if( ruleOut.notShowContentUponForeground )
		{

		}
		else
		{
			// should show content upon foreground
			if( ruleOut.showContentUponForeground )
				[ settings setObject: urlStringOut forKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];

			if( [ self.delegate respondsToSelector: @selector( rulesManagerDidCallURL: ) ] )
				[ self.delegate rulesManagerDidCallURL: urlStringOut ];
		}
	} // if( state == UIApplicationStateActive )

	else
	{
		bgUrlLoadTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
													 ^
													 {
														 [ [ UIApplication sharedApplication ] endBackgroundTask: bgUrlLoadTask ];
														 bgUrlLoadTask = UIBackgroundTaskInvalid;
													 }
													 ];

		NSURLRequest * urlRequest = [ NSURLRequest requestWithURL: urlToCall ];

		[ NSURLConnection sendAsynchronousRequest: urlRequest
											queue: [ NSOperationQueue mainQueue ]
								completionHandler:
		^ ( NSURLResponse * response, NSData * data, NSError * connectionError )
		{
			if( connectionError )
			{
				[ Logger logToConsole: [ NSString stringWithFormat: @"connectionError %@", connectionError ] ];
			}
			else
			{
				if( ruleOut.showContentBackground )
				{
					NSString * initialString = [ [ NSString alloc ] initWithData: data encoding: NSUTF8StringEncoding ];

					NSLog( @"the string before parsing %@", initialString );

					initialString = [ initialString stringByReplacingOccurrencesOfString: @"\r" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"\n" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"\t" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&" ];
					
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<?xml version=\"1.0\" encoding=\"utf-8\"?>" withString: @"" ];
					
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://192.168.1.125:26457/autolock/\">" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://abhay.ideationts.com:8082/autolock/\">" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://enmo.cloudapp.net/autolock/\">" withString: @"" ];
					
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://atmio.com/rules/\">" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://testenmo.cloudapp.net/autolock/\">" withString: @"" ];
					initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://192.168.1.7/autolock/\">" withString: @"" ];

					initialString = [ initialString stringByReplacingOccurrencesOfString: @"</string>" withString: @"" ];
					initialString = [ initialString stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding ];

					NSString * regionName = nil;

					if( [ triggeredRegionOut isKindOfClass: [ EnmoBeaconDetail class ] ] )
					{
						EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) triggeredRegionOut;
						regionName = beacon.deviceName;
					}
					else if( [ triggeredRegionOut isKindOfClass: [ EnmoGeofence class ] ] )
					{
						EnmoGeofence * geofence = ( EnmoGeofence * ) triggeredRegionOut;
						regionName = geofence.geofenceName;
					}

					if( regionName )
					{
//						if( ( ruleOut.conditionType == ctEntry ) && ( ![ regionName isEqualToString: _lastEnterRegionName ] ) )
//						{
//							_lastEnterRegionName = regionName;
//							_lastExitRegionName = nil;
//							[ RulesManager showLocalNotificationWithText: initialString ];
//						}
//						else if( ( ruleOut.conditionType == ctExit ) && ( ![ regionName isEqualToString: _lastExitRegionName ] ) )
//						{
//							_lastEnterRegionName = nil;
//							_lastExitRegionName = regionName;
//							[ RulesManager showLocalNotificationWithText: initialString ];
//						}

						[ RulesManager showLocalNotificationWithText: initialString ];

					}

				} // if( ruleOut.showContentBackground )

				if( ruleOut.showContentUponForeground )
				{
					NSString * stringURL;

					// if the url is not for background
					if( [ urlStringOut rangeOfString: @"msgtype=0" ].location == NSNotFound )
						stringURL = urlStringOut;
					else // if the url is for background
						stringURL = [ urlStringOut stringByReplacingOccurrencesOfString: @"msgtype=0" withString: @"msgtype=1" ];

					[ settings setObject: stringURL forKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];
				}

				if( isRulesUpdate )
				{
					if( [ self.delegate respondsToSelector: @selector( rulesManagerDidCallURL: ) ] )
						[ self.delegate rulesManagerDidCallURL: urlStringOut ];
				}

			} // else - no connection errors

			[ settings synchronize ];

			[ [ UIApplication sharedApplication ] endBackgroundTask: bgUrlLoadTask ];
			bgUrlLoadTask = UIBackgroundTaskInvalid;

		 } // ^ ( NSURLResponse * response, NSData * data, NSError * connectionError )
	 ];
	} // App State Background
}


//==============================================================================
- ( id ) eddystoneWithNamespace: ( NSString * ) esNamespace
					andInstance: ( NSString * ) esInstance
{
	__block id finalRegion = nil;

	[ _arrayBeacons enumerateObjectsUsingBlock:
		^ ( EnmoBeaconDetail * beacon, NSUInteger idx, BOOL * stop )
		{
			if( [ beacon isEddystone ] )
			{
				if( [ [ beacon.deviceUUID lowercaseString ] isEqualToString: [ esNamespace lowercaseString ] ]
				   && [ [ beacon.deviceMajor lowercaseString ] isEqualToString: [ esInstance lowercaseString ] ] )
				{
					finalRegion = beacon;
					*stop = YES;
					return;
				}
			}
			else if( [ beacon isIoT ] )
			{
				if( [ [ beacon.deviceIDA lowercaseString ] isEqualToString: [ esNamespace lowercaseString ] ]
				   && [ [ beacon.deviceIDB lowercaseString ] isEqualToString: [ esInstance lowercaseString ] ] )
				{
					finalRegion = beacon;
					*stop = YES;
					return;
				}
			}
		}
	 ];

	if( finalRegion ) // no sense to iterate geofences
		return finalRegion;

	return nil;
}


//==============================================================================
- ( id ) regionWithName: ( NSString * ) regionName
{
    __block id finalRegion = nil;

    [ _arrayBeacons enumerateObjectsUsingBlock:
        ^ ( EnmoBeaconDetail * beacon, NSUInteger idx, BOOL * stop )
        {
            if( [ beacon.deviceName isEqualToString: regionName ] )
            {
                finalRegion = beacon;
                return;
            }
        }
     ];

    if( finalRegion ) // no sense to iterate geofences
        return finalRegion;

    // finalRegion not found
    [ _arrayGeofences enumerateObjectsUsingBlock:
        ^ ( EnmoGeofence * geofence, NSUInteger idx, BOOL * stop )
        {
            if( [ geofence.geofenceName isEqualToString: regionName ] )
            {
                finalRegion = geofence;
                return;
            }
        }
     ];

    return finalRegion;
}


//==============================================================================
- ( id ) gimbalWithUUID: ( NSString * ) uuid
{
		if( uuid.length == 0 )
			return nil;

	__block id finalRegion = nil;
	
	[ _arrayBeacons enumerateObjectsUsingBlock:
		^ ( EnmoBeaconDetail * beacon, NSUInteger idx, BOOL * stop )
		{
			if( beacon.isGimbal && [ beacon.deviceUUID isEqualToString: uuid ] )
			{
				finalRegion = beacon;
				return;
			}
		}
	 ];

	return finalRegion;
}


//==============================================================================
- ( NSString * ) addExtraFieldsToURL: ( NSString * ) urlString1
                            withRule: ( EnmoRule * ) rule
                  andTriggeredRegion: ( id ) triggeredRegion
{
	return [ self addExtraFieldsToURL: urlString1 withRule: rule andTriggeredRegion: triggeredRegion andIoTDataString: @"" ];
}


//==============================================================================
- ( NSString * ) addExtraFieldsToURL: ( NSString * ) urlString1
							withRule: ( EnmoRule * ) rule
				  andTriggeredRegion: ( id ) triggeredRegion
					andIoTDataString: ( NSString * ) iotDataString
{

	__block NSString * urlString = urlString1;
    
    [ Logger logToConsole: [ NSString stringWithFormat: @"The UN featured string %@", urlString ] ];

    NSString * lastPathComponent = [ urlString lastPathComponent ];
    [ Logger logToConsole: [ NSString stringWithFormat: @"Last path component %@",lastPathComponent ] ];

	NSRange rangeAutoLockService = [ urlString rangeOfString: @"AutoLockService.asmx" ];
    

	if( rangeAutoLockService.location != NSNotFound && [ triggeredRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )
	{
		// NOTE: FOR TESTS
#ifdef LOCAL_TESTING
		urlString = [ urlString stringByReplacingOccurrencesOfString: @"atmio.com" withString: @"192.168.1.7:26457" ];
		urlString = [ urlString stringByReplacingOccurrencesOfString: @"testenmo.cloudapp.net" withString: @"192.168.1.7:26457" ];
//		urlString = [ urlString stringByReplacingOccurrencesOfString: @"testenmo.cloudapp.net" withString: @"192.168.1.125:26457" ];
#endif

		urlString = [ urlString stringByAppendingFormat: @"?ruleName=%@", rule.ruleName ];

		EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) triggeredRegion;
		urlString = [ urlString stringByAppendingFormat: @"&uuid=%@", beacon.deviceUUID ];

//#ifdef AUTOLOCK
//		urlString = [ urlString stringByAppendingFormat: @"&idfv=%@", [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ] ];
//#else
		urlString = [ urlString stringByAppendingFormat: @"&DID=%@", [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ] ];
//#endif
		urlString = [ urlString stringByAppendingFormat: @"&advertiserId=%d", ( int ) self.advertiserId ];
        
        UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];
        
        if (state==UIApplicationStateBackground) {
            
            if(rule.showContentBackground){
                urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 0];
            }
            else{
                urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
            }
        }
        else{
            urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
        }
        
//       // NSDictionary * dictInfo = ( __bridge NSDictionary * ) CFBundleGetInfoDictionary( CFBundleGetMainBundle() );
//        NSString *buildVersion = [[ NSUserDefaults standardUserDefaults ] objectForKey: @"CFBundleShortVersionString" ];
//        urlString =[urlString stringByAppendingFormat:@"&buildversion=%@",buildVersion];
        

        //NSString *iosVersion=[[UIDevice currentDevice].systemVersion floatValue];
        urlString =[urlString stringByAppendingFormat:@"&OSVersion=%f",[[UIDevice currentDevice].systemVersion floatValue]];
        
//		urlString = [ urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding ];

		return urlString;
	}

    // check if we need to add params to URL
//    NSRange rangePrefixEnmo = [ urlString rangeOfString: @"enmo.cloudapp.net/m/" ];
//    NSRange rangePrefixAtmio = [ urlString rangeOfString: @"atmio.com/m/" ];
//
//    // if current redirect string contains needed prefix and this string doesn't have any params in query - substitute URL
//    if( rangePrefixEnmo.location == NSNotFound && rangePrefixAtmio.location == NSNotFound ){
//        NSLog(@"The featured string in the if loop%@",urlString);
//        return urlString;
//    }


    // check if user already has params in his URL (in this case just add our params at the end)
    NSRange rangeParams = [ lastPathComponent rangeOfString: @"?" ];
	BOOL hasLastSlash = [urlString characterAtIndex: urlString.length - 1] == '/';

	if(hasLastSlash) {
		NSLog(@"hasLastSlash = TRUE");
	}

    BOOL alreadyHasParams = rangeParams.location != NSNotFound;

    if( !alreadyHasParams )
        urlString = [ urlString stringByAppendingString: @"?" ];

    
    NSString * appId = [ [ NSBundle mainBundle ] bundleIdentifier ];
    urlString = [ urlString stringByAppendingFormat: @"%@AppID=%@", alreadyHasParams ? @"&" : @"", appId ];

    NSString * IDFV = [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ];

//#ifdef AUTOLOCK
//	urlString = [ urlString stringByAppendingFormat: @"&idfv=%@", IDFV ];
//#else
    urlString = [ urlString stringByAppendingFormat: @"&DID=%@", IDFV ];
//#endif

    UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];
    
    if (state==UIApplicationStateBackground) {
        
        if(rule.showContentBackground){
            urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 0];
        }
        else{
            urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
        }
    }
    else{
        urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
    }
    
   // NSDictionary * dictInfo = ( __bridge NSDictionary * ) CFBundleGetInfoDictionary( CFBundleGetMainBundle() );
	NSString * buildVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"CFBundleShortVersionString"];
    NSLog(@"version %@",buildVersion);
    urlString =[urlString stringByAppendingFormat:@"&buildversion=%@",buildVersion];
    
    
    //NSString *iosVersion=[[UIDevice currentDevice].systemVersion floatValue];
    urlString =[urlString stringByAppendingFormat:@"&OSVersion=%f",[[UIDevice currentDevice].systemVersion floatValue]];

	NSArray * preferredLanguages = [NSLocale preferredLanguages];
	NSString *language = preferredLanguages.count > 0 ? [preferredLanguages objectAtIndex:0] : @"en-US";
    urlString=[urlString stringByAppendingFormat:@"&phonelang=%@",language];
    
        struct utsname systemInfo;
        uname(&systemInfo);
        
       NSString *deviceName=[NSString stringWithCString:systemInfo.machine
                                  encoding:NSUTF8StringEncoding];
    urlString=[urlString stringByAppendingFormat:@"&devicetype=%@",deviceName];


    if( _geofencesInRange.count )
    {
        urlString = [ urlString stringByAppendingString: @"&geofences=" ];

        __block BOOL isGeofenceTriggered = NO;

        if( triggeredRegion && [ triggeredRegion isKindOfClass: [ EnmoGeofence class ] ] )
        {
            isGeofenceTriggered = YES;

            EnmoGeofence * geofence = ( EnmoGeofence * ) triggeredRegion;

            urlString = [ urlString stringByAppendingFormat:
                         @"%@-%@-%@-%f",
                         geofence.geofenceName,
                         geofence.geofenceLat,
                         geofence.geofenceLong,
                         geofence.geofenceRadius
                         ];
        }

        __block BOOL atLeastOneGeofenceAdded = NO; // idx > 0 will not work here - as triggeredRegion can be first element

        [ _geofencesInRange enumerateObjectsUsingBlock:
            ^ ( EnmoGeofence * geofence, NSUInteger idx, BOOL * stop )
            {
                if( geofence == triggeredRegion )
                    return;

                urlString = [ urlString stringByAppendingFormat:
                             @"%@%@-%@-%@-%f",
                             ( isGeofenceTriggered || atLeastOneGeofenceAdded ) ? @"," : @"", // if triggeredRegion is not nil - then prefix and first geofence was already added, so we need to add comma
                             geofence.geofenceName,
                             geofence.geofenceLat,
                             geofence.geofenceLong,
                             geofence.geofenceRadius
                             ];

                atLeastOneGeofenceAdded = YES;
            }
         ];

    } // if( geofencesInRange.count )


    if( _beaconsInRange.count )
    {
        urlString = [ urlString stringByAppendingString: @"&beacons=" ];

        __block BOOL isBeaconTriggered = NO;

        if( triggeredRegion && [ triggeredRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )
        {
            isBeaconTriggered = YES;

            EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) triggeredRegion;

            urlString = [ urlString stringByAppendingFormat:
                         @"%@-%@-%@-%@",
                         [ beacon.deviceUUID stringByReplacingOccurrencesOfString: @"-" withString: @"" ],
                         beacon.deviceMajor,
                         beacon.deviceMinor,
                         beacon.currentProximity ? beacon.currentProximity : @"Unknown"
                         ];

        } // if( triggeredRegion && [ triggeredRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )


        __block BOOL atLeastOneBeaconAdded = NO; // idx > 0 will not work here - as triggeredRegion can be first element

        [ _beaconsInRange enumerateObjectsUsingBlock:
            ^ ( EnmoBeaconDetail * beacon, NSUInteger idx, BOOL * stop )
            {
                if( beacon == triggeredRegion )
                    return;

                urlString = [ urlString stringByAppendingFormat:
                             @"%@%@-%@-%@-%@",
                             ( isBeaconTriggered || atLeastOneBeaconAdded ) ? @"," : @"", // if triggeredRegion is not nil - then prefix and first beacon was already added, so we need to add comma
                             [ beacon.deviceUUID stringByReplacingOccurrencesOfString: @"-" withString: @"" ],
                             beacon.deviceMajor,
                             beacon.deviceMinor,
                             beacon.currentProximity ? beacon.currentProximity : @"Unknown"
                             ];

                atLeastOneBeaconAdded = YES;
            }
         ];

    } // if( beaconsInRange.count )


    if( self.currentLocation )
    {
        urlString = [ urlString stringByAppendingFormat: @"&lat=%f&long=%f",
                     self.currentLocation.coordinate.latitude,
                     self.currentLocation.coordinate.longitude ];

    } // if( [ RulesManager shared ].currentLocation )

    urlString = [ urlString stringByAppendingFormat: @"&ruleid=%ld", ( long ) rule.ID ];

	if( iotDataString.length > 0 )
	{
		NSArray * components = [ iotDataString componentsSeparatedByString: @"---" ];

		EnmoBeaconDetail * region = ( EnmoBeaconDetail * ) triggeredRegion;

		NSString * IOTDev = @"";

		if( [ region isIoT ] )
			IOTDev = [ NSString stringWithFormat: @"%@-%@-%@", region.deviceName, components.count > 1 ? components[1] : @"Unknown", region.deviceType ];

		NSString * numRecords = components.count > 2 ? components[2] : @"0";

		// TODO: reserved for future
//		BOOL hasUUID = NO;
//		if(hasUUID)
//			IOTDev = [ IOTDev stringByAppendingFormat: @"-", region.deviceUniqueID ];

		urlString = [ urlString stringByAppendingFormat: @"&IOTDev=%@&IOTData=%@&NumRecords=%@", IOTDev, components.count ? components[0] : @"", numRecords ];
	}

    [ Logger logToConsole: [ NSString stringWithFormat: @"The featured string %@", urlString ] ];

	return urlString;
}


////==============================================================================
//- ( void ) updateCurrentLocation: ( CLLocation * ) location
//{
//    self.currentLocation = location;
//}


#pragma mark - Serialization

//==============================================================================
- ( void ) loadLocalRules
{
    self.initialRulesJSON = [ [ NSUserDefaults standardUserDefaults ] objectForKey: @"rules_json" ];
    [ self parseRulesFromDictionary: self.initialRulesJSON isLocalLoad: YES isForced: NO ];
}


//==============================================================================
- ( void ) saveLocalRules
{
    [ Logger logToConsole: @"In save local rules" ];

    if( self.initialRulesJSON ){
        NSLog(@"initialRulesJSON %@",self.initialRulesJSON);
        [ [ NSUserDefaults standardUserDefaults ] setObject: self.initialRulesJSON forKey: @"rules_json" ];
    }
    else
        [ [ NSUserDefaults standardUserDefaults ] removeObjectForKey: @"rules_json" ];

    [ [ NSUserDefaults standardUserDefaults ] setObject: [ NSNumber numberWithInteger: self.advertiserId ] forKey: @"advertiserId" ];
}


//==============================================================================
- ( void ) resetRules
{
    [ Logger logToConsole: @"In reset Rules" ];

    [ [ BeaconsManager shared ] stopRangingForBeacons ];
    
    self.timerRule = nil;
    self.timerRuleAll = nil;
//    self.currentAppId = nil;
//    self.currentIDFV = nil;

    _arrayRules = [ [ NSMutableArray alloc ] init ];

    [ Logger logToConsole: [ NSString stringWithFormat: @"In reset rule size %lu", ( unsigned long ) _arrayRules.count ] ];

	_arrayGeofences = [ [ NSMutableArray alloc ] init ];
    _arrayBeacons = [ [ NSMutableArray alloc ] init ];
    _arrayAppIDs = [ [ NSMutableArray alloc ] init ];
    _arrayIDFVs = [ [ NSMutableArray alloc ] init ];
    _initialRegions = nil;
    _beaconsInRange = [ [ NSMutableArray alloc ] init ];
    _geofencesInRange = [ [ NSMutableArray alloc ] init ];

	self.initialRulesJSON = nil;
}


//==============================================================================
- ( void ) resetFrequencyCaps
{
	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];
	NSDictionary * dict = [ settings dictionaryRepresentation ];
	NSArray * allKeys = dict.allKeys;

	for( int n = 0; n < allKeys.count; n++ )
	{
		NSString * key = allKeys[n];

		if( [ key rangeOfString: @"rules_freq_" ].location != NSNotFound )
			[ settings setObject: nil forKey: allKeys[n] ];
	}

	[ settings synchronize ];
}


//==============================================================================
- ( BOOL ) checkForNewRules
{
	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];
	NSTimeInterval now = [ NSDate timeIntervalSinceReferenceDate ];
	NSTimeInterval old = [ settings doubleForKey: KEY_RULES_FETCH_TIMESTAMP ];
	NSTimeInterval diff = now - old;

	if( ( self.currentAppId.timer > 0 ) && ( diff >= [ RulesManager shared ].currentAppId.timer/100 ) )
	{
		[ RulesManager showTestLocalNotificationWithText: @"CHK: Loading Rules" ];
		[ self getRulesFromServer: NO ];
		return YES;
	}

	return NO;
}


//==============================================================================
- ( void ) saveMonitoredRegions
{
	[ [ BeaconsManager shared ] saveMonitoredRegions ];
}

#pragma mark - Manual Lock

//==============================================================================
- ( void ) sendManualLockMessage
{
	__block UIBackgroundTaskIdentifier bgTask = [ [ UIApplication sharedApplication ] beginBackgroundTaskWithExpirationHandler:
													 ^
													 {
														 [ Logger logToConsole: [ NSString stringWithFormat: @"Background Time in testManualLock:%f",
															   [ [ UIApplication sharedApplication ] backgroundTimeRemaining ] ] ];

														 [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
														 bgTask = UIBackgroundTaskInvalid;
													 }
												 ];


	NSString * emailCurrent = [ [ NSUserDefaults standardUserDefaults ] objectForKey: @"email" ];

#ifdef USE_TESTENMO_SERVER
	BOOL useTestenmo = YES;
#else
	BOOL useTestenmo = NO;
#endif

	NSURL * postURL = [ NSURL URLWithString: [ NSString stringWithFormat:
//                                              MANUAL_LOCK_URL_KONSTANTIN,
											  useTestenmo ? MANUAL_LOCK_URL_TESTENMO : MANUAL_LOCK_URL_ENMO,
											  emailCurrent.length ? emailCurrent : @"",
											  [ NSString stringWithFormat: @"%ld", ( long ) [ RulesManager shared ].advertiserId ] ]
					   ];

	[ Logger logToConsole: [ NSString stringWithFormat: @"The POST URL is >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> %@", postURL ] ];

	dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ),
					   ^
					   {
//						   NSData * data = [ NSData dataWithContentsOfURL: postURL ];
//						   [ Logger logToConsole: [ NSString stringWithFormat: @"The data is ----------------------------------- %@", [ [ NSString alloc ] initWithData: data encoding: NSUTF8StringEncoding ] ] ];

						   // Do the work associated with the task, preferably in chunks.
						   [ [ UIApplication sharedApplication ] endBackgroundTask: bgTask ];
						   bgTask = UIBackgroundTaskInvalid;
					   }
				   );
}


#pragma mark - Logout

//==============================================================================
- ( void ) prepareForLogout
{
	[ self resetFrequencyCaps ];
	[ self resetRules ];

//	[ NSUserDefaults resetStandardUserDefaults ];

	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];
	[ settings removeObjectForKey: @"rules_json" ];
	[ settings removeObjectForKey: @"showDebugNotifications" ];
	[ settings removeObjectForKey: @"advertiserId" ];
	[ settings removeObjectForKey: @"lastURL" ];
	[ settings removeObjectForKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];
	[ settings removeObjectForKey: @"email" ];
	[ settings removeObjectForKey: @"arrayOfRegionsToRemember" ];
	[ settings removeObjectForKey: @"lastMonitoredRegions" ];
	[ settings removeObjectForKey: @"shouldLoadRulesUponForeground" ];
	[ settings removeObjectForKey: @"AppVersion" ];
	[ settings removeObjectForKey: KEY_RULES_FETCH_TIMESTAMP ];

	[ settings synchronize ];


	self.currentLocation = nil;
	self.currentAppId = nil;
	self.currentIDFV = nil;


	//AppDelegate * delegate = ( AppDelegate * ) [ UIApplication sharedApplication ].delegate;

	//[ delegate stop3rdPartyRanging ];

	if( [ self.delegate respondsToSelector: @selector( rulesManagerWillLogout ) ] )
		[ self.delegate rulesManagerWillLogout ];
}




//==============================================================================
- ( void ) callRuleURL: ( NSString * ) urlStringIn
			   forRule: ( EnmoRule * ) ruleIn
	andTriggeredRegion: ( id ) triggeredRegionIn
	 andDurationString: ( NSString * ) durationString
		 isRulesUpdate: ( BOOL ) isRulesUpdate
{
	[ RulesManager showTestLocalNotificationWithText: [ NSString stringWithFormat: @"CALL RULE" ] ];
	[ Logger logToConsole: [ NSString stringWithFormat: @"CALL RULE" ] ];

	if(ruleIn.frequencyCapNum>0)
	{
		NSLog(@"Got a FREQ CAP of %ld PER %lu minutes", (long)ruleIn.frequencyCapNum, (long)ruleIn.frequencyCapPer);
		NSString *key = [NSString stringWithFormat:@"rules_freq_%ld", (long)ruleIn.ID];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSMutableArray *timestamps = [[userDefaults objectForKey:key] mutableCopy];
		if(timestamps==nil)
			timestamps = [[NSMutableArray alloc] init];
		NSLog(@"Last logged timestamps: %@", [timestamps description]);

		if([timestamps count] >= ruleIn.frequencyCapNum){
			NSLog(@"frequency exceeded cap!");
			NSInteger lastTimeInterval = [[timestamps objectAtIndex:(timestamps.count - ruleIn.frequencyCapNum)] integerValue];
			NSDate *lastTime = [[NSDate alloc] initWithTimeIntervalSince1970:lastTimeInterval];
			if([[NSDate date] timeIntervalSinceDate:lastTime] < ruleIn.frequencyCapPer * 60){
				[RulesManager showTestLocalNotificationWithText: @"HIT FREQ CAP in FREQ PERIOD" ];
				NSLog(@"HIT FREQ CAP inside FREQ PERIOD, not showing URL");
				return;
			} else {
				NSLog(@"Enough time has passed can show URL");
			}
		} else {
			NSLog(@"FREQ CAP NOT HIT, can show URL");
		}

		[timestamps addObject:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]]];
		while([timestamps count]>5){
			[timestamps removeObjectAtIndex:0];
		}
		[userDefaults setObject:timestamps forKey:key];
		[userDefaults synchronize];
	} // if(ruleIn.frequencyCapNum>0)
	else
	{
		NSLog(@"No FREQ CAP on this rule");
	}


	if( urlStringIn.length == 0 )
	{
		[ Logger logToConsole: [ NSString stringWithFormat: @"URL string is ZERO" ] ];
		if( [ self.delegate respondsToSelector: @selector( rulesManagerDidCallURL: ) ] ){
			[ Logger logToConsole: [ NSString stringWithFormat: @"In ulesManagerDidCallURL: in If" ] ];
			[ self.delegate rulesManagerDidCallURL: @"" ];
		}

		return;
	}


	__block id triggeredRegionOut = triggeredRegionIn;
	__block EnmoRule * ruleOut = ruleIn;
	__block NSString * urlStringOut=urlStringIn;

	NSUserDefaults * settings = [ NSUserDefaults standardUserDefaults ];
	NSString * lastCalledURL = [ settings objectForKey: @"lastURL" ];

	if( urlStringIn != lastCalledURL )
	{
		if(durationString.length > 0)
			urlStringOut= [ self addExtraFieldsToURL: urlStringIn
											withRule: ruleOut
								  andTriggeredRegion: triggeredRegionOut
								andIoTDurationString: durationString ];
		else
			urlStringOut= [ self addExtraFieldsToURL: urlStringIn
											withRule: ruleOut
								  andTriggeredRegion: triggeredRegionOut ];
	}

	[ Logger logToConsole: [ NSString stringWithFormat: @"BASIC URL = %@", urlStringIn ] ];
	[ Logger logToConsole: [ NSString stringWithFormat: @"URL to call = %@", urlStringOut ] ];

	if( [ urlStringOut rangeOfString: @"http://" ].location == NSNotFound && [ urlStringOut rangeOfString: @"https://" ].location == NSNotFound )
		urlStringOut = [ @"http://" stringByAppendingString: urlStringOut ];


	NSURL * urlToCall = [ NSURL URLWithString: [ urlStringOut stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding ] ];

	if( !urlToCall )
		return;

	UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

	// When app is in Background - we just show notification message
	// When app is in Foreground - we call URL and showing page in Web View

	if( state == UIApplicationStateActive )
	{
		if( ruleOut.notShowContentUponForeground )
		{

		}
		else
		{
			// should show content upon foreground
			if( ruleOut.showContentUponForeground )
				[ settings setObject: urlStringOut forKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];

			if( [ self.delegate respondsToSelector: @selector( rulesManagerDidCallURL: ) ] )
				[ self.delegate rulesManagerDidCallURL: urlStringOut ];
		}
	} // if( state == UIApplicationStateActive )

	else
	{
		NSURLRequest * urlRequest = [ NSURLRequest requestWithURL: urlToCall ];

		[ NSURLConnection sendAsynchronousRequest: urlRequest
											queue: [ NSOperationQueue mainQueue ]
								completionHandler:
		 ^ ( NSURLResponse * response, NSData * data, NSError * connectionError )
		 {
			 if( connectionError )
			 {
				 [ Logger logToConsole: [ NSString stringWithFormat: @"connectionError %@", connectionError ] ];
			 }
			 else
			 {
				 if( ruleOut.showContentBackground )
				 {
					 NSString * initialString = [ [ NSString alloc ] initWithData: data encoding: NSUTF8StringEncoding ];

					 NSLog( @"the string before parsing %@", initialString );

					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"\r" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"\n" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"\t" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&" ];

					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<?xml version=\"1.0\" encoding=\"utf-8\"?>" withString: @"" ];

					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://192.168.1.125:26457/autolock/\">" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://abhay.ideationts.com:8082/autolock/\">" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://enmo.cloudapp.net/autolock/\">" withString: @"" ];

					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://atmio.com/rules/\">" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://testenmo.cloudapp.net/autolock/\">" withString: @"" ];
					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"<string xmlns=\"http://192.168.1.7/autolock/\">" withString: @"" ];

					 initialString = [ initialString stringByReplacingOccurrencesOfString: @"</string>" withString: @"" ];
					 initialString = [ initialString stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding ];

					 NSString * regionName = nil;

					 if( [ triggeredRegionOut isKindOfClass: [ EnmoBeaconDetail class ] ] )
					 {
						 EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) triggeredRegionOut;
						 regionName = beacon.deviceName;
					 }
					 else if( [ triggeredRegionOut isKindOfClass: [ EnmoGeofence class ] ] )
					 {
						 EnmoGeofence * geofence = ( EnmoGeofence * ) triggeredRegionOut;
						 regionName = geofence.geofenceName;
					 }

					 if( regionName )
					 {
 //						if( ( ruleOut.conditionType == ctEntry ) && ( ![ regionName isEqualToString: _lastEnterRegionName ] ) )
 //						{
 //							_lastEnterRegionName = regionName;
 //							_lastExitRegionName = nil;
 //							[ RulesManager showLocalNotificationWithText: initialString ];
 //						}
 //						else if( ( ruleOut.conditionType == ctExit ) && ( ![ regionName isEqualToString: _lastExitRegionName ] ) )
 //						{
 //							_lastEnterRegionName = nil;
 //							_lastExitRegionName = regionName;
 //							[ RulesManager showLocalNotificationWithText: initialString ];
 //						}

						 [ RulesManager showLocalNotificationWithText: initialString ];
					 }

				 } // if( ruleOut.showContentBackground )

				 if( ruleOut.showContentUponForeground )
				 {
					 NSString * stringURL;

					 // if the url is not for background
					 if( [ urlStringOut rangeOfString: @"msgtype=0" ].location == NSNotFound )
						 stringURL = urlStringOut;
					 else // if the url is for background
						 stringURL = [ urlStringOut stringByReplacingOccurrencesOfString: @"msgtype=0" withString: @"msgtype=1" ];

					 [ settings setObject: stringURL forKey: KEY_URL_TO_SHOW_UPON_FOREGROUND ];
				 }

				 if( isRulesUpdate )
				 {
					 if( [ self.delegate respondsToSelector: @selector( rulesManagerDidCallURL: ) ] )
						 [ self.delegate rulesManagerDidCallURL: urlStringOut ];
				 }

			 } // else - no connection errors
			 
			 [ settings synchronize ];
			 
		 } // ^ ( NSURLResponse * response, NSData * data, NSError * connectionError )
		 ];
	} // App State Background
}

//==============================================================================
- ( NSString * ) addExtraFieldsToURL: ( NSString * ) urlString1
							withRule: ( EnmoRule * ) rule
				  andTriggeredRegion: ( id ) triggeredRegion
				andIoTDurationString: ( NSString * ) iotDurationString
{
	__block NSString * urlString = urlString1;

	[ Logger logToConsole: [ NSString stringWithFormat: @"The UN featured string %@", urlString ] ];

	NSString * lastPathComponent = [ urlString lastPathComponent ];
	[ Logger logToConsole: [ NSString stringWithFormat: @"Last path component %@",lastPathComponent ] ];

	NSRange rangeAutoLockService = [ urlString rangeOfString: @"AutoLockService.asmx" ];


	if( rangeAutoLockService.location != NSNotFound && [ triggeredRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )
	{
		// NOTE: FOR TESTS
#ifdef LOCAL_TESTING
		urlString = [ urlString stringByReplacingOccurrencesOfString: @"atmio.com" withString: @"192.168.1.7:26457" ];
		urlString = [ urlString stringByReplacingOccurrencesOfString: @"testenmo.cloudapp.net" withString: @"192.168.1.7:26457" ];
		//		urlString = [ urlString stringByReplacingOccurrencesOfString: @"testenmo.cloudapp.net" withString: @"192.168.1.125:26457" ];
#endif

		urlString = [ urlString stringByAppendingFormat: @"?ruleName=%@", rule.ruleName ];

		EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) triggeredRegion;
		urlString = [ urlString stringByAppendingFormat: @"&uuid=%@", beacon.deviceUUID ];

		//#ifdef AUTOLOCK
		//		urlString = [ urlString stringByAppendingFormat: @"&idfv=%@", [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ] ];
		//#else
		urlString = [ urlString stringByAppendingFormat: @"&DID=%@", [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ] ];
		//#endif
		urlString = [ urlString stringByAppendingFormat: @"&advertiserId=%d", ( int ) self.advertiserId ];

		UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

		if (state==UIApplicationStateBackground) {

			if(rule.showContentBackground){
				urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 0];
			}
			else{
				urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
			}
		}
		else{
			urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
		}

		//       // NSDictionary * dictInfo = ( __bridge NSDictionary * ) CFBundleGetInfoDictionary( CFBundleGetMainBundle() );
		//        NSString *buildVersion = [[ NSUserDefaults standardUserDefaults ] objectForKey: @"CFBundleShortVersionString" ];
		//        urlString =[urlString stringByAppendingFormat:@"&buildversion=%@",buildVersion];


		//NSString *iosVersion=[[UIDevice currentDevice].systemVersion floatValue];
		urlString =[urlString stringByAppendingFormat:@"&OSVersion=%f",[[UIDevice currentDevice].systemVersion floatValue]];

		//		urlString = [ urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding ];

		return urlString;
	}

	// check if we need to add params to URL
	//    NSRange rangePrefixEnmo = [ urlString rangeOfString: @"enmo.cloudapp.net/m/" ];
	//    NSRange rangePrefixAtmio = [ urlString rangeOfString: @"atmio.com/m/" ];
	//
	//    // if current redirect string contains needed prefix and this string doesn't have any params in query - substitute URL
	//    if( rangePrefixEnmo.location == NSNotFound && rangePrefixAtmio.location == NSNotFound ){
	//        NSLog(@"The featured string in the if loop%@",urlString);
	//        return urlString;
	//    }


	// check if user already has params in his URL (in this case just add our params at the end)
	NSRange rangeParams = [ lastPathComponent rangeOfString: @"?" ];
	BOOL hasLastSlash = [urlString characterAtIndex: urlString.length - 1] == '/';

	if(hasLastSlash) {
		NSLog(@"hasLastSlash = TRUE");
	}

	BOOL alreadyHasParams = rangeParams.location != NSNotFound;

	if( !alreadyHasParams )
		urlString = [ urlString stringByAppendingString: @"?" ];


	NSString * appId = [ [ NSBundle mainBundle ] bundleIdentifier ];
	urlString = [ urlString stringByAppendingFormat: @"%@AppID=%@", alreadyHasParams ? @"&" : @"", appId ];

	NSString * IDFV = [ [ [ UIDevice currentDevice ] identifierForVendor ] UUIDString ];

	//#ifdef AUTOLOCK
	//	urlString = [ urlString stringByAppendingFormat: @"&idfv=%@", IDFV ];
	//#else
	urlString = [ urlString stringByAppendingFormat: @"&DID=%@", IDFV ];
	//#endif

	UIApplicationState state = [ [ UIApplication sharedApplication ] applicationState ];

	if (state==UIApplicationStateBackground) {

		if(rule.showContentBackground){
			urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 0];
		}
		else{
			urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
		}
	}
	else{
		urlString = [ urlString stringByAppendingFormat: @"&msgtype=%d", 1];
	}

	// NSDictionary * dictInfo = ( __bridge NSDictionary * ) CFBundleGetInfoDictionary( CFBundleGetMainBundle() );
	NSString * buildVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"CFBundleShortVersionString"];
	NSLog(@"version %@",buildVersion);
	urlString =[urlString stringByAppendingFormat:@"&buildversion=%@",buildVersion];


	//NSString *iosVersion=[[UIDevice currentDevice].systemVersion floatValue];
	urlString =[urlString stringByAppendingFormat:@"&OSVersion=%f",[[UIDevice currentDevice].systemVersion floatValue]];

	NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
	urlString=[urlString stringByAppendingFormat:@"&phonelang=%@",language];


	struct utsname systemInfo;
	uname(&systemInfo);

	NSString *deviceName=[NSString stringWithCString:systemInfo.machine
											encoding:NSUTF8StringEncoding];
	urlString=[urlString stringByAppendingFormat:@"&devicetype=%@",deviceName];


	if( _geofencesInRange.count )
	{
		urlString = [ urlString stringByAppendingString: @"&geofences=" ];

		__block BOOL isGeofenceTriggered = NO;

		if( triggeredRegion && [ triggeredRegion isKindOfClass: [ EnmoGeofence class ] ] )
		{
			isGeofenceTriggered = YES;

			EnmoGeofence * geofence = ( EnmoGeofence * ) triggeredRegion;

			urlString = [ urlString stringByAppendingFormat:
						 @"%@-%@-%@-%f",
						 geofence.geofenceName,
						 geofence.geofenceLat,
						 geofence.geofenceLong,
						 geofence.geofenceRadius
						 ];
		}

		__block BOOL atLeastOneGeofenceAdded = NO; // idx > 0 will not work here - as triggeredRegion can be first element

		[ _geofencesInRange enumerateObjectsUsingBlock:
		 ^ ( EnmoGeofence * geofence, NSUInteger idx, BOOL * stop )
		 {
			 if( geofence == triggeredRegion )
				 return;

			 urlString = [ urlString stringByAppendingFormat:
						  @"%@%@-%@-%@-%f",
						  ( isGeofenceTriggered || atLeastOneGeofenceAdded ) ? @"," : @"", // if triggeredRegion is not nil - then prefix and first geofence was already added, so we need to add comma
						  geofence.geofenceName,
						  geofence.geofenceLat,
						  geofence.geofenceLong,
						  geofence.geofenceRadius
						  ];

			 atLeastOneGeofenceAdded = YES;
		 }
		 ];

	} // if( geofencesInRange.count )


	if( _beaconsInRange.count )
	{
		urlString = [ urlString stringByAppendingString: @"&beacons=" ];

		__block BOOL isBeaconTriggered = NO;

		if( triggeredRegion && [ triggeredRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )
		{
			isBeaconTriggered = YES;

			EnmoBeaconDetail * beacon = ( EnmoBeaconDetail * ) triggeredRegion;

			urlString = [ urlString stringByAppendingFormat:
						 @"%@-%@-%@-%@",
						 [ beacon.deviceUUID stringByReplacingOccurrencesOfString: @"-" withString: @"" ],
						 beacon.deviceMajor,
						 beacon.deviceMinor,
						 beacon.currentProximity ? beacon.currentProximity : @"Unknown"
						 ];

		} // if( triggeredRegion && [ triggeredRegion isKindOfClass: [ EnmoBeaconDetail class ] ] )


		__block BOOL atLeastOneBeaconAdded = NO; // idx > 0 will not work here - as triggeredRegion can be first element

		[ _beaconsInRange enumerateObjectsUsingBlock:
		 ^ ( EnmoBeaconDetail * beacon, NSUInteger idx, BOOL * stop )
		 {
			 if( beacon == triggeredRegion )
				 return;

			 urlString = [ urlString stringByAppendingFormat:
						  @"%@%@-%@-%@-%@",
						  ( isBeaconTriggered || atLeastOneBeaconAdded ) ? @"," : @"", // if triggeredRegion is not nil - then prefix and first beacon was already added, so we need to add comma
						  [ beacon.deviceUUID stringByReplacingOccurrencesOfString: @"-" withString: @"" ],
						  beacon.deviceMajor,
						  beacon.deviceMinor,
						  beacon.currentProximity ? beacon.currentProximity : @"Unknown"
						  ];

			 atLeastOneBeaconAdded = YES;
		 }
		 ];

	} // if( beaconsInRange.count )


	if( self.currentLocation )
	{
		urlString = [ urlString stringByAppendingFormat: @"&lat=%f&long=%f",
					 self.currentLocation.coordinate.latitude,
					 self.currentLocation.coordinate.longitude ];

	} // if( [ RulesManager shared ].currentLocation )

	urlString = [ urlString stringByAppendingFormat: @"&ruleid=%ld", ( long ) rule.ID ];

	if( iotDurationString.length > 0 )
		urlString = [ urlString stringByAppendingFormat: @"&duration=%@", iotDurationString ];

	[ Logger logToConsole: [ NSString stringWithFormat: @"The featured string %@", urlString ] ];

	return urlString;
}

@end
