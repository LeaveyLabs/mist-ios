//
//  Constants.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/12.
//

import Foundation
import UIKit

struct Constants {
    static let DefaultFont: String = "Avenir-Medium";
    static let DefaultFontSize: CGFloat = 20
    
    
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
            static let PostResult = "PostResult"
            static let UserResult = "UserResult"
            static let Query = "QueryCell"
            static let Sort = "SortCell"
        }
        struct VC {
            static let SortBy = "SortByViewController"
            static let More = "MoreViewController"
            static let Rules = "RulesViewController"
            static let NewPost = "NewPostViewController"
            static let NewPostNavigation = "NewPostNavigationController"
            static let Profile = "ProfileViewController"
            static let Feed = "FeedTableViewController"
            static let Post = "PostViewController"
            static let Explore = "ExploreViewController"
            static let LiveResults = "LiveResultsTableViewController"
            static let ResultsFeed = "ResultsFeedViewController"
        }
    }
}
