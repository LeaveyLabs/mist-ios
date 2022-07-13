//
//  mist_iosUITests.swift
//  mist-iosUITests
//
//  Created by Adam Novak on 2022/02/25.
//

import XCTest

class mist_iosUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScreenshots() throws {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let tabBar = app.tabBars["Tab Bar"]
        let chatButton = tabBar.buttons["Chat"]
        let backButton = app.buttons["Back"]
        let stopButton = app.navigationBars["mist_ios.NewPostView"].buttons["Stop"]
        let exploreButton = tabBar.buttons["Explore"]
        let dropPinButton = app.scrollViews.otherElements.buttons["Drop a pin"]
        let escapePostButton = app.navigationBars["mist_ios.PostView"].buttons["Back"]
        let feedButton = app.buttons["toggle list button"]
        let submitbuttonButton = tabBar.buttons["submitbutton"]
        
        // Start Screen
        setupSnapshot(app)
        app.launch()
        snapshot("01StartScreen")
        
        sleep(20)
        
        // Explore Post Screen
        app.otherElements["Cava cutie"].tap()
        sleep(5)
        snapshot("02PostScreen")
        
        // Chat Screen
        chatButton.tap()
        sleep(5)
        snapshot("03ChatScreen")
        
        // Requested Match Screen
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Adam"]/*[[".cells.staticTexts[\"Adam\"]",".staticTexts[\"Adam\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(5)
        snapshot("04MatchRequestScreen")
        
        // Accepted Match Screen
        backButton.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Bob"]/*[[".cells.staticTexts[\"Bob\"]",".staticTexts[\"Bob\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(5)
        snapshot("05AcceptedScreen")
        
        // Pending Match Screen
        backButton.tap()
        app.tables/*@START_MENU_TOKEN@*/.cells.containing(.staticText, identifier:"You’ve caught me haha… you’re in luck, I’ve got enough for the two of us!").element/*[[".cells.containing(.staticText, identifier:\"???\").element",".cells.containing(.staticText, identifier:\"You’ve caught me haha… you’re in luck, I’ve got enough for the two of us!\").element"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(5)
        snapshot("06PendingScreen")
        
        // Comment Screen
        app.collectionViews/*@START_MENU_TOKEN@*/.staticTexts["You replied to ???'s mist:"]/*[[".cells.staticTexts[\"You replied to ???'s mist:\"]",".staticTexts[\"You replied to ???'s mist:\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(10)
        snapshot("07CommentScreen")
        
        // Submit Post Screen
        escapePostButton.tap()
        backButton.tap()
        submitbuttonButton.tap()
        sleep(5)
        snapshot("08WritePostScreen")
        
        // Drop Pin Screen
        dropPinButton.tap()
        app.otherElements["Target"].press(forDuration: 0.9)
        sleep(5)
        snapshot("09DropPinScreen")
        
        // Feed Screen
        backButton.tap()
        stopButton.tap()
        exploreButton.tap()
        feedButton.tap()
        sleep(5)
        snapshot("10FeedScreen")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
