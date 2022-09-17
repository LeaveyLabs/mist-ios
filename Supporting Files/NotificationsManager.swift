//
//  NotificationsManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation

enum NotificationTypes: String {
    case tag = "tag"
    case message = "message"
    case match = "match"
    case daily_mistbox = "dailymistbox"
    case make_someones_day = "makesomeonesday"
}

extension Notification.Name {
    static let newMistboxMist = Notification.Name("newMistboxMist")
    static let sdfv = Notification.Name("dailyOpensRefreshed")
    static let newDM = Notification.Name("newDM")
    static let newMentionedMist = Notification.Name("tag")
}

extension Notification {
    enum extra: String {
        case type = "type"
        case data = "data"
    }
}

class NotificationsManager: NSObject {
    
    private var center: UNUserNotificationCenter!
    static let shared = NotificationsManager()
    
    private override init() {
        super.init()
        center =  UNUserNotificationCenter.current()
    }
    
    //MARK: - Posting
    
    func post() {
//        NotificationCenter.default.post(name: .newDM,
//                                        object: nil,
//                                        userInfo:[Notification.Key.key1: "value", "key1": 1234])
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
                    print("REGISTERED FOR NOTIFICATIONS")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }
    
    //the closure returns a bool: wasThePermissionReqeust displayed?
    //returns false when they already were requested permissioned, or if they were already accepted
    func askForNewNotificationPermissionsIfNecessary(permission: PermissionType, onVC vc: UIViewController, closure: @escaping (_ wasShownPermissionRequest: Bool) -> Void = { _ in } ) {
        switch permission {
        case .userLocation, .newpostUserLocation, .contacts: //shouldn't be passed as arguments
            return
        case .mistboxNotifications:
            if DeviceService.shared.hasBeenOfferedNotificationsBeforeMistbox() {
                closure(false)
                return
            } else {
                DeviceService.shared.showedNotificationRequestBeforeMistbox()
            }
        case .dmNotificationsAfterNewPost:
            if DeviceService.shared.hasBeenOfferedNotificationsAfterPost() {
                closure(false)
                return
            } else {
                DeviceService.shared.showedNotificationRequestAfterPost()
            }
        case .dmNotificationsAfterDm:
            if DeviceService.shared.hasBeenOfferedNotificationsAfterDM() {
                closure(false)
                return
            } else {
                DeviceService.shared.showedNotificationRequestAfterDM()
            }
        }
        
        center.getNotificationSettings(completionHandler: { [self] (settings) in
            switch settings.authorizationStatus {
            case .denied, .notDetermined:
                CustomSwiftMessages.showPermissionRequest(permissionType: permission) { approved in
                    guard approved else {
                        closure(true)
                        return
                    }
                    guard settings.authorizationStatus != .denied else {
                        CustomSwiftMessages.showSettingsAlertController(title: "enable notifications in settings", message: "", on: vc)
                        return
                    }
                    self.center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
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
