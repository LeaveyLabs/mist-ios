//
//  AppDelegate.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/02/25.
//

import UIKit
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
import FirebasePerformance
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
                
        // Bring bar button items closer together
        let stackViewAppearance = UIStackView.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        stackViewAppearance.spacing = -10
        
//        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
//        Performance.sharedInstance().isInstrumentationEnabled = false
//        Performance.sharedInstance().isDataCollectionEnabled = false
//        Analytics.setAnalyticsCollectionEnabled(false)
        
        //MUST COME in didfinishlaunchingwithOptions
        let notifCenter = UNUserNotificationCenter.current()
        notifCenter.delegate = self
        NotificationsManager.shared.registerForNotificationsOnStartupIfAccessExists()
        
        FirebaseApp.configure()
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    // These delegate methods MUST live in App Delegate and nowhere else!
    
    //MARK: - Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }

        let token = tokenParts.joined()
        setGlobalDeviceToken(token: token)
        print("SET GLOBAL DEVICE TOKEN")
        print("Device Token: \(token)")
    }

    //user was in app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("userInfo:", notification.request.content.userInfo )
        print("aps", notification.request.content.userInfo["aps"])
        guard
            let userInfo = notification.request.content.userInfo as? [String : AnyObject]
        else { return }
        Task {
            await handleNotificationWhileInApp(userInfo: userInfo)
        }
//        completionHandler([.alert, .sound, .badge]) //when the user is in the app, we don't want to do an ios system displays
    }
    
    func handleNotificationWhileInApp(userInfo: [String: AnyObject]) async {
        let tabVC = UIApplication.shared.windows.first!.rootViewController as! SpecialTabBarController
        
//        if let newDm = userInfo[Notification.Name.newDM.rawValue] {
////            let tag = asdf[Notification.Key.taggingUser]
//        }
//        try await PostService.singleton.getMentions()
//
//        try await MatchRequestService.singleton.loadMatchRequests()
//        
        do {
            try await MistboxManager.shared.fetchSyncedMistbox()
            //update badge count
        } catch {
            print("FAILED TO LOAD DATA AFTER RECEIVING BACKGROUND NOTIFICATION")
        }
    }

    //user was not in app
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("userInfo:", response.notification.request.content.userInfo )
        guard
            let userInfo = response.notification.request.content.userInfo as? [String : AnyObject]
        else { return }
        
        handleNotificationOpenFromLockScreen(userInfo: userInfo)
        completionHandler()

    }
    
    func handleNotificationOpenFromLockScreen(userInfo: [String: AnyObject]) {
        let tabVC = UIApplication.shared.windows.first!.rootViewController as! SpecialTabBarController

        //if a match request
        tabVC.selectedIndex = 2
        
        //if a mistbox, do nothing
        
        //if a mention, open up mentions? do nothing for now
        
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
}
