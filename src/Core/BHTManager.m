//
//  BHTdownloadManager.m
//  NeoFreeBird
//
//  Created by BandarHelal.
//

#include <stdlib.h>

#import "Core/BHTBundle.h"
#import "Core/BHTManager.h"
#import "Core/BHTSettings.h"
#import "Settings/ModernSettingsViewController.h"

@implementation BHTManager
+ (void)cleanCache {
    NSArray<NSURL*>* DocumentFiles = [[NSFileManager defaultManager]
          contentsOfDirectoryAtURL:
              [NSURL
                  fileURLWithPath:NSSearchPathForDirectoriesInDomains(
                                      NSDocumentDirectory, NSUserDomainMask, true)
                                      .firstObject]
        includingPropertiesForKeys:@[]
                           options:NSDirectoryEnumerationSkipsHiddenFiles
                             error:nil];

    for (NSURL* file in DocumentFiles) {
        if ([file.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
    }

    NSArray<NSURL*>* TempFiles = [[NSFileManager defaultManager]
          contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory()]
        includingPropertiesForKeys:@[]
                           options:NSDirectoryEnumerationSkipsHiddenFiles
                             error:nil];

    for (NSURL* file in TempFiles) {
        if ([file.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
        if ([file.pathExtension.lowercaseString isEqualToString:@"mov"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
        if ([file.pathExtension.lowercaseString isEqualToString:@"tmp"]) {
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
        if ([file hasDirectoryPath]) {
            if ([BHTManager isEmpty:file]) {
                [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
            }
        }
    }
}
+ (BOOL)isEmpty:(NSURL*)url {
    NSArray* FolderFiles = [[NSFileManager defaultManager]
          contentsOfDirectoryAtURL:url
        includingPropertiesForKeys:@[]
                           options:NSDirectoryEnumerationSkipsHiddenFiles
                             error:nil];
    if (FolderFiles.count == 0) {
        return true;
    } else {
        return false;
    }
}
+ (id)sharedFontGroup {
    // TAEStandardFontGroup was renamed to TFNUIDefaultFontGroup in 12.3.
    return [objc_getClass("TFNUIDefaultFontGroup") sharedFontGroup];
}
+ (UIFont*)menuTitleFont {
    UIFont* font = [[self sharedFontGroup] headline2BoldFont];
    if (!font)
        font = [UIFont boldSystemFontOfSize:17.0];
    return font;
}
+ (NSString*)getVideoQuality:(NSString*)url {
    NSMutableArray* q = [NSMutableArray new];
    NSArray* splits = [url componentsSeparatedByString:@"/"];
    for (int i = 0; i < [splits count]; i++) {
        NSString* item = [splits objectAtIndex:i];
        NSArray* dir = [item componentsSeparatedByString:@"x"];
        for (int k = 0; k < [dir count]; k++) {
            NSString* item2 = [dir objectAtIndex:k];
            if (!(item2.length == 0)) {
                if ([BHTManager doesContainDigitsOnly:item2]) {
                    if (!(item2.integerValue > 10000)) {
                        if (!(q.count == 2)) {
                            [q addObject:item2];
                        }
                    }
                }
            }
        }
    }
    if (q.count == 0) {
        return @"GIF";
    }
    return [NSString stringWithFormat:@"%@x%@", q.firstObject, q.lastObject];
}
+ (void)save:(NSURL*)url {
    [[PHPhotoLibrary sharedPhotoLibrary]
        performChangesAndWait:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        }
                        error:nil];
}
+ (void)saveGIF:(NSURL*)url {
    [[PHPhotoLibrary sharedPhotoLibrary]
        performChangesAndWait:^{
            [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
        }
                        error:nil];
}
+ (void)showSaveVC:(NSURL*)url {
    UIActivityViewController* acVC =
        [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                          applicationActivities:nil];
    if (is_iPad()) {
        acVC.popoverPresentationController.sourceView = topMostController().view;
        acVC.popoverPresentationController.sourceRect =
            CGRectMake(topMostController().view.bounds.size.width / 2.0,
                       topMostController().view.bounds.size.height / 2.0, 1.0, 1.0);
    }
    [topMostController() presentViewController:acVC animated:true completion:nil];
}

+ (MediaInformation*)getM3U8Information:(NSURL*)mediaURL {
    MediaInformationSession* mediaInformationSession =
        [FFprobeKit getMediaInformation:mediaURL.absoluteString];
    MediaInformation* mediaInformation =
        [mediaInformationSession getMediaInformation];
    return mediaInformation;
}
+ (NSString*)getDownloadingPercent:(float)progress {
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    return [numberFormatter stringFromNumber:[NSNumber numberWithFloat:progress]];
}

+ (BOOL)isTwitterBranded {
    static BOOL branded = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        branded = [[[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"]
            isEqual:@"Twitter"];
    });
    return branded;
}

// LiveContainer runs a guest app inside its own process rather than installing
// it, and exports the guest's redirected home directory to it. Both variables
// come straight from LiveContainer's guest-side hooks (LC_HOME_PATH normally,
// LP_HOME_PATH in LiveProcess mode), so checking for either is more durable
// than matching on the guest's bundle path layout.
+ (BOOL)isLiveContainer {
    static BOOL liveContainer = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        liveContainer = getenv("LC_HOME_PATH") != NULL || getenv("LP_HOME_PATH") != NULL;
    });
    return liveContainer;
}

// UITraitCollection.verticalBarEdge (iOS 27.1) is UIVerticalBarEdgeUnspecified (0)
// on hardware without a vertical bar, so a nonzero value identifies the iPhone Duo
// without matching model names. The trait can also be unspecified on the Duo's
// own inner display, so the first positive result is remembered for good.
static NSString* const BHTVerticalBarDeviceKey = @"nfb_device_has_vertical_bar";
static _Atomic(BOOL) BHTVerticalBarSeen;

// Read through KVC so this builds against SDKs older than 27.1.
static BOOL BHTTraitsHaveVerticalBar(UITraitCollection* traits) {
    return [[traits valueForKey:@"verticalBarEdge"] integerValue] != 0;
}

// Window scenes carry the per-display traits; their windows inherit them.
static BOOL BHTAnyDisplayHasVerticalBar(void) {
    if (BHTTraitsHaveVerticalBar(UIScreen.mainScreen.traitCollection)) {
        return YES;
    }
    for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class] &&
            BHTTraitsHaveVerticalBar(((UIWindowScene*)scene).traitCollection)) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)deviceHasVerticalBar {
    static BOOL traitExists;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        traitExists = [UITraitCollection
            instancesRespondToSelector:NSSelectorFromString(@"verticalBarEdge")];
        BHTVerticalBarSeen = traitExists && [[NSUserDefaults standardUserDefaults]
                                                boolForKey:BHTVerticalBarDeviceKey];
    });
    if (!traitExists || BHTVerticalBarSeen || !NSThread.isMainThread) {
        return BHTVerticalBarSeen;
    }
    if (!BHTAnyDisplayHasVerticalBar()) {
        return NO;
    }
    BHTVerticalBarSeen = YES;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BHTVerticalBarDeviceKey];
    return YES;
}

+ (UIViewController*)BHTSettingsWithAccount:(TFNTwitterAccount*)twAccount {
    return [[ModernSettingsViewController alloc] initWithAccount:twAccount];
}

// https://stackoverflow.com/a/45356575/9910699
+ (BOOL)doesContainDigitsOnly:(NSString*)string {
    NSCharacterSet* nonDigits =
        [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    BOOL containsDigitsOnly =
        [string rangeOfCharacterFromSet:nonDigits].location == NSNotFound;

    return containsDigitsOnly;
}

@end
