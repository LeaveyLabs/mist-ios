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
}
