//
//  SketchbookFlowUITests.swift
//  ModaicsUITests
//
//  UI Tests for Sketchbook (Brand & Consumer) functionality
//  Tests: View, create posts, polls, reactions, membership
//

import XCTest

final class SketchbookFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-sketchbook"]
        app.launch()
        
        // Login first
        performLogin()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Sketchbook Entry Tests
    
    func testSketchbook_NavigationFromTabBar() {
        // Tap sketchbook tab
        let sketchbookTab = app.tabBars["mainTabBar"].buttons["sketchbookTab"]
        sketchbookTab.tap()
        
        // Verify sketchbook screen
        let sketchbookTitle = app.navigationBars["Sketchbook"]
        XCTAssertTrue(sketchbookTitle.waitForExistence(timeout: 5))
    }
    
    func testSketchbook_NavigationFromBrandProfile() {
        // Navigate to brand profile
        let searchTab = app.tabBars["mainTabBar"].buttons["searchTab"]
        searchTab.tap()
        
        // Search for a brand
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("brand")
        app.keyboards.buttons["Search"].tap()
        
        // Tap on a brand
        let brandCell = app.cells.firstMatch
        if brandCell.waitForExistence(timeout: 5) {
            brandCell.tap()
            
            // Look for sketchbook button
            let sketchbookButton = app.buttons["viewSketchbookButton"]
            if sketchbookButton.waitForExistence(timeout: 5) {
                sketchbookButton.tap()
                
                let sketchbookView = app.scrollViews["sketchbookFeed"]
                XCTAssertTrue(sketchbookView.waitForExistence(timeout: 5))
            }
        }
    }
    
    // MARK: - Sketchbook Feed Tests
    
    func testSketchbookFeed_LoadsPosts() {
        navigateToSketchbook()
        
        // Verify feed loads
        let feed = app.scrollViews["sketchbookFeed"]
        XCTAssertTrue(feed.waitForExistence(timeout: 10))
        
        // Verify posts exist
        let firstPost = feed.cells.firstMatch
        XCTAssertTrue(firstPost.waitForExistence(timeout: 5))
    }
    
    func testSketchbookFeed_Scroll() {
        navigateToSketchbook()
        
        let feed = app.scrollViews["sketchbookFeed"]
        XCTAssertTrue(feed.waitForExistence(timeout: 10))
        
        // Scroll down
        feed.swipeUp()
        
        // Verify more posts loaded
        let morePosts = feed.cells.element(boundBy: 3)
        XCTAssertTrue(morePosts.waitForExistence(timeout: 5))
    }
    
    func testSketchbookFeed_PullToRefresh() {
        navigateToSketchbook()
        
        let feed = app.scrollViews["sketchbookFeed"]
        XCTAssertTrue(feed.waitForExistence(timeout: 10))
        
        // Pull to refresh
        feed.pullToRefresh()
        
        // Verify loading indicator
        let loadingIndicator = app.activityIndicators["refreshIndicator"]
        _ = loadingIndicator.waitForExistence(timeout: 5)
    }
    
    // MARK: - Post Detail Tests
    
    func testSketchbook_PostDetail_View() {
        navigateToSketchbook()
        
        // Tap on first post
        let feed = app.scrollViews["sketchbookFeed"]
        let firstPost = feed.cells.firstMatch
        XCTAssertTrue(firstPost.waitForExistence(timeout: 5))
        firstPost.tap()
        
        // Verify detail view
        let postDetailNav = app.navigationBars["Post Details"]
        XCTAssertTrue(postDetailNav.waitForExistence(timeout: 5))
    }
    
    func testSketchbook_PostDetail_Content() {
        openPostDetail()
        
        // Verify post elements
        let postImage = app.images["postImage"]
        XCTAssertTrue(postImage.waitForExistence(timeout: 5))
        
        let postCaption = app.staticTexts["postCaption"]
        XCTAssertTrue(postCaption.exists)
        
        let authorName = app.staticTexts["authorName"]
        XCTAssertTrue(authorName.exists)
        
        let timestamp = app.staticTexts["postTimestamp"]
        XCTAssertTrue(timestamp.exists)
    }
    
    func testSketchbook_PostDetail_Reactions() {
        openPostDetail()
        
        // Verify reaction buttons
        let likeButton = app.buttons["likeButton"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 5))
        
        let commentButton = app.buttons["commentButton"]
        XCTAssertTrue(commentButton.exists)
        
        let shareButton = app.buttons["shareButton"]
        XCTAssertTrue(shareButton.exists)
    }
    
    func testSketchbook_PostDetail_Like() {
        openPostDetail()
        
        let likeButton = app.buttons["likeButton"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 5))
        
        // Tap like
        likeButton.tap()
        
        // Verify like state changed
        XCTAssertTrue(likeButton.isSelected)
    }
    
    // MARK: - Poll Tests
    
    func testSketchbook_Poll_Display() {
        navigateToSketchbook()
        
        // Look for poll post
        let feed = app.scrollViews["sketchbookFeed"]
        let pollPost = feed.cells.containing(.staticText, identifier: "pollQuestion").firstMatch
        
        if pollPost.waitForExistence(timeout: 5) {
            // Verify poll options
            let optionA = pollPost.buttons["pollOptionA"]
            XCTAssertTrue(optionA.exists)
            
            let optionB = pollPost.buttons["pollOptionB"]
            XCTAssertTrue(optionB.exists)
        }
    }
    
    func testSketchbook_Poll_Vote() {
        navigateToSketchbook()
        
        let feed = app.scrollViews["sketchbookFeed"]
        let pollPost = feed.cells.containing(.staticText, identifier: "pollQuestion").firstMatch
        
        if pollPost.waitForExistence(timeout: 5) {
            // Vote on option A
            let optionA = pollPost.buttons["pollOptionA"]
            optionA.tap()
            
            // Verify results shown
            let resultsView = pollPost.otherElements["pollResults"]
            XCTAssertTrue(resultsView.waitForExistence(timeout: 5))
        }
    }
    
    func testSketchbook_Poll_Results() {
        navigateToSketchbook()
        
        let feed = app.scrollViews["sketchbookFeed"]
        let pollPost = feed.cells.containing(.otherElement, identifier: "pollResults").firstMatch
        
        if pollPost.waitForExistence(timeout: 5) {
            // Verify percentage labels
            let percentageA = pollPost.staticTexts["percentageA"]
            XCTAssertTrue(percentageA.exists)
            
            let percentageB = pollPost.staticTexts["percentageB"]
            XCTAssertTrue(percentageB.exists)
            
            let totalVotes = pollPost.staticTexts["totalVotes"]
            XCTAssertTrue(totalVotes.exists)
        }
    }
    
    // MARK: - Create Post Tests (Brand)
    
    func testSketchbook_CreatePost_ButtonExists() {
        // Login as brand user for this test
        navigateToSketchbook()
        
        let createButton = app.buttons["createPostButton"]
        _ = createButton.waitForExistence(timeout: 5)
    }
    
    func testSketchbook_CreatePost_Image() {
        navigateToSketchbook()
        
        let createButton = app.buttons["createPostButton"]
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
            
            // Verify create post screen
            let createNav = app.navigationBars["Create Post"]
            XCTAssertTrue(createNav.waitForExistence(timeout: 5))
            
            // Add image
            let addImageButton = app.buttons["addImageButton"]
            addImageButton.tap()
            
            let galleryOption = app.buttons["galleryOption"]
            if galleryOption.waitForExistence(timeout: 5) {
                galleryOption.tap()
                
                let firstPhoto = app.scrollViews["photoGrid"].images.firstMatch
                if firstPhoto.waitForExistence(timeout: 5) {
                    firstPhoto.tap()
                    
                    // Verify image added
                    let imagePreview = app.images["postImagePreview"]
                    XCTAssertTrue(imagePreview.waitForExistence(timeout: 5))
                }
            }
        }
    }
    
    func testSketchbook_CreatePost_WithCaption() {
        startCreatingPost()
        
        // Add caption
        let captionField = app.textViews["captionTextView"]
        captionField.tap()
        captionField.typeText("Check out our new collection! #sustainablefashion")
        
        // Verify character count
        let charCount = app.staticTexts["characterCount"]
        XCTAssertTrue(charCount.exists)
    }
    
    func testSketchbook_CreatePost_CreatePoll() {
        startCreatingPost()
        
        // Toggle poll creation
        let pollToggle = app.switches["addPollSwitch"]
        if pollToggle.waitForExistence(timeout: 5) {
            pollToggle.tap()
            
            // Fill poll options
            let option1Field = app.textFields["pollOption1"]
            option1Field.tap()
            option1Field.typeText("Option A")
            
            let option2Field = app.textFields["pollOption2"]
            option2Field.tap()
            option2Field.typeText("Option B")
            
            // Verify options added
            XCTAssertEqual(option1Field.value as? String, "Option A")
            XCTAssertEqual(option2Field.value as? String, "Option B")
        }
    }
    
    func testSketchbook_CreatePost_Publish() {
        startCreatingPost()
        
        // Add image
        addImageToPost()
        
        // Add caption
        let captionField = app.textViews["captionTextView"]
        captionField.tap()
        captionField.typeText("New post!")
        
        // Publish
        let publishButton = app.buttons["publishButton"]
        publishButton.tap()
        
        // Verify published
        let successMessage = app.staticTexts["postPublishedMessage"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 10))
    }
    
    func testSketchbook_CreatePost_Schedule() {
        startCreatingPost()
        
        addImageToPost()
        
        // Open schedule options
        let scheduleButton = app.buttons["scheduleButton"]
        scheduleButton.tap()
        
        // Select date
        let datePicker = app.datePickers["scheduleDatePicker"]
        XCTAssertTrue(datePicker.waitForExistence(timeout: 5))
        
        // Select future date
        datePicker.tap()
        // Select date logic would go here
        
        // Confirm
        let confirmButton = app.buttons["confirmSchedule"]
        confirmButton.tap()
        
        // Verify scheduled indicator
        let scheduledBadge = app.staticTexts["scheduledBadge"]
        XCTAssertTrue(scheduledBadge.waitForExistence(timeout: 5))
    }
    
    // MARK: - Membership Tests
    
    func testSketchbook_Membership_Badge() {
        navigateToSketchbook()
        
        // Look for membership badge
        let membershipBadge = app.staticTexts["membershipBadge"]
        _ = membershipBadge.waitForExistence(timeout: 5)
    }
    
    func testSketchbook_Membership_JoinButton() {
        // Navigate to brand sketchbook (not joined)
        navigateToBrandSketchbook()
        
        let joinButton = app.buttons["joinSketchbookButton"]
        if joinButton.waitForExistence(timeout: 5) {
            // Verify join button exists
            XCTAssertTrue(joinButton.exists)
            
            // Check if membership info shown
            let membershipInfo = app.staticTexts["membershipInfo"]
            XCTAssertTrue(membershipInfo.exists)
        }
    }
    
    func testSketchbook_Membership_SubscriptionOptions() {
        navigateToBrandSketchbook()
        
        let joinButton = app.buttons["joinSketchbookButton"]
        if joinButton.waitForExistence(timeout: 5) {
            joinButton.tap()
            
            // Verify subscription sheet
            let subscriptionSheet = app.sheets["subscriptionOptions"]
            XCTAssertTrue(subscriptionSheet.waitForExistence(timeout: 5))
            
            // Verify tiers
            let monthlyOption = subscriptionSheet.buttons["monthlyTier"]
            XCTAssertTrue(monthlyOption.exists)
            
            let yearlyOption = subscriptionSheet.buttons["yearlyTier"]
            XCTAssertTrue(yearlyOption.exists)
        }
    }
    
    func testSketchbook_Membership_Payment() {
        navigateToBrandSketchbook()
        
        let joinButton = app.buttons["joinSketchbookButton"]
        if joinButton.waitForExistence(timeout: 5) {
            joinButton.tap()
            
            let subscriptionSheet = app.sheets["subscriptionOptions"]
            XCTAssertTrue(subscriptionSheet.waitForExistence(timeout: 5))
            
            // Select tier
            let monthlyOption = subscriptionSheet.buttons["monthlyTier"]
            monthlyOption.tap()
            
            // Verify payment sheet
            let paymentSheet = app.otherElements["paymentSheet"]
            XCTAssertTrue(paymentSheet.waitForExistence(timeout: 10))
        }
    }
    
    // MARK: - Exclusive Content Tests
    
    func testSketchbook_ExclusiveContent_Locked() {
        navigateToBrandSketchbook()
        
        // Look for locked content indicator
        let feed = app.scrollViews["sketchbookFeed"]
        let lockedPost = feed.cells.containing(.button, identifier: "unlockButton").firstMatch
        
        if lockedPost.waitForExistence(timeout: 5) {
            // Verify lock icon
            let lockIcon = lockedPost.images["lockIcon"]
            XCTAssertTrue(lockIcon.exists)
            
            // Verify unlock button
            let unlockButton = lockedPost.buttons["unlockButton"]
            XCTAssertTrue(unlockButton.exists)
        }
    }
    
    func testSketchbook_ExclusiveContent_SpendToUnlock() {
        navigateToBrandSketchbook()
        
        let feed = app.scrollViews["sketchbookFeed"]
        let lockedPost = feed.cells.containing(.button, identifier: "unlockButton").firstMatch
        
        if lockedPost.waitForExistence(timeout: 5) {
            let unlockButton = lockedPost.buttons["unlockButton"]
            unlockButton.tap()
            
            // Verify confirmation dialog
            let alert = app.alerts["spendToUnlockAlert"]
            XCTAssertTrue(alert.waitForExistence(timeout: 5))
            
            // Confirm
            let spendButton = alert.buttons["Spend Points"]
            spendButton.tap()
            
            // Verify content unlocked
            let contentView = lockedPost.scrollViews["exclusiveContent"]
            XCTAssertTrue(contentView.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Settings Tests
    
    func testSketchbook_Settings_Access() {
        // Navigate to brand sketchbook (as owner)
        navigateToSketchbook()
        
        let settingsButton = app.buttons["sketchbookSettings"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            
            // Verify settings screen
            let settingsNav = app.navigationBars["Sketchbook Settings"]
            XCTAssertTrue(settingsNav.waitForExistence(timeout: 5))
        }
    }
    
    func testSketchbook_Settings_ToggleExclusive() {
        openSketchbookSettings()
        
        let exclusiveToggle = app.switches["exclusiveContentToggle"]
        if exclusiveToggle.waitForExistence(timeout: 5) {
            let initialValue = exclusiveToggle.value as? String
            exclusiveToggle.tap()
            
            // Verify toggle changed
            let newValue = exclusiveToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue)
        }
    }
    
    func testSketchbook_Settings_MembershipPrice() {
        openSketchbookSettings()
        
        let priceField = app.textFields["membershipPriceField"]
        if priceField.waitForExistence(timeout: 5) {
            priceField.tap()
            priceField.clearText()
            priceField.typeText("9.99")
            
            // Save
            let saveButton = app.buttons["saveSettings"]
            saveButton.tap()
            
            // Verify saved
            let successMessage = app.staticTexts["settingsSaved"]
            XCTAssertTrue(successMessage.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Helper Methods
    
    private func performLogin() {
        let getStartedButton = app.buttons["getStartedButton"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
            
            let loginButton = app.buttons["loginButton"]
            if loginButton.waitForExistence(timeout: 5) {
                loginButton.tap()
                
                let emailField = app.textFields["emailTextField"]
                emailField.tap()
                emailField.typeText("test@modaics.com")
                
                let passwordField = app.secureTextFields["passwordTextField"]
                passwordField.tap()
                passwordField.typeText("TestPass123!")
                
                app.buttons["loginButton"].tap()
                
                _ = app.tabBars["mainTabBar"].waitForExistence(timeout: 10)
            }
        }
    }
    
    private func navigateToSketchbook() {
        let sketchbookTab = app.tabBars["mainTabBar"].buttons["sketchbookTab"]
        sketchbookTab.tap()
        
        let sketchbookTitle = app.navigationBars["Sketchbook"]
        XCTAssertTrue(sketchbookTitle.waitForExistence(timeout: 5))
    }
    
    private func navigateToBrandSketchbook() {
        let searchTab = app.tabBars["mainTabBar"].buttons["searchTab"]
        searchTab.tap()
        
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("brand")
        app.keyboards.buttons["Search"].tap()
        
        let brandCell = app.cells.firstMatch
        if brandCell.waitForExistence(timeout: 5) {
            brandCell.tap()
            
            let sketchbookButton = app.buttons["viewSketchbookButton"]
            if sketchbookButton.waitForExistence(timeout: 5) {
                sketchbookButton.tap()
            }
        }
    }
    
    private func openPostDetail() {
        navigateToSketchbook()
        
        let feed = app.scrollViews["sketchbookFeed"]
        let firstPost = feed.cells.firstMatch
        XCTAssertTrue(firstPost.waitForExistence(timeout: 5))
        firstPost.tap()
        
        let postDetailNav = app.navigationBars["Post Details"]
        XCTAssertTrue(postDetailNav.waitForExistence(timeout: 5))
    }
    
    private func startCreatingPost() {
        navigateToSketchbook()
        
        let createButton = app.buttons["createPostButton"]
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
            
            let createNav = app.navigationBars["Create Post"]
            XCTAssertTrue(createNav.waitForExistence(timeout: 5))
        }
    }
    
    private func addImageToPost() {
        let addImageButton = app.buttons["addImageButton"]
        addImageButton.tap()
        
        let galleryOption = app.buttons["galleryOption"]
        if galleryOption.waitForExistence(timeout: 5) {
            galleryOption.tap()
            
            let firstPhoto = app.scrollViews["photoGrid"].images.firstMatch
            if firstPhoto.waitForExistence(timeout: 5) {
                firstPhoto.tap()
            }
        }
    }
    
    private func openSketchbookSettings() {
        navigateToSketchbook()
        
        let settingsButton = app.buttons["sketchbookSettings"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            
            let settingsNav = app.navigationBars["Sketchbook Settings"]
            XCTAssertTrue(settingsNav.waitForExistence(timeout: 5))
        }
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    func pullToRefresh() {
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0, thenDragTo: end)
    }
    
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}
