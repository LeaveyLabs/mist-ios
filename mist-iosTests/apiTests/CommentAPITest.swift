//
//  CommentAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 3/12/22.
//

import Foundation
import XCTest
@testable import mist_ios

class CommentAPITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let expectation = self.expectation(description: "HTTP request")
        Task {
            let testPost:Post = Post(id: "random15",
                                 title: "randomtest",
                                 text: "randomtext",
                                 location: "not the right location",
                                 timestamp: 10000,
                                 author: "kevinsun")
            try await PostAPI.createPost(post: testPost)
            let testComment:Comment = Comment(id:"randomID",
                                              text: "randomText",
                                              timestamp: 10000,
                                              post: "random15",
                                              author: "kevinsun")
            try await CommentAPI.postComment(comment: testComment)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let expectation = self.expectation(description: "HTTP request")
        Task {
            try await PostAPI.deletePost(id: "random15")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testFetch() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let expectation = self.expectation(description: "HTTP request")
        Task {
            let comments = try await CommentAPI.fetchComments(postID: "EEE46C55-3")
            XCTAssert(comments[0].post == "EEE46C55-3")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
