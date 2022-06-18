//
//  MessageThreadTest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/17/22.
//

import XCTest
@testable import mist_ios

class MessageThreadTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
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
    
    func testConversation() async throws {
        let thread1 = try MessageThread(sender: TestConstants.Auth.ID, receiver: TestConstants.Auth2.ID)
        let thread2 = try MessageThread(sender: TestConstants.Auth2.ID, receiver: TestConstants.Auth.ID)
        let message_texts = ["Message 1", "Message 2", "Message 3", "Message 4", "Message 5", "Message 6"]
        do {
            setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
            for message_text in message_texts {
                try thread1.sendMessage(message_text: message_text)
            }
            sleep(4)
            for (message_text, server_message) in zip(message_texts, thread2.server_messages) {
                XCTAssert(message_text == server_message.body)
            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
