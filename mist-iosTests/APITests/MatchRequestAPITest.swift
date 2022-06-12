//
//  MatchRequestAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/11/22.
//

import XCTest
@testable import mist_ios

class MatchRequestAPITest: XCTestCase {

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
        struct Auth2 {
            static let TOKEN = "5b466dc2f53727127e7c63d32c98f00e5cfcb0f3"
            static let ID = 8
            static let EMAIL = "testingadmin2@invaliddomain.net"
            static let USERNAME = "testingadmin2"
            static let PASSWORD = "randomstringofcharacters1234"
            static let FIRST_NAME = "testing"
            static let LAST_NAME = "admin2"
            static let authedUser = AuthedUser(id: ID,
                                               username: USERNAME,
                                               first_name: FIRST_NAME,
                                               last_name: LAST_NAME,
                                               picture: nil,
                                               email: EMAIL,
                                               password: PASSWORD)
        }
    }

    func testPostFetchDeleteFriendRequest() async throws {
        let post = try await PostAPI.createPost(title: "fakeTitle", text: "fakeText", locationDescription: "fakeLocDescription", latitude: 0, longitude: 0, timestamp: 0, author: TestConstants.Auth.ID)
        let postedMatchRequest = try await MatchRequestAPI.postMatchRequest(senderUserId: TestConstants.Auth.ID, receiverUserId: TestConstants.Auth2.ID, postId: post.id)
        XCTAssertTrue(TestConstants.Auth.ID == postedMatchRequest.match_requesting_user)
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        let fetchedMatchRequest1 = try await MatchRequestAPI.fetchMatchRequestsBySender(senderUserId: TestConstants.Auth.ID)
        XCTAssertTrue(postedMatchRequest.id == fetchedMatchRequest1.last!.id)
        setGlobalAuthToken(token: TestConstants.Auth2.TOKEN)
        let fetchedMatchRequest2 = try await MatchRequestAPI.fetchMatchRequestsByReceiver(receiverUserId: TestConstants.Auth2.ID)
        XCTAssertTrue(postedMatchRequest.id == fetchedMatchRequest2.last!.id)
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        try await MatchRequestAPI.deleteMatchRequest(id: postedMatchRequest.id)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
