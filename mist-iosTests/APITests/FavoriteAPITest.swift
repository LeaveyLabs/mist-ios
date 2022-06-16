//
//  FavoriteAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/11/22.
//

import XCTest
@testable import mist_ios

class FavoriteAPITest: XCTestCase {

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
            static let authedUser = AuthedUser(id: ID,
                                               username: USERNAME,
                                               first_name: FIRST_NAME,
                                               last_name: LAST_NAME,
                                               picture: nil,
                                               email: EMAIL,
                                               password: PASSWORD)
        }
    }
    
    func testPostFetchDeleteFavorite() async throws {
        let post = try await PostAPI.createPost(title: "fakeTitle", text: "fakeText", locationDescription: "fakeLocationDescription", latitude: 0, longitude: 0, timestamp: 0, author: TestConstants.Auth.ID)
        let postedFavorite = try await FavoriteAPI.postFavorite(userId: TestConstants.Auth.ID, postId: post.id)
        XCTAssertTrue(post.id == postedFavorite.post)
        let fetchedFavorite = try await FavoriteAPI.fetchFavoritesByUser(userId: TestConstants.Auth.ID)
        XCTAssertTrue(postedFavorite.id == fetchedFavorite.last!.id)
        try await FavoriteAPI.deleteFavorite(id: postedFavorite.id)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
