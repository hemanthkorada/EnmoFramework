//
//  UIAlerter.m
//  Beacons Master
//


#import "UIAlerter.h"


BOOL alertIsShown = NO;


@implementation CustomUIAlertView

#pragma mark - UIAlertViewDelegate

//==============================================================================
- ( void ) alertView: ( UIAlertView * ) alertView
clickedButtonAtIndex: ( NSInteger ) buttonIndex
{
    alertIsShown = NO;

    if( buttonIndex == 0 )
    {
        if( alertView.alertViewStyle == UIAlertViewStylePlainTextInput )
		{
			if( self.textAlertResultBlock )
				self.textAlertResultBlock( self );
		}
        else
		{
			if( self.alertResultBlock )
				self.alertResultBlock();
		}
    }
    else if( buttonIndex == 1 )
    {
		if( self.alertResultBlockCancel )
			self.alertResultBlockCancel();
    }
}

@end



@implementation UIAlerter

//==============================================================================
+ ( BOOL ) isAlertShown
{
    return alertIsShown;
}


//==============================================================================
+ ( void ) showOKAlertWithTitle: ( NSString * ) title
                        message: ( NSString * ) message
                 andResultBlock: ( void ( ^ ) ( void ) ) resultBlock
{
    alertIsShown = YES;

    CustomUIAlertView * alertView = [ [ CustomUIAlertView alloc ] initWithTitle: title ? title : @""
                                                                        message: message ? message : @""
                                                                       delegate: self
                                                              cancelButtonTitle: @"OK"
                                                              otherButtonTitles: nil ];
    alertView.alertResultBlock = resultBlock;
    alertView.delegate = alertView;

    [ alertView show ];
}


//==============================================================================
+ ( void ) showYesNoAlertWithTitle: ( NSString * ) title
                           message: ( NSString * ) message
                       resultBlock: ( void ( ^ ) ( void ) ) resultBlock
                    andCancelBlock: ( void ( ^ ) ( void ) ) cancelBlock
{
    alertIsShown = YES;

    CustomUIAlertView * alertView = [ [ CustomUIAlertView alloc ] initWithTitle: title ? title : @""
                                                                        message: message ? message : @""
                                                                       delegate: self
                                                              cancelButtonTitle: @"Yes"
                                                              otherButtonTitles: @"No", nil ];

    alertView.alertResultBlock = resultBlock;
    alertView.alertResultBlockCancel = cancelBlock;
    alertView.delegate = alertView;

    [ alertView show ];
}


//==============================================================================
+ ( void ) showOkCancelTextFieldAlertWithTitle: ( NSString * ) title
                                       message: ( NSString * ) message
                                andResultBlock: ( void ( ^ ) ( CustomUIAlertView * ) ) resultBlock
{
    alertIsShown = YES;

    CustomUIAlertView * alertView = [ [ CustomUIAlertView alloc ] initWithTitle: title ? title : @""
                                                                        message: message ? message : @""
                                                                       delegate: self
                                                              cancelButtonTitle: @"Yes"
                                                              otherButtonTitles: @"No", nil ];

    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.textAlertResultBlock = resultBlock;
    alertView.delegate = alertView;

    [ alertView show ];
}


//==============================================================================
+ ( void ) showOkSettingsAlertWithTitle: ( NSString * ) title
								message: ( NSString * ) message
								okBlock: ( void ( ^ ) ( void ) ) okBlock
					   andSettingsBlock: ( void ( ^ ) ( void ) ) settingsBlock
{
	alertIsShown = YES;

	CustomUIAlertView * alertView = [ [ CustomUIAlertView alloc ] initWithTitle: title ? title : @""
																		message: message ? message : @""
																	   delegate: self
															  cancelButtonTitle: @"Settings"
															  otherButtonTitles: @"OK", nil ];

	alertView.alertResultBlock = settingsBlock;
	alertView.alertResultBlockCancel = okBlock;
	alertView.delegate = alertView;

	[ alertView show ];
}

@end
