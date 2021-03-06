/**
 * Copyright (C) 2015 Gimbal, Inc. All rights reserved.
 *
 * This software is the confidential and proprietary information of Gimbal, Inc.
 *
 * The following sample code illustrates various aspects of the Gimbal SDK.
 *
 * The sample code herein is provided for your convenience, and has not been
 * tested or designed to work on any particular system configuration. It is
 * provided AS IS and your use of this sample code, whether as provided or
 * with any modification, is at your own risk. Neither Gimbal, Inc.
 * nor any affiliate takes any liability nor responsibility with respect
 * to the sample code, and disclaims all warranties, express and
 * implied, including without limitation warranties on merchantability,
 * fitness for a specified purpose, and against infringement.
 */
#import <Foundation/Foundation.h>
#import <Common/QLAvailability.h>

typedef enum  {
    QLPlaceEventTypeAt = 1,
    QLPlaceEventTypeLeft = 2,
} QLPlaceEventType;

typedef enum  {
    QLPlaceTypePrivate = 0,
    QLPlaceTypeOrganization = 1,
} QLPlaceType;

@class QLPlace;

@interface QLPlaceEvent : NSObject

@property (nonatomic, assign) QLPlaceEventType eventType;
@property (nonatomic, strong) NSDate *time;
@property (nonatomic, strong) QLPlace *place;
@property (nonatomic, assign) QLPlaceType placeType;
@property (nonatomic, assign) long placeId DEPRECATED;
@property (nonatomic, strong) NSString *placeName DEPRECATED;

@end
