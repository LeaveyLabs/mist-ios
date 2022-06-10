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
    struct Font {
        static let Light: String = "Avenir-Light"
        static let Medium: String = "Avenir-Medium"
        static let Heavy: String = "Avenir-Heavy"
        static let Size: CGFloat = 20
    }
    
    struct Coordinates {
        static let USC = CLLocationCoordinate2D(latitude: 34.0209 + 0.0019, longitude: -118.2861)
    }
    
    // Note: all nib names should be the same ss their storyboard ID
    struct SBID {
        struct View {
            //Post
            static let Post = "PostView"
        }
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
            static let FeedHeader = "FeedHeaderCell"
            static let Sort = "SortCell"
            static let Conversation = "ConversationCell"
            static let NoConversations = "NoConversationsCell"
        }
        struct VC {
            //Post
            static let Post = "PostViewController"
            static let SortBy = "SortByViewController"
            static let More = "MoreViewController"
            //NewPost
            static let NewPost = "NewPostViewController"
            static let Rules = "RulesViewController"
            //Account
            static let Profile = "ProfileViewController"
            static let Feed = "FeedTableViewController"
            static let MyProfile = "MyProfileViewController"
            static let Settings = "SettingsViewController"
            //Explore
            static let Explore = "ExploreViewController"
            static let SearchSuggestions = "SearchSuggestionsTableViewController"
            static let ResultsFeed = "ResultsFeedViewController"
            static let PinMapModal = "PinMapModalViewController"
            static let MapModal = "MapModalViewController"
            static let Filter = "FilterViewController"
            static let MapSearch = "MapSearchViewController"
            //Messages
            static let NewMessage = "NewMessageViewController"
            //Navigation Controllers
            static let NewMessageNavigation = "NewMessageNavigationController"
            static let NewPostNavigation = "NewPostNavigationController"
            static let MyAccountNavigation = "MyAccountNavigationController"
            static let AuthNavigation = "AuthNavigationController"
            //TabBar
            static let TabBarController = "TabBarController"
            //Auth
            static let ConfirmEmail = "ConfirmEmailViewController"
            static let WelcomeTutorial = "WelcomeTutorialViewController"
            static let UploadProfilePicture = "UploadProfilePictureViewController"
            static let CreatePassword = "CreatePasswordViewController"
            static let EnterName = "EnterNameViewController"
            static let ChooseUsername = "ChooseUsernameViewController"
            static let SetupTime = "SetupTimeViewController"
        }
        struct Segue {
            static let ToUsernameSetting = "ToUsernameSetting"
            static let ToNameSetting = "ToNameSetting"
            static let ToPasswordSetting = "ToPasswordSetting"
            static let ToNotificationsSetting = "ToNotificationsSetting"
            static let ToListView = "ToListView"
            static let ToExplain = "ToExplain"
        }
    }
}
