//
//  TagAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 8/4/22.
//

import XCTest
@testable import mist_ios

class TagAPITest: XCTestCase {

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
        struct Auth2 {
            static let TOKEN = "5b466dc2f53727127e7c63d32c98f00e5cfcb0f3"
            static let ID = 8
            static let EMAIL = "testingadmin2@invaliddomain.net"
            static let USERNAME = "testingadmin2"
            static let PASSWORD = "randomstringofcharacters1234"
            static let FIRST_NAME = "testing"
            static let LAST_NAME = "admin2"
        }
    }
    
    // GET
    func testFetchTags() async throws {
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        let tags = try await TagAPI.fetchTags()
        print(tags)
    }
    
    // POST
    func testPostTag() async throws {
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let comment = try await CommentAPI.postComment(body: "hey", post: post.id, author: TestConstants.Auth.ID)
        let tag = try await TagAPI.postTag(comment: comment.id,
                                           tagged_name: TestConstants.Auth2.USERNAME,
                                           tagging_user: TestConstants.Auth.ID,
                                           tagged_user: TestConstants.Auth2.ID)
        try await PostAPI.deletePost(post_id: post.id)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
