//
//  TagLink.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/14/22.
//

import Foundation

enum TagType: String {
    case id, phone
}

struct TagLink {
    
    //URL format: id/adamvnovak11/@adamvnovak
    static let delimitter = "/"
    
    let tagType: TagType
    let tagValue: String
    let tagText: String
    
    static func encodeTagLink(_ tagLink: TagLink) -> String? {
        guard tagLink.tagText.rangeOfCharacter(from: .whitespacesAndNewlines) == nil, tagLink.tagValue.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            print("link contained whitespace, cannot format properly")
            return nil
        }
        
        return tagLink.tagType.rawValue + TagLink.delimitter + tagLink.tagValue + TagLink.delimitter + tagLink.tagText
    }
    
    static func decodeTag(linkString: String) -> TagLink? {
        let tokens = linkString.components(separatedBy: "/")
        guard tokens.count == 3 else { return nil }
        
        let tagType = tokens[0]
        let tagValue = tokens[1]
        let tagText = tokens[2]
        guard let tagType = TagType(rawValue: tagType) else { return nil}
        
        return TagLink(tagType: tagType, tagValue: tagValue, tagText: tagText)
    }
}
