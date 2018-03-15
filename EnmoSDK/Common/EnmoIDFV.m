//
//  EnmoIDFV.m
//  enmo autolock
//


#import "EnmoIDFV.h"


@implementation EnmoIDFV

//==============================================================================
- ( id ) initWithDictionary: ( NSDictionary * ) dictAppID
{
    self = [ super init ];

    if( self )
    {
        self.ID     = [ [ dictAppID objectForKey: @"id" ] integerValue ];
        self.name   = [ dictAppID objectForKey: @"Name" ];
        self.idfv   = [ dictAppID objectForKey: @"Idfv" ];
    }

    return self;
}

@end
