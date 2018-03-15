//
//  RulesManager.h
//  enmo rules
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "EnmoRule.h"
#import "EnmoBeaconDetail.h"
#import "EnmoGeofence.h"
#import "EnmoAppId.h"
#import "EnmoIDFV.h"


@protocol RulesManagerDelegate < NSObject >

- ( void ) rulesManagerDidStartRulesLoading;
- ( void ) rulesManagerDidFailRulesParsing;
- ( void ) rulesManagerDidFinishRulesParsing;
- ( void ) rulesManagerDidCallURL: ( NSString * ) url;
- ( void ) rulesManagerWillLogout;

@end



@interface RulesManager : NSObject

@property ( readwrite, retain ) id < RulesManagerDelegate > delegate;
@property ( readwrite, retain ) CLLocation * currentLocation;
@property ( readwrite, retain ) EnmoAppId * currentAppId;
@property ( readwrite, retain ) EnmoIDFV * currentIDFV;
@property ( readwrite, retain ) EnmoRule * timerRule;
@property ( readwrite, retain ) EnmoRule * timerRuleAll;
@property ( readwrite, assign ) NSInteger advertiserId;

@property ( readwrite, strong ) NSDictionary * initialRulesJSON;
@property ( readwrite, strong ) NSString * pushNotificationsToken;
@property ( readwrite, assign ) BOOL isLoadingRules;


+ ( RulesManager * ) shared;
+ ( void ) showLocalNotificationWithText: ( NSString * ) text;
+ ( void ) showTestLocalNotificationWithText: ( NSString * ) text;

- ( void ) getUsersAdvertiserIDWithCompletionBlock: ( void ( ^ ) ( void ) ) resultBlock;
- ( void ) getRulesFromServer: ( BOOL ) isForced;
- ( void ) parseRulesFromData: ( NSData * ) data isForced: ( BOOL ) isForced;

- ( void ) sendManualLockMessage;

- ( id ) regionWithName: ( NSString * ) regionName;
- ( id ) gimbalWithUUID: ( NSString * ) uuid;

- ( void ) checkEntryRuleForRegionWithName: ( NSString * ) regionName;
- ( void ) checkExitRuleForRegionWithName: ( NSString * ) regionName;

- ( void ) checkEntryRuleForEddystoneWithNamespace: ( NSString * ) esNamespace andInstance: ( NSString * ) esInstance;
- ( void ) checkExitRuleForEddystoneWithNamespace: ( NSString * ) esNamespace andInstance: ( NSString * ) esInstance;

- ( void ) processTIRuleWithParams: ( NSArray * ) params;
- ( void ) processTIRuleWithParamsDuration: ( NSArray * ) params;
- ( void ) processTIRule: ( EnmoRule * ) rule andRegion: ( EnmoBeaconDetail * ) region andDataString: ( NSString * ) dataString;

- ( void ) saveMonitoredRegions;

- ( void ) loadLocalRules;
- ( void ) saveLocalRules;
- ( void ) resetRules;

- ( NSString * ) addExtraFieldsToURL: ( NSString * ) urlString withRule: ( EnmoRule * ) rule andTriggeredRegion: ( id ) triggeredRegion;

- ( void ) prepareForLogout;
- ( void ) resetFrequencyCaps;
- ( BOOL ) checkForNewRules;

@end
