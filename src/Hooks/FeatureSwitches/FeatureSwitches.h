#import "../HookHelpers.h"

extern __thread BOOL DashPanelIDQuery;
extern __thread BOOL ReportGenuineSubscription;
extern __thread BOOL ReportGenuineTabGates;

// nil lets X handle the value; otherwise the NSNumber or NSString to report
id BHTFeatureSwitchOverrideValue(NSString* key, BOOL reportGenuineTabGates,
                                 BOOL (^isGenuinelyPremium)(void));
id FeatureSwitchAnyOverrideForKey(NSString* key);
// Typed views of the same override, for the bool/number and string accessors
NSNumber* FeatureSwitchOverrideValueForKey(NSString* key);
NSString* FeatureSwitchStringOverrideForKey(NSString* key);
BOOL panelIsGenuinelyAvailable(long long panelID);
NSArray* panelIDsForDashSnapshot(NSArray* panelIDs);
void BHTUpdateSensitiveMediaRevealButton(HFSensitiveTweetBlurredInterstitialView* overlay);
void BHTScheduleSensitiveMediaReveal(HFSensitiveTweetBlurredInterstitialView* overlay);
