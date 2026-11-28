#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BHTFeatureSwitchPolicy) {
    BHTFeatureSwitchPolicySetting,
    BHTFeatureSwitchPolicyTabGate,
    BHTFeatureSwitchPolicyBranding,
    BHTFeatureSwitchPolicyPremium,
    BHTFeatureSwitchPolicyVerticalBar,
};

@interface BHTFeatureSwitchRule : NSObject
@property (nonatomic, copy, readonly) NSSet<NSString*>* keys;
@property (nonatomic, copy, readonly) NSString* prefix;
@property (nonatomic, copy, readonly) NSString* suffix;
@property (nonatomic, copy, readonly) NSString* setting;
// NSNumber for bool/number switches, NSString for string switches
@property (nonatomic, strong, readonly) id enabledValue;
@property (nonatomic, strong, readonly) id disabledValue;
@property (nonatomic, readonly) BHTFeatureSwitchPolicy policy;
@end

NSArray<BHTFeatureSwitchRule*>* BHTFeatureSwitchRules(void);
BHTFeatureSwitchRule* BHTFixedSwitches(NSArray<NSString*>* keys, NSNumber* value);
BHTFeatureSwitchRule* BHTSettingSwitches(NSArray<NSString*>* keys, NSString* setting,
                                         NSNumber* enabledValue, NSNumber* disabledValue);
BHTFeatureSwitchRule* BHTPatternSwitches(NSString* prefix, NSString* suffix, NSString* setting,
                                         NSNumber* enabledValue, NSNumber* disabledValue);
BHTFeatureSwitchRule* BHTTabGateSwitches(NSArray<NSString*>* keys);
BHTFeatureSwitchRule* BHTBrandedSwitches(NSArray<NSString*>* keys, NSNumber* twitterValue,
                                         NSNumber* otherValue);
BHTFeatureSwitchRule* BHTPremiumSwitches(NSArray<NSString*>* keys);
// Applies enabledValue only while the vertical tab rail is active (setting on,
// Liquid Glass on, device has a vertical bar); otherwise X keeps its own value.
BHTFeatureSwitchRule* BHTVerticalBarSwitches(NSArray<NSString*>* keys, id value);
