//
//  UserAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/9/22.
//

import XCTest
@testable import mist_ios

class UserAPITest: XCTestCase {

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

    // GET by id
    func testGetUserById() async throws  {
        let user = try await UserAPI.fetchUsersByUserId(userId: TestConstants.Auth.ID)
        XCTAssertTrue(user.id == TestConstants.Auth.ID)
    }
    // GET by first name
    func testGetUsersByFirstName() async throws {
        let users = try await UserAPI.fetchUsersByFirstName(firstName: TestConstants.Auth.FIRST_NAME)
        XCTAssertTrue(users[0].first_name == TestConstants.Auth.FIRST_NAME)
    }
    // GET by last name
    func testGetUsersByLastName() async throws {
        let users = try await UserAPI.fetchUsersByLastName(lastName: TestConstants.Auth.LAST_NAME)
        XCTAssertTrue(users[0].last_name == TestConstants.Auth.LAST_NAME)
    }
    // GET by username
    func testGetUsersByUsername() async throws {
        let users = try await UserAPI.fetchUsersByUsername(username: TestConstants.Auth.USERNAME)
        XCTAssertTrue(users[0].username == TestConstants.Auth.USERNAME)
    }
    // GET by text
    func testGetUsersByText() async throws {
        let users = try await UserAPI.fetchUsersByText(containing: TestConstants.Auth.USERNAME)
        XCTAssertTrue(users[0].username == TestConstants.Auth.USERNAME)
    }
    // GET by token
    func testGeAuthedUserByToken() async throws {
        let user =  try await UserAPI.fetchAuthedUserByToken(token: TestConstants.Auth.TOKEN)
        XCTAssertTrue(user.id == TestConstants.Auth.ID)
    }
    // PATCH username
    func testPatchUserUsername() async throws {
        let user = try await UserAPI.patchUsername(username: TestConstants.Auth.USERNAME, user: TestConstants.Auth.authedUser)
        XCTAssertTrue(user.username == TestConstants.Auth.USERNAME)
    }
    // PATCH password
    func testPatchUserPassword() async throws {
        let user = try await UserAPI.patchPassword(password: TestConstants.Auth.PASSWORD, user: TestConstants.Auth.authedUser)
        XCTAssertTrue(user.username == TestConstants.Auth.USERNAME)
    }
    // PATCH picture
    func testPatchUserPicture() async throws {
        let picture = try await UserAPI.UIImageFromURLString(url: "https://cdn.cocoacasts.com/cc00ceb0c6bff0d536f25454d50223875d5c79f1/above-the-clouds.jpg")
        let user = try await UserAPI.patchProfilePic(image: picture, user: TestConstants.Auth.authedUser)
        XCTAssertTrue(user.id == TestConstants.Auth.ID)
    }
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
