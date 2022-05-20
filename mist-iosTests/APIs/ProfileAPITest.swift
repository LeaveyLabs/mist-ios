//
//  UserAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 5/2/22.
//

import XCTest
@testable import mist_ios

class UserAPITest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
    }
    
    func testProfilePicUploadCompletes() throws {
        let expectation = XCTestExpectation()
        let url = URL(string: "https://cdn.cocoacasts.com/cc00ceb0c6bff0d536f25454d50223875d5c79f1/above-the-clouds.jpg")!
        if let imgData = try? Data(contentsOf: url) {
            let image = UIImage(data: imgData)
            Task {
                let testProfiles = try? await UserAPI.fetchProfilesByText(text: "kevinsun")
                let testProfile = testProfiles?[0]
                if let testProfile = testProfile {
                    if let image = image {
                        let _ = try? await UserAPI.putProfilePic(image: image, profile:testProfile)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 30)
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
