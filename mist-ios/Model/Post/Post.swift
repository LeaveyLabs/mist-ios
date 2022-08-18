//
//  Post.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

let DUMMY_POST_ID: Int = -1

typealias EmojiCountTuple = (emoji: String, count: Int)

struct Post: Codable, Equatable {
    
    let id: Int
    let title: String
    let body: String
    let location_description: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: Double
    let author: Int
    let read_only_author: ReadOnlyUser
    let votes: [PostVote];
    
    //commentCount is not supported right now. we're trying to avoid ever updating the Post on the frontend, so it's easier just to not think about this right now
//    let commentcount: Int
    
    //votecount has been removed bc it's no longer needed
//    var votecount: Int
    
    let emojiCountTuples: [EmojiCountTuple] //right now, this is serving as the default three emojis that one can vote on a post with. this could be changed to become more useful later on, potentially eliminating the need for votes^
    //potential solution which would also us to not need to load in votes: an array of local votes in VoteService. (problem: if we were to not load in votes, if we've voted for a post, how do we know if the count for an emoji should be incremented or not?

    
    //MARK: - Initializers
    
    // Post has two initializers:
    // Default initializer is used when deserializing a post from the DB
    // Custom initializer (below) is used when a user first creates a post
    
    init(id: Int = DUMMY_POST_ID,
         title: String,
         body: String,
         location_description: String?,
         latitude: Double?,
         longitude: Double?,
         timestamp: Double,
         author: Int,
         votecount: Int = 0,
         commentcount: Int = 0) {
        self.id = id
        self.title = title
        self.body = body
        self.location_description = location_description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.author = author
        self.read_only_author = UserService.singleton.getUserAsReadOnlyUser()
//        self.commentcount = commentcount
//        self.votecount = votecount
        self.votes = []
        self.emojiCountTuples = []
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.body = try container.decode(String.self, forKey: .body)
        self.location_description = try container.decode(String.self, forKey: .location_description)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.timestamp = try container.decode(Double.self, forKey: .timestamp)
        self.author = try container.decode(Int.self, forKey: .author)
        self.read_only_author = try container.decode(ReadOnlyUser.self, forKey: .read_only_author)
//        self.commentcount = try container.decode(Int.self, forKey: .commentcount)
//        self.votecount = try container.decode(Int.self, forKey: .votecount)
        self.votes = try container.decode([PostVote].self, forKey: .votes)
        self.emojiCountTuples = Post.setupPostTuples(from: votes, title)
    }
    
    static private func setupPostTuples(from votes: [PostVote], _ title: String) -> [EmojiCountTuple] {
        //Tally up votes by their respective emojis
        var postVotesOrganizedByEmoji: [String: Int] = [:]
        for postVote in votes {
            if postVotesOrganizedByEmoji.keys.contains(postVote.emoji) {
                postVotesOrganizedByEmoji[postVote.emoji]! += 1
            } else {
                postVotesOrganizedByEmoji[postVote.emoji] = 1
            }
        }
        
        //Turn the dictionary into an array of tuples, sorted by count
        var emojiCountTuples = postVotesOrganizedByEmoji.map { (key: String, value: Int) in
            EmojiCountTuple(key, value)
        }.sorted { $0.count > $1.count }
        
        //Add placeholder emojis
        let missingEmojiCount = 3 - emojiCountTuples.count
        if missingEmojiCount > 0 {
            for _ in (0 ..< missingEmojiCount) {
                emojiCountTuples.append(EmojiCountTuple(randomUnusedEmoji(usedEmojis: emojiCountTuples), 0))
            }
        }
        
        return emojiCountTuples
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
        case id, title, body, location_description, latitude, longitude, timestamp, author, read_only_author, votes
    }
}
