//
//  EnmoManager.h
//  EnmoSDK
//
//  Created by APPLE on 14/03/18.
//  Copyright © 2018 APPLE. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_URL_TO_SHOW_UPON_FOREGROUND            @"URLtoShowUponForeground"



@interface EnmoManager : NSObject{
    
}

@property (strong, nonatomic) void (^fetchCompletionHandler)(UIBackgroundFetchResult);


+ (EnmoManager*) shared;

- ( void ) start3rdPartyRanging;

- ( void ) stop3rdPartyRanging;

- ( void ) loadRulesFromServer: (BOOL) isForced;

- ( NSInteger ) appIdTimer;

- (void) checkNewRules;



@end
