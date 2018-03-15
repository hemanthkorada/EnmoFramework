//
//  EnmoAppId.h
//  enmo autolock
//


#import <Foundation/Foundation.h>


@interface EnmoAppId : NSObject

@property ( readwrite, assign ) NSInteger ID;
@property ( readwrite, retain ) NSString * appName;
@property ( readwrite, retain ) NSString * appID;
@property ( readwrite, assign ) NSInteger timer;
@property ( readwrite, retain ) NSString * initialRegions;
@property ( readwrite, retain ) NSString * initialHomePage;
@property ( readwrite, retain ) NSArray * arrayInitialRegions;
@property ( readwrite, retain ) NSString * timestamp;

- ( id ) initWithDictionary: ( NSDictionary * ) dictAppID;

@end
