//
//  EnmoManager.h
//  EnmoSDK
//
//  Created by APPLE on 14/03/18.
//  Copyright © 2018 APPLE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EnmoManager : NSObject

+ (EnmoManager*) shared;

- ( void ) start3rdPartyRanging;

- ( void ) stop3rdPartyRanging;

@end
