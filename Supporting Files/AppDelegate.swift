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
        

//        print(rootViewController)
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let controller = storyboard.instantiateViewController(withIdentifier: "Requester") as! RequestViewController
//        rootViewController.present(controller, animated: true, completion: { () -> Void in
//
//        })
        
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
        print("WILL PRESENT NOTIFIATION. userInfo:")
        guard let userInfo = notification.request.content.userInfo as? [String : AnyObject] else { return }
        Task {
            await handleNotificationWhileInApp(userInfo: userInfo)
        }
//        completionHandler([.alert, .sound, .badge]) //when the user is in the app, we don't want to do an ios system displays
    }
    
    //user was not in app
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("DID RECEIVE NOTIFIATION. userInfo:")
        guard let userInfo = response.notification.request.content.userInfo as? [String : AnyObject] else { return }
        handleNotificationOpenFromLockScreen(userInfo: userInfo)
        completionHandler()
    }
    
    func handleNotificationWhileInApp(userInfo: [String: AnyObject]) async {
        guard let tabVC = UIApplication.shared.windows.first?.rootViewController as? SpecialTabBarController else { return }
        guard let notificaitonType = userInfo[Notification.extra.type.rawValue] as? String else { return }
        
        do {
            let json = userInfo[Notification.extra.data.rawValue]
            let data = try JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)
            if notificaitonType == NotificationTypes.tag.rawValue {
//                let tag = try JSONDecoder().decode(Tag.self, from: data)
                try await PostService.singleton.loadMentions()
                try await CommentService.singleton.fetchTaggedTags()
                DispatchQueue.main.async {
                    tabVC.refreshBadgeCount()
                    let visibleVC = SceneDelegate.visibleViewController
                    if let mistboxVC = visibleVC as? MistboxViewController {
                        mistboxVC.navBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
                        mistboxVC.navBar.accountBadgeHub.bump()
                    } else if let conversationsVC = visibleVC as? ConversationsViewController {
                        conversationsVC.customNavBar.accountBadgeHub.setCount(DeviceService.shared.unreadMentionsCount())
                        conversationsVC.customNavBar.accountBadgeHub.bump()
                    }
                }
            } else if notificaitonType == NotificationTypes.message.rawValue {
                let message = try JSONDecoder().decode(Message.self, from: data)
                if (ConversationService.singleton.getConversationWith(userId: message.sender) == nil) {
                    try await ConversationService.singleton.loadConversationsAndRefreshVC()
                } else {
                    //if we do have a converation open, this code is handled in Conversation
                }
            }
        } catch {
            print("failed to load data after notification:", error.localizedDescription)
        }
    }
    
    func handleNotificationOpenFromLockScreen(userInfo: [String: AnyObject]) {
        //TODO: how do you set the initialVC from a notification given that we're supposed to do this within SceneDelegate, not AppDelegate ,now?
//        let tabVC = UIApplication.shared.windows.first!.rootViewController as! SpecialTabBarController
//        guard let notificaitonType = userInfo[Notification.extra.type.rawValue] as? String else { return }

//            let json = userInfo[Notification.extra.data.rawValue]
//            let data = try JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)
//        if notificaitonType == NotificationTypes.tag.rawValue {
//                let tag = try JSONDecoder().decode(Tag.self, from: data)
            
            //TODO: refactor caching and post loading so that we could immediately pull up a postVC with a skeleton view while the post loads in
            
//                let taggedPost = PostViewController.createPostVC(with: tag., shouldStartWithRaisedKeyboard: <#T##Bool#>, completionHandler: T##PostCompletionHandler?##PostCompletionHandler?##() -> Void)
//                tabVC.present(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: <#T##Bool#>)
            
//        } else if notificaitonType == NotificationTypes.message.rawValue {
//            tabVC.selectedIndex = 2
//        }
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
