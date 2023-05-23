//
//  AppDelegate.swift
//  OmicallDevSwift
//
//  Created by PRO 2019 16' on 18/05/2023.
//

import UIKit
import OmiKit
import PushKit
import NotificationCenter

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pushkitManager: PushKitManager?
    var provider: CallKitProviderDelegate?
    var voipRegistry: PKPushRegistry?

    var deviceOrientation = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        OmiClient.setEnviroment(KEY_OMI_APP_ENVIROMENT_SANDBOX)
        provider = CallKitProviderDelegate.init(callManager: OMISIPLib.sharedInstance().callManager)
        voipRegistry = PKPushRegistry.init(queue: .main)
        pushkitManager = PushKitManager.init(voipRegistry: voipRegistry)
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.requestPushNotificationPermissions()
        }
        OmiClient.setLogLevel(5)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        AppRouter.shared.openMain()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.hexString
        OmiClient.setUserPushNotificationToken(deviceTokenString)
    }
    
    func requestPushNotificationPermissions() {
        if #available(iOS 10.0, *) {
            let center  = UNUserNotificationCenter.current()

            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                if error == nil{
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
        else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

