//
//  GimbalsManager.h
//  enmo autolock
//


//#define GIMBAL_SDK_VERSION_1
#define GIMBAL_SDK_VERSION_2

#import <Foundation/Foundation.h>

#ifdef GIMBAL_SDK_VERSION_1

#import <ContextCore/QLContextCoreConnector.h>
#import <ContextLocation/QLContextPlaceConnector.h>
#import <FYX/FYX.h>
#import <FYX/FYXSightingManager.h>
#import <FYX/FYXVisitManager.h>
#import <FYX/FYXTransmitter.h>
#import <FYX/FYXLogging.h>

#else

#import <Gimbal/Gimbal.h>

#endif


@interface GimbalsManager : NSObject
{

}

#ifdef GIMBAL_SDK_VERSION_1

#else
@property ( readwrite, retain ) GMBLPlaceManager * placeManager;
@property ( readwrite, retain ) GMBLBeaconManager * beaconManager;
@property ( readwrite, retain ) GMBLCommunicationManager * communicationManager;
#endif

@property ( readwrite, assign ) NSInteger dwellTimeTimeout;
@property ( readwrite, assign ) NSInteger stayAwayTimeout;
@property ( readwrite, assign ) NSInteger stayAwayTimeoutBG;
@property ( readwrite, assign ) NSInteger enterSignalStrength;
@property ( readwrite, assign ) NSInteger exitSignalStrength;
@property ( readwrite, assign ) NSInteger signalStrengthWindow;

+ ( GimbalsManager * ) shared;

#ifdef GIMBAL_SDK_VERSION_1
- ( void ) initVisitManager;
- ( void ) readPreferences;
- ( void ) savePreferences;
#endif

- ( void ) startMonitoring;
- ( void ) stopMonitoring;

@end
