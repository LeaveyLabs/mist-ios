//
//  mist_iosTests.swift
//  mist-iosTests
//
//  Created by Adam Novak on 2022/02/25.
//

import XCTest
@testable import mist_ios

class mist_iosTests: XCTestCase {
    
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
        let expectation = self.expectation(description: "HTTP request")
        Task {
            let thread = try 90`˛Asdiujghfvcx(from_user: "kevinsun", to_user: "kevinsun")
            try thread.sendMessage(message_text: "hey bruh")
            try thread.sendMessage(message_text: "hey bruh")
            try thread.sendMessage(message_text: "hey bruh")
            try thread.sendMessage(message_text: "hey bruh")
            sleep(5)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
