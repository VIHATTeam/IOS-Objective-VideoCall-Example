//
//  OmiSwiftUIApp.swift
//  OmiSwiftUI
//
//  Created by PRO 2019 16' on 23/05/2023.
//

import SwiftUI
import OmiKit

// no changes in your AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
    var pushkitManager: PushKitManager?
    var provider: CallKitProviderDelegate?
    var voipRegistry: PKPushRegistry?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        OmiClient.setEnviroment(KEY_OMI_APP_ENVIROMENT_SANDBOX)
        provider = CallKitProviderDelegate.init(callManager: OMISIPLib.sharedInstance().callManager)
        voipRegistry = PKPushRegistry.init(queue: .main)
        pushkitManager = PushKitManager.init(voipRegistry: voipRegistry)
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.requestPushNotificationPermissions()
        }
        OmiClient.setLogLevel(5)
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

@main
struct OmiSwiftUIApp: App {
    
    // inject into SwiftUI life-cycle via adaptor !!!
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}


extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
