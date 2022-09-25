//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

let DUMMY_POST_ID: Int = -1
typealias Emoji = String
typealias EmojiCountDict = [Emoji:Int]
typealias EmojiCountTuple = (emoji: Emoji, count: Int)

struct Post: Codable, Equatable {
    
    let id: Int
    let title: String
    let body: String
    let location_description: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: Double
    let creation_time: Double
    let author: Int
    var emoji_dict: EmojiCountDict
    let commentcount: Int
    let collectible_type: Int?
    let is_matched: Bool
    
    //MARK: - Initializers
    
    // Post has two initializers:
    // Default initializer is used when deserializing a post from the DB
    // Custom initializer (below) is used when a user first creates a post
    
    init(id: Int = DUMMY_POST_ID,
         title: String,
         body: String,
         location_description: String,
         latitude: Double,
         longitude: Double,
         timestamp: Double,
         author: Int,
         emojiDict: EmojiCountDict = [:],
         votes: [PostVote] = [],
         commentcount: Int = 0,
         collectible_type: Int? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.location_description = location_description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.author = author
        self.commentcount = commentcount
        self.creation_time = Date().timeIntervalSince1970
        self.emoji_dict = emojiDict
        self.collectible_type = collectible_type
        self.is_matched = false
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    //We use a custom decoder so that we can insert default emojis into the emoji_dict in case the post has fewer than 3 different emoji votes
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.body = try container.decode(String.self, forKey: .body)
        self.location_description = try container.decode(String.self, forKey: .location_description)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.timestamp = try container.decode(Double.self, forKey: .timestamp)
        self.creation_time = try container.decode(Double.self, forKey: .creation_time)
        self.author = try container.decode(Int.self, forKey: .author)
        self.commentcount = try container.decode(Int.self, forKey: .commentcount)
        let decodedEmojiCountDict = try container.decode(EmojiCountDict.self, forKey: .emoji_dict)
        self.emoji_dict = Post.insertUpToThreePlaceholderEmojis(on: decodedEmojiCountDict)
        self.collectible_type = try container.decodeIfPresent(Int.self, forKey: .collectible_type)
        self.is_matched = try container.decode(Bool.self, forKey: .is_matched)
    }
    
    static private func insertUpToThreePlaceholderEmojis(on emojiDict: EmojiCountDict) -> EmojiCountDict {
        let missingEmojiCount = 3 - emojiDict.values.count
        guard missingEmojiCount > 0 else { return emojiDict }
        var emojiDictWithPlaceholders = emojiDict
        for _ in (0 ..< missingEmojiCount) {
            emojiDictWithPlaceholders[randomUnusedEmoji(usedEmojis: emojiDictWithPlaceholders.map { ($0, $1) })] = 0
        }
        return emojiDictWithPlaceholders
    }
    
    static private func randomUnusedEmoji(usedEmojis: [EmojiCountTuple]) -> String {
        while true {
            let randomEmoji = ["🥹", "🥳", "😂", "🥰", "😍", "🧐", "😭", "❤️", "😰", "👀", "🫶", "👏", "💘", "😮", "🙄", "😇", "😳", "🫢", "😶", "🤠", "😦", "🍿", "🔥", "🙂", "🤣"].randomElement()!
            let isEmojiUsed = usedEmojis.contains { $0.emoji == randomEmoji }
            if !isEmojiUsed {
                return randomEmoji
            }
        }
    }
    
    enum CodingKeys: CodingKey {
        case id, title, body, location_description, latitude, longitude, timestamp, creation_time, author, emoji_dict, commentcount, collectible_type, is_matched
    }
}
