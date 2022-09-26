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
        Task {
            try await DeviceAPI.registerCurrentDeviceWithUser(user: UserService.singleton.getId())
        }
    }
    
    //user was not in app
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        guard var _ = UIApplication.shared.windows.first?.rootViewController else {
            return //the app wasn't running in the background. scene delegate will handle
        }
                
        let loadingVC = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
        if let notificationResponseHandler = generateNotificationResponseHandler(response) {
            loadingVC.notificationResponseHandler = notificationResponseHandler
        }
        UIApplication.shared.windows.first?.rootViewController = loadingVC

        completionHandler()
    }
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        <#code#>
//    }

    //user was in app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("WILL PRESENT NOTIFIATION")
        guard let userInfo = notification.request.content.userInfo as? [String : AnyObject] else { return }
        Task {
            await handleNotificationWhileInApp(userInfo: userInfo)
        }
                
//        completionHandler([.alert, .sound, .badge]) //when the user is in the app, we don't want to do an ios system displays
    }
    
    func handleNotificationWhileInApp(userInfo: [String: AnyObject]) async {
        //both of these methods work here. we'll just use the first
//        guard let _ = UIApplication.shared.windows.first?.rootViewController as? SpecialTabBarController else { return }
//        guard let rootViewController = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController as? SpecialTabBarController else { return }
        
        guard
            let notificaitonTypeString = userInfo[Notification.extra.type.rawValue] as? String,
            let notificationType = NotificationTypes(rawValue: notificaitonTypeString)
        else { return }
        
        do {
            //Note: we actually only want to deserialize the data if the notification has data. the below code should be moved out of match
//            let json = userInfo[Notification.extra.data.rawValue]
//            _ = try JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)
            switch notificationType {
            case .tag:
                break //handled in PostService background task
            case .message:
                 break //do nothing: this case should be handled within the socket
//                let message = try JSONDecoder().decode(Message.self, from: data)
//                if (ConversationService.singleton.getConversationWith(userId: message.sender) == nil) {
//                    try await ConversationService.singleton.loadConversationsAndRefreshVC()
//                } else {
//                    //if we do have a converation open, this code is handled in Conversation
//                }
            case .match:
                break //do nothing, this is handled within ConversationService every 15 seconds
//                let matchRequest = try JSONDecoder().decode(MatchRequest.self, from: data)
//                if (ConversationService.singleton.getConversationWith(userId: matchRequest.match_requesting_user) == nil) {
//                    try await ConversationService.singleton.load
//                } else {
//                    //if we do have a converation open, this code is handled in Conversation
//                }
            case .prompts, .comment:
                break
            }
        } catch {
            print("failed to load data after notification:", error.localizedDescription)
        }
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
