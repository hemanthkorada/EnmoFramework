//
//  EnmoManager.h
//  EnmoSDK
//
//  Created by APPLE on 14/03/18.
//  Copyright © 2018 APPLE. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_URL_TO_SHOW_UPON_FOREGROUND            @"URLtoShowUponForeground"


@protocol EnmoManagerDelegate <NSObject>

@optional
- (void) enmoManagerDidDeliverURL: (NSString*) url;
@end

@interface EnmoManager : NSObject{
    
}

@property (strong, nonatomic) void (^fetchCompletionHandler)(UIBackgroundFetchResult);
@property (nonatomic, weak) id<EnmoManagerDelegate> delegate;


+ (EnmoManager*) shared;

- ( void ) start3rdPartyRanging;

- ( void ) stop3rdPartyRanging;

- ( void ) loadRulesFromServer: (BOOL) isForced;

- ( NSInteger ) appIdTimer;

- (BOOL) checkNewRules;

- ( void ) setAdvertiserId: (int) advID;

- ( int) getAdvertiserId;

-(void) prepareForAppTerminate;


@end
