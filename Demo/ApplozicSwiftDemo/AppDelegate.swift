//
//  AppDelegate.swift
//  ApplozicSwiftDemo
//
//  Created by Mukesh Thawani on 11/08/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Applozic
import ApplozicSwift
import Pushy

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        BuddyBuildSDK.setup()
        

//        registerForNotification()
    
        ALKPushNotificationHandler.shared.dataConnectionNotificationHandler()
        let alApplocalNotificationHnadler : ALAppLocalNotifications =  ALAppLocalNotifications.appLocalNotificationHandler()
        alApplocalNotificationHnadler.dataConnectionNotificationHandler()
        
        let pushy = Pushy(UIApplication.shared)
        
        pushy.register({ (error, deviceToken) in
            if error != nil {
                return print ("Registration failed: \(error!)")
            }
            let alApplocalNotificationHnadler : ALAppLocalNotifications =  ALAppLocalNotifications.appLocalNotificationHandler();
            alApplocalNotificationHnadler.dataConnectionNotificationHandler();
            
            let internetRech = alApplocalNotificationHnadler.internetConnectionReach
            
            NotificationCenter.default.removeObserver(self, name:NSNotification.Name(rawValue: "AL_kReachabilityChangedNotification"), object: nil)
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AL_kReachabilityChangedNotification"), object: nil, queue: nil, using: { notification in
                NSLog("Reloadtable notification received")
                
                let reach = notification.object as? ALReachability
                if reach == internetRech {
                    if reach?.isReachable() != nil {
                        let deviceKeyString = ALUserDefaultsHandler.getDeviceKeyString()
                        if ALUserDefaultsHandler.isLoggedIn() {
                            ALMessageService.getLatestMessage(forUser: deviceKeyString) { (array, error) in
                                if(error == nil){
                                    print("message sync on connectivity  change ")
                                }
                            }
                        }
                    }
                }
            })

            if deviceToken != ALUserDefaultsHandler.getApnDeviceToken() {
                let alRegisterUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
                alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceToken, withCompletion: { (response, error) in
                    print ("Response:\(response)")
                    
                })
            }
            
            UserDefaults.standard.set(deviceToken, forKey: "pushyDeviceToken")
        })
            
        if (ALUserDefaultsHandler.isLoggedIn())
        {
            // Get login screen from storyboard and present it
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as UIViewController
            self.window?.makeKeyAndVisible();
            self.window?.rootViewController!.present(viewController, animated:true, completion: nil)

        }
        if (launchOptions != nil)
        {
            //let dictionary = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary
            let dictionary = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary

            if (dictionary != nil)
            {
                print("launched from push notification")
                let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()

                let appState: NSNumber = NSNumber(value: 0 as Int32)
                let applozicProcessed = alPushNotificationService.processPushNotification(launchOptions,updateUI:appState)
                if (!applozicProcessed)
                {

                }
            }
        }

        pushy.setNotificationHandler({ (data, completionHandler) in
            var message = "Data from Applozic\(data)"
            let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
            alPushNotificationService.notificationArrived(to: application, with: data)
            if let aps = data["aps"] as? [AnyHashable : Any] {
                if let payloadMessage = aps["alert"] as? String {
                    message = payloadMessage
                }
            }
            completionHandler(UIBackgroundFetchResult.newData)
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("APP_ENTER_IN_BACKGROUND")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_BACKGROUND"), object: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        ALPushNotificationService.applicationEntersForeground()
        print("APP_ENTER_IN_FOREGROUND")

        NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ALDBHandler.sharedInstance().saveContext()
    }

//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
//    {
//
//        print("DEVICE_TOKEN_DATA :: \(deviceToken.description)")  // (SWIFT = 3) : TOKEN PARSING
//
//        var deviceTokenString: String = ""
//        for i in 0..<deviceToken.count
//        {
//            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
//        }
//        print("DEVICE_TOKEN_STRING :: \(deviceTokenString)")
//
//        if (ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString)
//        {
//            let alRegisterUserClientService: ALRegisterUserClientService = ALRegisterUserClientService()
//            alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
//                print ("REGISTRATION_RESPONSE :: \(response)")
//            })
//        }
//    }
//
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
//    {
//        print("Couldn’t register: \(error)")
//    }

//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any])
//    {
//        print("Received notification :: \(userInfo.description)")
//        let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
//        alPushNotificationService.notificationArrived(to: application, with: userInfo)
//    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        print("Received notification With Completion :: \(userInfo.description)")
        let alPushNotificationService: ALPushNotificationService = ALPushNotificationService()
        alPushNotificationService.notificationArrived(to: application, with: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }


//    func registerForNotification() {
//        if #available(iOS 10.0, *) {
//            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
//
//                if granted {
//                    DispatchQueue.main.async {
//                        UIApplication.shared.registerForRemoteNotifications()
//                    }
//                }
//            }
//        } else {
//            // Fallback on earlier versions
//            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            UIApplication.shared.registerUserNotificationSettings(settings)
//            UIApplication.shared.registerForRemoteNotifications()
//
//        }
//    }
}

