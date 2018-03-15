//
//  EnmoRule.m
//  enmo rules
//


#import "EnmoRule.h"


@implementation EnmoRule

//==============================================================================
- ( id ) initWithDictionary: ( NSDictionary * ) dictRule
{
    self = [ super init ];

    if( self )
    {
        self.ID                         = [ [ dictRule objectForKey: @"id" ] integerValue ];
        self.ruleName                   = [ dictRule objectForKey: @"RuleName" ];
        self.status                     = [ dictRule objectForKey: @"Status" ];
        self.createdOn                  = [ dictRule objectForKey: @"CreatedOn" ];
		self.appID                      = [ dictRule objectForKey: @"AppID" ];
		self.IDFV                       = [ dictRule objectForKey: @"IDFV" ];
		self.frequencyCapNum            = [ [ dictRule objectForKey: @"FrequencyCapNum" ] integerValue ];
		self.frequencyCapPer            = [ [ dictRule objectForKey: @"FrequencyCapPer" ] integerValue ];
		self.email						= [ dictRule objectForKey: @"Email" ];
        self.conditionType              = ( EnmoRuleConditionType ) [ [ dictRule objectForKey: @"ConditionType" ] integerValue ];
        self.conditionRegionName        = [ dictRule objectForKey: @"ConditionRegionName" ];
        self.updateRegions              = [ dictRule objectForKey: @"UpdateRegions" ];
        self.urlToCall                  = [ dictRule objectForKey: @"UrlToCall" ];

        //Show content when app is in background
        self.showContentBackground      = [ [ dictRule objectForKey: @"ShowContentBackground" ] boolValue ];
        
        //show content when app next in foreground
        self.showContentUponForeground  = [ [ dictRule objectForKey: @"ShowContentUponForeground" ] boolValue ];
        
        //Don't change the web view when app is in foreground
        self.notShowContentUponForeground  = [ [ dictRule objectForKey: @"NotShowContentUponForeground" ] boolValue ];
    }

    return self;
}

@end
