//
//  ProfileAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 3/25/22.
//


import Foundation
import XCTest
@testable import mist_ios

class ProfileAPITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let expectation = self.expectation(description: "HTTP request")
        Task {
            
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let expectation = self.expectation(description: "HTTP request")
        Task {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testPostPicture() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let expectation = self.expectation(description: "HTTP request")
        Task {
            let testProfile = Profile(
                username: "kevinsun",
                first_name: "kevin",
                last_name: "sun",
                picture: nil)
            let testImage = UIImage(named: "apiTests/test.jpeg")!
            try await ProfileAPI.postProfilePic(image: testImage, profile: testProfile)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
