//
//  AuthAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/9/22.
//

import XCTest
@testable import mist_ios

class AuthAPITest: XCTestCase {
    
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

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        setGlobalAuthToken(token: "")
    }

    func testFetchAuthToken() async throws {
        let token = try await AuthAPI.fetchAuthToken(username: TestConstants.Auth.USERNAME, password: TestConstants.Auth.PASSWORD)
        XCTAssert(token == TestConstants.Auth.TOKEN)
    }
    
    func testRegisterEmail() async throws {
        do {
            try await AuthAPI.registerEmail(email: "kevinsun@usc.edu")
        } catch {
            XCTFail("Could not register email.")
        }
    }
    
    func testValidateEmail() async throws {
        do {
            try await AuthAPI.validateEmail(email: "kevinsun@usc.edu", code: "123456")
            XCTFail("Invalid validation was successful")
        } catch {}
    }
    
    func testCreateUser() async throws {
        do {
            let _ = try await AuthAPI.createUser(username: "kevinsun", first_name: "Kevin", last_name: "Sun", picture: UIImage(), email: "kevinsun@usc.edu", password: "fakePass1234")
            XCTFail("Invalid create user request was successful")
        } catch {}
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
