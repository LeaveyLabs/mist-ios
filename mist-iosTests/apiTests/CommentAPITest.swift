//
//  CommentAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/9/22.
//

import XCTest
@testable import mist_ios

class CommentAPITest: XCTestCase {

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
    
    // POST
    func testPostComment() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        do {
            let comment = try await CommentAPI.postComment(text: "hey", post: post.id, author: TestConstants.Auth.ID)
            XCTAssertTrue(comment.body == "hey")
        } catch {
            print(error)
        }
    }
    // GET by postId
    func testGetCommentByPostId() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let comment = try await CommentAPI.postComment(text: "hey", post: post.id, author: TestConstants.Auth.ID)
        let comments = try await CommentAPI.fetchCommentsByPostID(post: post.id)
        XCTAssertTrue(comments[0].body == "hey")
    }
    // DELETE
    func testDeleteComment() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let comment = try await CommentAPI.postComment(text: "hey", post: post.id, author: TestConstants.Auth.ID)
        try await CommentAPI.deleteComment(commentId: comment.id)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
