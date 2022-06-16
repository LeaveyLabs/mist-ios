//
//  SortBy.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

struct PostFilter {
    var postType: PostType = .All
    var postTimeframe: Float = 1
    
    static func getFilterLabelText(for postFilter: PostFilter) -> NSAttributedString {
        var postTypeString, middleString, postTimeframeString: NSMutableAttributedString
        let heavyAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Heavy, size: 23)!]
        let normalAttributes = [NSAttributedString.Key.font: UIFont(name: Constants.Font.Medium, size: 23)!]
        
        // set postTypeString
        switch postFilter.postType {
        case .All:
            postTypeString = NSMutableAttributedString(string: PostType.All.displayName, attributes: heavyAttributes)
        case .Friends:
            postTypeString = NSMutableAttributedString(string: PostType.Friends.displayName, attributes: heavyAttributes)
        case .Featured:
            postTypeString = NSMutableAttributedString(string: PostType.Featured.displayName, attributes: heavyAttributes)
        case .Matches:
            postTypeString = NSMutableAttributedString(string: PostType.Matches.displayName, attributes: heavyAttributes)
        }
        
        // set middleString nad postTimeframeString
        if postFilter.postType == .All {
            middleString = NSMutableAttributedString(string: " mists from ", attributes: normalAttributes)
            postTimeframeString = NSMutableAttributedString(
                string: getDateFromSlider(indexFromZeroToOne: postFilter.postTimeframe,
                                          timescale: FilterTimescale.week,
                                          lowercase: true),
                attributes: heavyAttributes)
        } else {
            middleString = NSMutableAttributedString(string: " from ", attributes: normalAttributes)
            postTimeframeString = NSMutableAttributedString(
                string: getDateFromSlider(indexFromZeroToOne: postFilter.postTimeframe,
                                          timescale: FilterTimescale.month,
                                          lowercase: true),
                attributes: heavyAttributes)
        }
        
//        postTypeString.append(middleString)
//        postTypeString.append(postTimeframeString)
        
        return postTypeString
    }
}

enum PostType: String {
    case All, Featured, Matches, Friends
    
    var displayName : String {
      switch self {
      case .All: return "⭐️ All"
      case .Featured: return "Featured"
      case .Matches: return "💞 Matches"
      case .Friends: return "👀 Friends"
      }
    }
    // For better formatting on the sheet view controller
    var displayNameWithExtraSpace : String {
      switch self {
      case .All: return "⭐️  All"
      case .Featured: return "Featured"
      case .Matches: return "💞  Matches"
      case .Friends: return "👀  Friends"
      }
    }
}

