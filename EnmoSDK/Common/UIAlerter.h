//
//  UIAlerter.h
//  Beacons Master
//


#import <Foundation/Foundation.h>


@interface CustomUIAlertView : UIAlertView < UIAlertViewDelegate >
{

}

@property ( copy ) void ( ^ alertResultBlock ) ( void );
@property ( copy ) void ( ^ alertResultBlockCancel ) ( void );
@property ( copy ) void ( ^ textAlertResultBlock ) ( CustomUIAlertView * );

@end



@interface UIAlerter : NSObject
{

}

+ ( BOOL ) isAlertShown;

+ ( void ) showOKAlertWithTitle: ( NSString * ) title
                        message: ( NSString * ) message
                 andResultBlock: ( void ( ^ ) ( void ) ) resultBlock;

+ ( void ) showYesNoAlertWithTitle: ( NSString * ) title
                           message: ( NSString * ) message
                       resultBlock: ( void ( ^ ) ( void ) ) resultBlock
                    andCancelBlock: ( void ( ^ ) ( void ) ) cancelBlock;

+ ( void ) showOkCancelTextFieldAlertWithTitle: ( NSString * ) title
                                       message: ( NSString * ) message
                                andResultBlock: ( void ( ^ ) ( CustomUIAlertView * ) ) resultBlock;

+ ( void ) showOkSettingsAlertWithTitle: ( NSString * ) title
								message: ( NSString * ) message
								okBlock: ( void ( ^ ) ( void ) ) okBlock
					   andSettingsBlock: ( void ( ^ ) ( void ) ) settingsBlock;

@end
