//
//  EnmoIDFV.h
//  enmo autolock
//


#import <Foundation/Foundation.h>


@interface EnmoIDFV : NSObject
{

}

@property ( readwrite, assign ) NSInteger ID;
@property ( readwrite, retain ) NSString * name;
@property ( readwrite, retain ) NSString * idfv;

- ( id ) initWithDictionary: ( NSDictionary * ) dictRule;

@end
