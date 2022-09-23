//
//  NotificationResponseHandler.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/15/22.
//

import Foundation
import FirebaseAnalytics

struct NotificationResponseHandler {
    var notificationType: NotificationTypes
    var newTag: Tag?
    var newTaggedPost: Post?
    var newMessage: Message?
    var newMessageConversation: Conversation?
    var newMatchRequest: MatchRequest?
}

func generateNotificationResponseHandler(_ notificationResponse: UNNotificationResponse) -> NotificationResponseHandler? {
    guard
        let userInfo = notificationResponse.notification.request.content.userInfo as? [String : AnyObject],
        let notificationTypeString = userInfo[Notification.extra.type.rawValue] as? String,
        let notificationType = NotificationTypes.init(rawValue: notificationTypeString),
        let json = userInfo[Notification.extra.data.rawValue]
    else { return nil }
    
    do {
        let data = try JSONSerialization.data(withJSONObject: json as Any, options: .prettyPrinted)
        var handler = NotificationResponseHandler(notificationType: notificationType)
        switch notificationType {
        case .tag:
            handler.newTag = try JSONDecoder().decode(Tag.self, from: data)
        case .message:
            handler.newMessage = try JSONDecoder().decode(Message.self, from: data)
        case .match:
            handler.newMatchRequest = try JSONDecoder().decode(MatchRequest.self, from: data)
        case .daily_mistbox, .make_someones_day:
            break
        case .comment:
            break
        }
        return handler
    } catch {
        let analyticsId = "notiifcation"
        let analyticsTitle = "displayingVCafterRemoteNotificationFailed"
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
          AnalyticsParameterItemID: "id-\(analyticsId)",
          AnalyticsParameterItemName: analyticsTitle,
        ])
        return nil
    }
}
