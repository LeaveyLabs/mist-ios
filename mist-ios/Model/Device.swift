//
//  Device.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/3/22.
//

import Foundation

struct Device: Codable {
    var hasBeenShownGuidelines: Bool = false
    var hasBeenOfferedNotificationsAfterDM: Bool = false
    var hasBeenOfferedNotificationsAfterPost: Bool = false
    var hasBeenRequestedARating: Bool = false
    var lastMentionsOpenTime: Double = .leastNormalMagnitude
    
    enum CodingKeys: String, CodingKey {
        case hasBeenShownGuidelines
        case hasBeenOfferedNotificationsAfterDM
        case hasBeenOfferedNotificationsAfterPost
        case hasBeenRequestedARating
        case lastMentionsOpenTime
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hasBeenShownGuidelines = try values.decodeIfPresent(Bool.self, forKey: .hasBeenShownGuidelines) ?? false
        hasBeenOfferedNotificationsAfterDM = try values.decodeIfPresent(Bool.self, forKey: .hasBeenOfferedNotificationsAfterDM) ?? false
        hasBeenOfferedNotificationsAfterDM = try values.decodeIfPresent(Bool.self, forKey: .hasBeenOfferedNotificationsAfterPost) ?? false
        hasBeenRequestedARating = try values.decodeIfPresent(Bool.self, forKey: .hasBeenRequestedARating) ?? false
        lastMentionsOpenTime = try values.decodeIfPresent(Double.self, forKey: .lastMentionsOpenTime) ?? .leastNormalMagnitude
    }
    
    init() {
        hasBeenShownGuidelines = false
        hasBeenOfferedNotificationsAfterDM = false
        hasBeenOfferedNotificationsAfterPost = false
        hasBeenRequestedARating = false
        lastMentionsOpenTime = .leastNormalMagnitude
    }
    
}
