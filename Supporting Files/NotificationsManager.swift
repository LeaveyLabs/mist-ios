//
//  NotificationsManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation

extension Notification.Name {
    static let newMistboxMist = Notification.Name("newMistboxMist")
    static let newDM = Notification.Name("newDM")
    static let newMentionedMist = Notification.Name("newDM")
}

extension Notification {
    enum Key: String {
        case key0
        case key1
    }
}

class NotificationsManager: NSObject {
    
    private let center  = UNUserNotificationCenter.current()
    static let shared = NotificationsManager()
    
    private override init() {
        super.init()
    }
    
    //MARK: - Posting
    
    func post() {
        NotificationCenter.default.post(name: .newDM,
                                        object: nil,
                                        userInfo:[Notification.Key.key0: "value", "key1": 1234])
    }
    
    //MARK: - Permission and Status
    
    func getNotificationStatus(closure: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { setting in
            closure(setting.authorizationStatus)
        }
    }
    
    func registerForNotificationsOnStartupIfAccessExists() {
        center.getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    print("REGISTERED")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }
    
    func askForNewNotificationPermissionsIfNecessary(permission: PermissionType, onVC vc: UIViewController, closure: @escaping (Bool) -> Void = { _ in } ) {
        center.getNotificationSettings(completionHandler: { [self] (settings) in
            switch settings.authorizationStatus {
            case .denied, .notDetermined:
                CustomSwiftMessages.showPermissionRequest(permissionType: permission) { approved in
                    guard approved else {
                        closure(false)
                        return
                    }
                    guard settings.authorizationStatus != .denied else {
                        CustomSwiftMessages.showSettingsAlertController(title: "enable notifications in settings", message: "", on: vc)
                        closure(false)
                        return
                    }
                    self.center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                        guard granted else {
                            closure(false)
                            return
                        }
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        closure(true)
                    }
                }
            default:
                closure(false)
            }
        })
    }
        
}

extension NotificationsManager: UNUserNotificationCenterDelegate {
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
//        <#code#>
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
//        <#code#>
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
//        <#code#>
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        <#code#>
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        <#code#>
//    }
}
