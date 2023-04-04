//
//  AppDelegate.m
//  OmiKitSample
//
//  Created by VietHQ on 2022/10/31.
//  Copyright © 2022 VietHQ. All rights reserved.
//

#import "AppDelegate.h"
#import <OmiKit/OmiKit-umbrella.h>
//#import <AVFoundation/>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX];
#else
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_PRODUCTION];
#endif

    provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
    voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
    
    [self requestPushNotificationPermissions];
    [OmiClient setLogLevel:5];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


#pragma "PUSH NOTIFICATION"

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // could not register a Push Notification token at this time.
    NSLog(@"Push Notification Token: %@", [error description]);
    

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // app has received a push notification
}
- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    // parse token bytes to string
    const char *data = [devToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < [devToken length]; i++)
    {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    [OmiClient setUserPushNotificationToken:[token copy]];
}


- (void)requestPushNotificationPermissions
{
    // iOS 10+
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch (settings.authorizationStatus)
        {
            // User hasn't accepted or rejected permissions yet. This block shows the allow/deny dialog
            case UNAuthorizationStatusNotDetermined:
            {
                center.delegate = self;
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
                 {
                     if(granted)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [[UIApplication sharedApplication] registerForRemoteNotifications];
                         });
                     }
                     else
                     {
                         // notify user to enable push notification permission in settings
                     }
                 }];
                break;
            }
            case UNAuthorizationStatusAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
                break;
            }
            default:
                break;
        }
    }];
}




@end
