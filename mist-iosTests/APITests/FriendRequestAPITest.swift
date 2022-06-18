//
//  FriendRequestAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/11/22.
//

import XCTest
@testable import mist_ios

class FriendRequestAPITest: XCTestCase {

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

    func testPostFetchDeleteFriendRequest() async throws {
        let postedFriendRequest = try await FriendRequestAPI.postFriendRequest(senderUserId: TestConstants.Auth.ID, receiverUserId: TestConstants.Auth2.ID)
        XCTAssertTrue(TestConstants.Auth.ID == postedFriendRequest.friend_requesting_user)
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        let fetchedFriendRequest1 = try await FriendRequestAPI.fetchFriendRequestsBySender(senderUserId: TestConstants.Auth.ID)
        XCTAssertTrue(postedFriendRequest.id == fetchedFriendRequest1.last!.id)
        setGlobalAuthToken(token: TestConstants.Auth2.TOKEN)
        let fetchedFriendRequest2 = try await FriendRequestAPI.fetchFriendRequestsByReceiver(receiverUserId: TestConstants.Auth2.ID)
        XCTAssertTrue(postedFriendRequest.id == fetchedFriendRequest2.last!.id)
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
        try await FriendRequestAPI.deleteFriendRequest(id: postedFriendRequest.id)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
