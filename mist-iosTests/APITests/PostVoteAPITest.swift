//
//  PostVoteAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 8/2/22.
//

import XCTest
@testable import mist_ios

class PostVoteAPITest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        setGlobalAuthToken(token: "")
    }

    // AUTH CONSTANTS
    struct TestConstants {
        struct Auth {
            static let TOKEN = "13929afc3930c2a332ee7e53af3d2dc62f904fc7"
            static let ID = 1
            static let EMAIL = "testingadmin@invaliddomain.com"
            static let USERNAME = "testingadmin"
            static let PASSWORD = "randomstringofcharacters1234"
            static let FIRST_NAME = "testing"
            static let LAST_NAME = "admin"
        }
    }
    
    // PATCH
    func testPatchPostVoteEmoji() async throws {
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        let post = try await PostAPI.createPost(title: "this is a test", text: "this is a test", locationDescription: "hello", latitude: 0, longitude: 0, timestamp: 0.0, author: TestConstants.Auth.ID)
        do {
            try await PostVoteAPI.deleteVote(voter: TestConstants.Auth.ID, post: post.id)
        } catch {}
        let postVote = try await PostVoteAPI.postVote(voter: TestConstants.Auth.ID, post: post.id)
        try await PostVoteAPI.patchVote(voter: postVote.voter, post: postVote.post, emoji: "😭")
        let fetchedVote = try await PostVoteAPI.fetchVotesByVoterAndPost(voter: postVote.voter, post: postVote.post)

        print(fetchedVote.first?.emoji)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
