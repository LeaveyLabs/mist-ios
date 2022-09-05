//
//  PostAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/9/22.
//

import XCTest
@testable import mist_ios

class PostAPITest: XCTestCase {

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
    func testPostPost() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        XCTAssertTrue(post.title == "hey")
    }
    
    // GET by ID
    func testGetPostByPostID() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let fetchedPost = try await PostAPI.fetchPostByPostID(postId: post.id)
        XCTAssertTrue(fetchedPost.title == "hey")
    }
    
    // GET by latitude and longitude
    func testGetPostByLatitudeLongitude() async throws {
        let _ = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let posts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: 1.0, longitude: 2.0)
        XCTAssertTrue(posts[0].title == "hey")
    }
    // GET by text
    func testGetPostByWord() async throws {
        let _ = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let posts = try await PostAPI.fetchPostsByWords(words: ["hey"])
        XCTAssertTrue(posts[0].title == "hey")
    }
    // GET by author
    func testGetPostByAuthor() async throws {
        let _ = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let posts = try await PostAPI.fetchPostsByAuthor(userId: TestConstants.Auth.ID)
        XCTAssertTrue(posts[0].title == "hey")
    }
    
    func testFetchMistbox() async throws {
        let _ = try await PostAPI.fetchMistbox()
    }
    
    func testPatchKeywords() async throws {
        let _ = try await PostAPI.patchKeywords(keywords: ["hi", "hi"])
    }
    
    
    // DELETE
    func testDeletePost() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        try await PostAPI.deletePost(post_id: post.id)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
