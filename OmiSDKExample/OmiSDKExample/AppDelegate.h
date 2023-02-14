//
//  AppDelegate.h
//  OmiSDKExample
//
//  Created by QUOC VIET  on 14/02/2023.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <OmiKit/OmiKit-umbrella.h>
#import <OmiKit/Constants.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    PushKitManager *pushkitManager;
    CallKitProviderDelegate * provider;
    PKPushRegistry * voipRegistry;


}



@end

