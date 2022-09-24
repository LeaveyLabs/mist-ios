//
//  Device.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/3/22.
//

import Foundation

enum StartingScreen: String, CaseIterable, Codable {
    case map, feed
}

struct Device: Codable {
    var hasBeenShownGuidelines: Bool = false
    var hasBeenOfferedNotificationsAfterDM: Bool = false
    var hasBeenOfferedNotificationsAfterPost: Bool = false
    var hasBeenOfferedNotificationsBeforeMistbox: Bool = false
    var hasBeenRequestedARating: Bool = false
    var hasBeenRequestedLocationOnHome: Bool = false
    var hasBeenRequestedLocationOnNewPostPin: Bool = false
    var hasBeenRequestedContactsOnPost: Bool = false
    var hasBeenRequestedContactsBeforeTagging: Bool = false
    var lastMentionsOpenTime: Double = .leastNormalMagnitude
    
    var hasUserOpenedFeed: Bool = false
    
    var startingScreen: StartingScreen = .feed
    var sortOrder: SortOrder = .TRENDING
    
    enum CodingKeys: String, CodingKey {
        case hasBeenShownGuidelines
        case hasBeenOfferedNotificationsAfterDM
        case hasBeenOfferedNotificationsAfterPost
        case hasBeenOfferedNotificationsBeforeMistbox
        case hasBeenRequestedARating
        case lastMentionsOpenTime
        case hasBeenRequestedLocationOnHome
        case hasBeenRequestedLocationOnNewPostPin
        case hasBeenRequestedContactsBeforeTagging
        case hasBeenRequestedContactsOnPost
        
        case hasUserOpenedFeed

        case startingScreen
        case sortOrder
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hasBeenShownGuidelines = try values.decodeIfPresent(Bool.self, forKey: .hasBeenShownGuidelines) ?? false
        hasBeenOfferedNotificationsAfterDM = try values.decodeIfPresent(Bool.self, forKey: .hasBeenOfferedNotificationsAfterDM) ?? false
        hasBeenOfferedNotificationsAfterDM = try values.decodeIfPresent(Bool.self, forKey: .hasBeenOfferedNotificationsAfterPost) ?? false
        hasBeenOfferedNotificationsBeforeMistbox = try values.decodeIfPresent(Bool.self, forKey: .hasBeenOfferedNotificationsBeforeMistbox) ?? false
        hasBeenRequestedARating = try values.decodeIfPresent(Bool.self, forKey: .hasBeenRequestedARating) ?? false
        lastMentionsOpenTime = try values.decodeIfPresent(Double.self, forKey: .lastMentionsOpenTime) ?? .leastNormalMagnitude
        hasBeenRequestedLocationOnHome = try values.decodeIfPresent(Bool.self, forKey: .hasBeenRequestedLocationOnHome) ?? false
        hasBeenRequestedLocationOnNewPostPin = try values.decodeIfPresent(Bool.self, forKey: .hasBeenRequestedLocationOnNewPostPin) ?? false
        hasBeenRequestedContactsBeforeTagging = try values.decodeIfPresent(Bool.self, forKey: .hasBeenRequestedContactsBeforeTagging) ?? false
        hasBeenRequestedContactsOnPost = try values.decodeIfPresent(Bool.self, forKey: .hasBeenRequestedContactsOnPost) ?? false
        
        hasUserOpenedFeed = try values.decodeIfPresent(Bool.self, forKey: .hasUserOpenedFeed) ?? false
        
        startingScreen = try values.decodeIfPresent(StartingScreen.self, forKey: .startingScreen) ?? StartingScreen.feed
        sortOrder = try values.decodeIfPresent(SortOrder.self, forKey: .sortOrder) ?? SortOrder.TRENDING
    }
    
    init() {
        hasBeenShownGuidelines = false
        hasBeenOfferedNotificationsAfterDM = false
        hasBeenOfferedNotificationsAfterPost = false
        hasBeenRequestedARating = false
        hasBeenRequestedLocationOnHome = false
        hasBeenRequestedLocationOnNewPostPin = false
        hasBeenOfferedNotificationsBeforeMistbox = false
        hasBeenRequestedContactsBeforeTagging = false
        hasBeenRequestedContactsOnPost = false
        lastMentionsOpenTime = .leastNormalMagnitude
        startingScreen = .feed
        sortOrder = .TRENDING
        hasUserOpenedFeed = false
    }
    
}
