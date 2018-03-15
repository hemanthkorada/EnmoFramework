//
//  BLEService.m
//  enmo
//


#import "BLEService.h"


@implementation BLEService

//==============================================================================
- ( id ) initWithCBService: ( CBService * ) service
{
    self = [ super init ];

    if( self )
    {
        self.cbService = service;
        self.dictCharacteristics = [ [ NSMutableDictionary alloc ] init ];
    }

    return self;
}

@end
