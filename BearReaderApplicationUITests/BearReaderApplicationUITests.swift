//
//  BearReaderApplicationUITests.swift
//  BearReaderApplicationUITests
//
//  Created by Iaroslav Angliuster on 01.09.25.
//

import XCTest

final class BearReaderApplicationUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testBasicNavigationActions() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launch()
        
        // 2. Go to Recent tab
        print(app.tabBars)
        let recentTab = app.tabBars.buttons["Recent"]
        XCTAssertTrue(recentTab.waitForExistence(timeout: 5), "Recent tab should exist")
        recentTab.tap()
        
        // 3. On recent tab, tap on any of the new posts
        let firstPost = app.buttons["PostRow"].firstMatch
        XCTAssertTrue(firstPost.waitForExistence(timeout: 10), "At least one post should be visible")
        
        firstPost.tap()
        
        // 4. Post opens, tap on top-right corner on the burger menu
        let menuButton = app.buttons["PostMenuButton"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "Menu button should be visible on post detail")
        menuButton.tap()
        
        // 5. Tap on "Subscribe to AUTHORNAME"
        let subscribePredicate = NSPredicate(format: "label BEGINSWITH 'Subscribe to '")
        let subscribeButton = app.buttons.element(matching: subscribePredicate)
        
        if !subscribeButton.waitForExistence(timeout: 2) {
             
            // Check if already subscribed, if exists -> unsub, then sub again
             let unsubscribePredicate = NSPredicate(format: "label BEGINSWITH 'Unsubscribe from '")
             let unsubscribeButton = app.buttons.element(matching: unsubscribePredicate)
             
             if unsubscribeButton.exists {
                 unsubscribeButton.tap()
                 menuButton.tap()
             }
        }
        
        XCTAssertTrue(subscribeButton.waitForExistence(timeout: 5), "Subscribe button should be visible")
        let buttonLabel = subscribeButton.label
        guard let domain = buttonLabel.components(separatedBy: "Subscribe to ").last else {
            XCTFail("Could not extract domain from button label: \(buttonLabel)")
            return
        }
        
        subscribeButton.tap()
        
        // 6. Swipe from left to right to go back to the recent tab
        app.windows.firstMatch.swipeRight()
        
        // 7. Go to the Blogs tab
        let blogsTab = app.tabBars.buttons["Blogs"]
        XCTAssertTrue(blogsTab.waitForExistence(timeout: 2), "Blogs tab should exist")
        blogsTab.tap()
        
        // 8. Check if we have author name blog in there
        let expectedBlogTitle = domain.components(separatedBy: ".").first?.capitalized ?? domain
        
        let blogText = app.staticTexts[expectedBlogTitle]
        XCTAssertTrue(blogText.waitForExistence(timeout: 5), "Blog '\(expectedBlogTitle)' should be present in Blogs tab")
        
        // 9. Tap on it and load the blog
        blogText.tap()
        
        // 10. On the loaded blog, tap on any post that is visible to see if it loads
        let blogPost = app.buttons["PostRow"].firstMatch
        XCTAssertTrue(blogPost.waitForExistence(timeout: 10), "Blog feed should load posts")
        blogPost.tap()
        
        // Verify we are in a post view
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "Should have navigated to post detail")
    }
}
