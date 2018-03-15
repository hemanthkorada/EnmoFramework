//
//  BLEService.h
//  enmo
//


@interface BLEService : NSObject
{

}

@property ( readwrite, retain ) NSString * name;
@property ( readwrite, retain ) CBService * cbService;
@property ( readwrite, retain ) NSMutableDictionary * dictCharacteristics;

- ( id ) initWithCBService: ( CBService * ) service;

@end
