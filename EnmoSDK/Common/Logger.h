//
//  Logger.h
//  enmo autolock
//


#import <Foundation/Foundation.h>


@interface Logger : NSObject
{

}

+ ( void ) logFileWritter: ( NSString * ) theString;
+ ( void ) logToConsole: ( NSString * ) logString;
+ ( void ) logToConsole: ( NSString * ) logString andShowLocalNotification: ( BOOL ) showNotification;

@end
