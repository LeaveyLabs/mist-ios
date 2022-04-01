//
//  Constants.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import Foundation
import UIKit
import MapKit

struct Constants {
    static let DefaultFont: String = "Avenir-Medium";
    static let DefaultFontSize: CGFloat = 20
    
    static let USC_LAT_LONG =  CLLocationCoordinate2D(latitude: 34.0184, longitude: -118.2861)

    // MARK: -Storyboard Identifiers (SBID)
    //note: all nib names should be the same ss their storyboard ID
    struct SBID {
        struct SB {
            static let Main = "Main"
            static let Launch = "Launch"
            static let Auth = "Auth"
        }
        struct Cell {
            static let Post = "PostCell"
            static let Comment = "CommentCell"
            static let WordResult = "WordResultCell"
            static let UserResult = "UserResultCell"
            static let Query = "QueryCell"
            static let Sort = "SortCell"
        }
        struct VC {
            //Post
            static let Post = "PostViewController"
            static let SortBy = "SortByViewController"
            static let More = "MoreViewController"
            //NewPost
            static let NewPost = "NewPostViewController"
            static let NewPostNavigation = "NewPostNavigationController"
            static let Rules = "RulesViewController"
            //Account
            static let Profile = "ProfileViewController"
            static let Feed = "FeedTableViewController"
            static let MyProfile = "MyProfileViewController"
            static let Settings = "SettingsViewController"
            //Explore
            static let Explore = "ExploreViewController"
            static let LiveResults = "LiveResultsTableViewController"
            static let ResultsFeed = "ResultsFeedViewController"
            static let PinMapModal = "PinMapModalViewController"
            static let MapModal = "MapModalViewController"
        }
    }
}
