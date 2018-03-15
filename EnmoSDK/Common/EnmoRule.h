//
//  EnmoRule.h
//  enmo rules
//


#import <Foundation/Foundation.h>


typedef enum EnmoRuleConditionType
{
    ctEntry     = 0,
    ctExit      = 1,
    ctTimer     = 2,
    ctInRange   = 3,

} EnmoRuleConditionType;



@interface EnmoRule : NSObject
{

}

@property ( readwrite, assign ) NSInteger ID;
@property ( readwrite, retain ) NSString * ruleName;
@property ( readwrite, retain ) NSString * status;
@property ( readwrite, retain ) NSString * createdOn;
@property ( readwrite, assign ) NSString * appID;
@property ( readwrite, assign ) NSString * IDFV;
@property ( readwrite, assign ) NSInteger frequencyCapNum;
@property ( readwrite, assign ) NSInteger frequencyCapPer;
@property ( readwrite, retain ) NSString * email;
@property ( readwrite, assign ) EnmoRuleConditionType conditionType;

@property ( readwrite, retain ) NSString * conditionRegionName;
@property ( readwrite, retain ) NSString * updateRegions;
@property ( readwrite, retain ) NSString * urlToCall;

@property ( readwrite, assign ) BOOL showContentUponForeground;
@property ( readwrite, assign ) BOOL showContentBackground;
@property ( readwrite, assign ) BOOL notShowContentUponForeground;

- ( id ) initWithDictionary: ( NSDictionary * ) dictRule;

@end
