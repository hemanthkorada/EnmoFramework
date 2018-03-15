//
//  Logger.m
//  enmo autolock
//


#import "Logger.h"


// NSFileHandle * file = nil;


@implementation Logger

//==============================================================================
+ ( void ) showLocalNotificationWithText: ( NSString * ) text
{
	if( text.length == 0 )
		return;

	UILocalNotification * notification = [ [ UILocalNotification alloc ] init ];
	notification.fireDate = [ NSDate date ];
	notification.alertAction = @"OK";
	notification.alertBody = text;
	[ [ UIApplication sharedApplication ] presentLocalNotificationNow: notification ];
}


//==============================================================================
+ ( void ) logFileWritter: ( NSString * ) theString
{
	return;

/*
	NSDate * currentTime = [ NSDate date ];

	NSDateFormatter * dateFormatter = [ [ NSDateFormatter alloc ] init ];
	[ dateFormatter setDateFormat: @"hh-mm" ];

	NSString * resultString = [ dateFormatter stringFromDate: currentTime ];
	//	NSLog( @"CURRENT DATE TIME: %@ %@", currentTime, resultString );
	theString = [ NSString stringWithFormat: @"%@ %@: %@\n", currentTime, resultString, theString ];

	// Get the file path
	NSString * documentsDirectory = [ NSSearchPathForDirectoriesInDomains ( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex: 0 ];
	NSString * fileName = [ documentsDirectory stringByAppendingPathComponent: @"myLogFile.txt" ];
	//  NSLog(@"1st file name %@",fileName);

	//create file if it doesn't exist
	if( ![ [ NSFileManager defaultManager ] fileExistsAtPath: fileName ] )
	{
		[ Logger logToConsole: @"File found" ];
		[ [ NSFileManager defaultManager ] createFileAtPath: fileName contents: nil attributes: nil ];
	}

	// Append text to file (you'll probably want to add a newline every write)
	file = [ NSFileHandle fileHandleForUpdatingAtPath: fileName ];
	[ file seekToEndOfFile ];
//    NSLog( @"Writting" );
	[ file writeData: [ theString dataUsingEncoding: NSUTF8StringEncoding ] ];
	[ file closeFile ];
 */
}


//==============================================================================
+ ( void ) logToConsole: ( NSString * ) logString
{
	[ Logger logToConsole: logString andShowLocalNotification: NO ];
}


//==============================================================================
+ ( void ) logToConsole: ( NSString * ) logString
andShowLocalNotification: ( BOOL ) showNotification
{
    NSLog(@"%@",logString);
//	BOOL logsEnabled = [ [ [ PreferencesManager shared ] objectForKey: KEY_SETTINGS_WRITE_CONSOLE_NOTIFICATIONS ] boolValue ];
//	BOOL notificationsEnabled = [ [ [ PreferencesManager shared ] objectForKey: KEY_SETTINGS_SHOW_DEBUG_NOTIFICATIONS ] boolValue ];
//
//	if( logsEnabled )
//	{
//		NSLog( @"%@", logString );
//
//		if( showNotification && notificationsEnabled )
//			[ Logger showLocalNotificationWithText: logString ];
//	}
}

@end
