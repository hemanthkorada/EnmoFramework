//
//  EmailManager.h
//  enmo autolock
//


#import <Foundation/Foundation.h>


@interface EmailManager : NSObject

+ ( EmailManager * ) shared;

- ( void ) addString: ( NSString * ) string;
- ( void ) sendEmailWithViewController: ( UIViewController * ) controller;
- ( void ) cleanup;

@end
