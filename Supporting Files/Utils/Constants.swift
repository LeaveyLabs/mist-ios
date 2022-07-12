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
    
    static let maxPasswordLength = 1000
    
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
            static let SearchResult = "SearchResultCell"
            static let UserResult = "UserResultCell"
            static let FeedHeader = "FeedHeaderCell"
            static let Sort = "SortCell"
            static let Conversation = "ConversationCell"
            static let NoConversations = "NoConversationsCell"
            static let MyProfile = "MyProfileCell"
            static let SimpleInput = "SimpleInputCell"
        }
        struct VC {
            //Post
            static let Post = "PostViewController"
            static let SortBy = "SortByViewController"
            static let PostMore = "PostMoreViewController"
            //NewPost
            static let NewPost = "NewPostViewController"
            static let Rules = "RulesViewController"
            //Account
            static let Profile = "ProfileViewController"
            static let Feed = "FeedTableViewController"
            static let MyProfile = "MyProfileViewController"
            //Settings
            static let Settings = "SettingsViewController"
            static let PasswordSetting = "PasswordSettingViewController"
            //Explore
            static let Explore = "ExploreViewController"
            static let SearchSuggestions = "SearchSuggestionsTableViewController"
            static let ResultsFeed = "SearchResultsTableViewController"
            static let PinMapModal = "PinMapModalViewController"
            static let Filter = "FilterSheetViewController"
            static let NewFilter = "NewFilterSheetViewController"
            static let MapSearch = "MapSearchViewController"
            static let CustomExplore = "CustomExploreViewController"
            static let Home = "HomeViewController"
            //Messages
            static let Chat = "ChatViewController"
            static let ChatMore = "ChatMoreViewController"
            //Navigation Controllers
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
            static let EnterBios = "EnterBiosViewController"
            static let FinishProfile = "FinishProfileViewController"
            //Reset password
            static let RequestResetPassword = "RequestResetPasswordViewController"
            static let ValidateResetPassword = "ValidateResetPasswordViewController"
            static let FinalizeResetPassword = "FinalizeResetPasswordViewController"
        }
        struct Segue {
            static let ToMyProfileSetting = "ToMyProfileSetting"
            static let ToNameSetting = "ToNameSetting"
            static let ToPasswordSetting = "ToPasswordSetting"
            static let ToNotificationsSetting = "ToNotificationsSetting"
            static let ToListView = "ToListView"
            static let ToExplain = "ToExplain"
        }
    }
}
