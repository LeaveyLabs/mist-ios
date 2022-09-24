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
        static let Roman: String = "Avenir-Roman"
        static let Medium: String = "Avenir-Medium"
        static let Heavy: String = "Avenir-Heavy"
        static let Book: String = "Avenir-Book"
        static let Black: String = "Avenir-Black"
        static let Size: CGFloat = 20
    }
    
    struct Color {
        static let mistPink = UIColor.init(named: "mist-pink")!
        static let mistLilac = UIColor.init(named: "mist-lilac")!
        static let mistLilacPurple = UIColor.init(named: "mist-lilac-purple")!
        static let mistPurple = UIColor.init(named: "mist-purple")!
        static let mistNight = UIColor.init(named: "mist-night")!
        static let mistBlack = UIColor.init(named: "mist-black")!
        static let offWhite = UIColor.init(named: "off-white")!
    }
    
    static let downloadLink = NSURL(string: "https://www.getmist.app/download")!
    
    static let defaultProfilePic = ReadOnlyUser.RandomSilhouette()
        
    static let maxPasswordLength = 1000
    
    static let searchPlaceholder = "search a place or address"
    
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
            static let MyProfile = "ProfileCell"
            static let SimpleInput = "SimpleInputCell"
            static let CommentHeaderCell = "CommentHeaderCell"
            static let BadgesCell = "BadgesCell"
            static let BadgeCell = "BadgeCell"
            static let ToggleSettingsCell = "ToggleSettingsCell"
        }
        struct VC {
            //Post
            static let Post = "PostViewController"
            static let SortBy = "SortByViewController"
            static let PostMore = "PostMoreViewController"
            static let CommentMore = "CommentMoreViewController"
            //NewPost
            static let NewPost = "NewPostViewController"
            static let Guidelines = "GuidelinesViewController"
            static let PinParent = "PinParentViewController"
            static let PinMap = "PinMapViewController"
            static let PinSearch = "PinSearchViewController"
            //Account
            static let Profile = "ProfileViewController"
            static let PhotoDetail = "PhotoDetailViewController"
            static let Feed = "FeedTableViewController"
            static let MyProfile = "MyProfileViewController"
            //Settings
            static let Settings = "SettingsViewController"
            static let PasswordSetting = "PasswordSettingViewController"
            static let UpdateProfile = "UpdateProfileSettingViewController"
            static let DefaultSettings = "DefaultsSettingsViewController"
            //Explore
            static let CustomExploreParent = "CustomExploreParentViewController"
            static let HomeExploreParent = "HomeExploreParentViewController"
            static let ExploreMap = "ExploreMapViewController"
            static let ExploreFeed = "ExploreFeedViewController"
            static let SearchSuggestions = "SearchSuggestionsTableViewController"
            static let MapFilter = "MapFilterSheetViewController"
            static let FeedFilter = "FeedFilterSheetViewController"
            //Messages
            static let Chat = "ChatViewController"
            static let ChatMore = "ChatMoreViewController"
            //Navigation Controllers
            static let NewPostNavigation = "NewPostNavigationController"
            static let MyAccountNavigation = "MyAccountNavigationController"
            static let AuthNavigation = "AuthNavigationController"
            //TabBar
            static let TabBarController = "TabBarController"
            //Mistbox
            static let Mistbox = "MistboxEmailViewController"
            static let EnterKeywords = "EnterKeywordsViewController"
            static let WhatIsMistbox = "WhatIsMistboxViewController"
            //Mistbox
            static let Prompts = "PromptsViewController"
            static let Collectibles = "CollectiblesViewController"
            static let WhatIsPrompts = "WhatIsPromptsViewController"
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
            static let EnterNumber = "EnterNumberViewController"
            static let ConfirmNumber = "ConfirmNumberViewController"
            static let CreateProfile = "CreateProfileViewController"
            static let ConfirmCode = "ConfirmCodeViewController"
            static let RequestReset = "RequestResetNumberViewController"
            static let ResetNumber = "ResetNumberViewController"
            static let ExplainProfile = "ExplainProfileViewController"
            static let EnterEmail = "EnterEmailViewController"
            //Reset password
//            static let RequestResetPassword = "RequestResetPasswordViewController"
//            static let ValidateResetPassword = "ValidateResetPasswordViewController"
//            static let FinalizeResetPassword = "FinalizeResetPasswordViewController"
        }
        struct Segue {
            static let ToNotificationsSetting = "ToNotificationsSetting"
            static let ToListView = "ToListView"
            static let ToExplain = "ToExplain"
        }
    }
}
