//
//  EmailManager.m
//  enmo autolock
//

#import "EmailManager.h"
#import <MessageUI/MessageUI.h>


EmailManager * emailManager = nil;


@interface EmailManager()
{
	NSMutableArray * _arrayStrings;
}

@end



@implementation EmailManager

//==============================================================================
+ ( EmailManager * ) shared
{
	return nil;

	if( emailManager == nil )
		emailManager = [ [ EmailManager alloc ] init ];
	
	return emailManager;
}


//==============================================================================
- ( void ) addString: ( NSString * ) string
{
	if( _arrayStrings == nil )
		_arrayStrings = [ [ NSMutableArray alloc ] init ];
	
	if( string.length )
		[ _arrayStrings addObject: [ NSString stringWithFormat: @"%@ === %@", [ NSDate date ], string ] ];
}


//==============================================================================
- ( void ) sendEmailWithViewController: ( UIViewController < MFMailComposeViewControllerDelegate > * ) controller
{
	if( controller == nil )
		return;
	
	// Email Subject
#ifdef AUTOLOCK
	NSString * emailTitle = @"Auto-lock App Email";
#else
	NSString * emailTitle = @"enmo Development App Email";
#endif
	
	// Email Content
	NSMutableString * messageBody = [ [ NSMutableString alloc ] init ];
	
	for( NSString * string in _arrayStrings )
		[ messageBody appendFormat: @"%@\n", string ];
	
	// To address
	MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
	mc.mailComposeDelegate = controller;
	[mc setSubject:emailTitle];
	[mc setMessageBody:messageBody isHTML:NO];
	
	// Present mail view controller on screen
	[controller presentViewController:mc animated:YES completion:NULL];
}


//==============================================================================
- ( void ) cleanup
{
	[ _arrayStrings removeAllObjects ];
}


////==============================================================================
//- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
//{
//	switch (result)
//	{
//		case MFMailComposeResultCancelled:
//			NSLog(@"Mail cancelled");
//			break;
//		case MFMailComposeResultSaved:
//			NSLog(@"Mail saved");
//			break;
//		case MFMailComposeResultSent:
//			NSLog(@"Mail sent");
//			break;
//		case MFMailComposeResultFailed:
//			NSLog(@"Mail sent failure: %@", [error localizedDescription]);
//			break;
//		default:
//			break;
//	}
//	
//	// Close the Mail Interface
////	[self dismissViewControllerAnimated:YES completion:NULL];
//}

@end
