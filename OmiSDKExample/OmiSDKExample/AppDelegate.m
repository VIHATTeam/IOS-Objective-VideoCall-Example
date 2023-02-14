//
//  AppDelegate.m
//  OmiSDKExample
//
//  Created by QUOC VIET  on 14/02/2023.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX];
    provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
    voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
    
    [self requestPushNotificationPermissions];
    
    return YES;
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
    
    // print the token in the console.
    NSLog(@"Push Notification Token: %@", [token copy]);
    
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
            // the user has denied the permission
            case UNAuthorizationStatusDenied:
            {
                // notify user to enable push notification permission in settings
                break;
            }
            // the user has accepted; Register a PN token
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



#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"OmiSDKExample"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
