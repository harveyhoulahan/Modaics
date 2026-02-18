//
//  ItemCreationFlowUITests.swift
//  ModaicsUITests
//
//  UI Tests for item creation flow
//  Tests: Upload → AI Analysis → Save
//

import XCTest

final class ItemCreationFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-ai-analysis"]
        app.launch()
        
        // Login first
        performLogin()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Create Flow Entry Tests
    
    func testCreateFlow_NavigationFromTabBar() {
        // Tap create tab
        let createTab = app.tabBars["mainTabBar"].buttons["createTab"]
        createTab.tap()
        
        // Verify create screen appears
        let createTitle = app.navigationBars["Create Listing"]
        XCTAssertTrue(createTitle.waitForExistence(timeout: 5))
    }
    
    func testCreateFlow_FABEntry() {
        // Look for floating action button
        let fab = app.buttons["createItemFAB"]
        
        if fab.exists {
            fab.tap()
            
            let createTitle = app.navigationBars["Create Listing"]
            XCTAssertTrue(createTitle.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Image Upload Tests
    
    func testCreateFlow_AddImageFromCamera() {
        navigateToCreateScreen()
        
        // Tap add image button
        let addImageButton = app.buttons["addImageButton"]
        addImageButton.tap()
        
        // Select camera option
        let cameraOption = app.buttons["cameraOption"]
        XCTAssertTrue(cameraOption.waitForExistence(timeout: 5))
        cameraOption.tap()
        
        // Note: Camera interaction is limited in simulator
        // Verify camera permission or fallback
    }
    
    func testCreateFlow_AddImageFromGallery() {
        navigateToCreateScreen()
        
        let addImageButton = app.buttons["addImageButton"]
        addImageButton.tap()
        
        // Select gallery option
        let galleryOption = app.buttons["galleryOption"]
        XCTAssertTrue(galleryOption.waitForExistence(timeout: 5))
        galleryOption.tap()
        
        // Select first photo
        let firstPhoto = app.scrollViews["photoGrid"].images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            firstPhoto.tap()
            
            // Verify image appears in preview
            let imagePreview = app.images["itemImagePreview"]
            XCTAssertTrue(imagePreview.waitForExistence(timeout: 5))
        }
    }
    
    func testCreateFlow_AddMultipleImages() {
        navigateToCreateScreen()
        
        // Add first image
        addImageFromGallery()
        
        // Add second image
        let addImageButton = app.buttons["addImageButton"]
        addImageButton.tap()
        
        let galleryOption = app.buttons["galleryOption"]
        if galleryOption.waitForExistence(timeout: 5) {
            galleryOption.tap()
            
            let secondPhoto = app.scrollViews["photoGrid"].images.element(boundBy: 1)
            if secondPhoto.waitForExistence(timeout: 5) {
                secondPhoto.tap()
                
                // Verify both images shown
                let imageCarousel = app.scrollViews["imageCarousel"]
                XCTAssertTrue(imageCarousel.waitForExistence(timeout: 5))
            }
        }
    }
    
    func testCreateFlow_RemoveImage() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Tap remove button on image
        let removeButton = app.buttons["removeImageButton"]
        if removeButton.waitForExistence(timeout: 5) {
            removeButton.tap()
            
            // Confirm removal
            let confirmButton = app.buttons["confirmRemove"]
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
            }
            
            // Verify image removed
            let imagePreview = app.images["itemImagePreview"]
            XCTAssertFalse(imagePreview.exists)
        }
    }
    
    // MARK: - AI Analysis Tests
    
    func testCreateFlow_AIAnalysis_Triggered() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // AI analysis should start automatically
        let analyzingIndicator = app.activityIndicators["analyzingIndicator"]
        XCTAssertTrue(analyzingIndicator.waitForExistence(timeout: 5))
        
        // Wait for analysis to complete
        let aiResults = app.scrollViews["aiAnalysisResults"]
        XCTAssertTrue(aiResults.waitForExistence(timeout: 15))
    }
    
    func testCreateFlow_AIAnalysis_Results() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Wait for AI results
        let categoryLabel = app.staticTexts["aiCategoryLabel"]
        XCTAssertTrue(categoryLabel.waitForExistence(timeout: 15))
        
        // Verify suggested fields populated
        let titleField = app.textFields["titleTextField"]
        let categoryField = app.textFields["categoryTextField"]
        
        XCTAssertFalse(titleField.placeholderValue?.isEmpty ?? true)
        XCTAssertTrue(categoryField.exists)
    }
    
    func testCreateFlow_AIAnalysis_CategorySuggestions() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Wait for AI category
        let categoryChip = app.buttons["categoryChip"]
        XCTAssertTrue(categoryChip.waitForExistence(timeout: 15))
        
        // Tap to change category
        categoryChip.tap()
        
        let categoryPicker = app.pickers["categoryPicker"]
        XCTAssertTrue(categoryPicker.waitForExistence(timeout: 5))
    }
    
    func testCreateFlow_AIAnalysis_Tags() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Wait for AI tags
        let tagsScrollView = app.scrollViews["aiSuggestedTags"]
        XCTAssertTrue(tagsScrollView.waitForExistence(timeout: 15))
        
        // Tap a suggested tag to add
        let firstTag = tagsScrollView.buttons.firstMatch
        if firstTag.exists {
            firstTag.tap()
            
            // Verify tag added
            let selectedTags = app.scrollViews["selectedTags"]
            XCTAssertTrue(selectedTags.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Form Validation Tests
    
    func testCreateFlow_Validation_EmptyTitle() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Clear title if AI filled it
        let titleField = app.textFields["titleTextField"]
        titleField.tap()
        titleField.clearText()
        
        // Try to submit
        let submitButton = app.buttons["submitButton"]
        submitButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testCreateFlow_Validation_InvalidPrice() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        let priceField = app.textFields["priceTextField"]
        priceField.tap()
        priceField.typeText("-10")
        
        let submitButton = app.buttons["submitButton"]
        submitButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testCreateFlow_Validation_NoImages() {
        navigateToCreateScreen()
        
        // Fill title without adding image
        let titleField = app.textFields["titleTextField"]
        titleField.tap()
        titleField.typeText("Test Item")
        
        let submitButton = app.buttons["submitButton"]
        submitButton.tap()
        
        // Verify error about images
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    // MARK: - Complete Item Creation Tests
    
    func testCreateFlow_Complete_Success() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Wait for AI analysis
        waitForAIAnalysis()
        
        // Edit title
        let titleField = app.textFields["titleTextField"]
        titleField.tap()
        titleField.clearText()
        titleField.typeText("Vintage Leather Jacket")
        
        // Set price
        let priceField = app.textFields["priceTextField"]
        priceField.tap()
        priceField.typeText("150")
        
        // Set condition
        let conditionPicker = app.buttons["conditionPicker"]
        conditionPicker.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Excellent")
        app.toolbars.buttons["Done"].tap()
        
        // Set size
        let sizeField = app.textFields["sizeTextField"]
        sizeField.tap()
        sizeField.typeText("M")
        
        // Submit
        let submitButton = app.buttons["submitButton"]
        submitButton.tap()
        
        // Verify success
        let successMessage = app.staticTexts["successMessage"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 10))
        
        // Verify navigation to item detail
        let itemDetailTitle = app.navigationBars["Item Details"]
        XCTAssertTrue(itemDetailTitle.waitForExistence(timeout: 5))
    }
    
    func testCreateFlow_SaveAsDraft() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Fill minimal info
        let titleField = app.textFields["titleTextField"]
        titleField.tap()
        titleField.typeText("Draft Item")
        
        // Save as draft
        let saveDraftButton = app.buttons["saveDraftButton"]
        saveDraftButton.tap()
        
        // Verify draft saved
        let successMessage = app.staticTexts["successMessage"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 5))
    }
    
    // MARK: - Advanced Options Tests
    
    func testCreateFlow_ShippingOptions() {
        navigateToCreateScreen()
        
        // Expand shipping section
        let shippingSection = app.buttons["shippingSection"]
        shippingSection.tap()
        
        // Toggle international shipping
        let internationalSwitch = app.switches["internationalShippingSwitch"]
        XCTAssertTrue(internationalSwitch.waitForExistence(timeout: 5))
        internationalSwitch.tap()
        
        // Set shipping cost
        let shippingCostField = app.textFields["shippingCostTextField"]
        shippingCostField.tap()
        shippingCostField.typeText("10")
    }
    
    func testCreateFlow_BrandField() {
        navigateToCreateScreen()
        
        // Find brand field
        let brandField = app.textFields["brandTextField"]
        if brandField.exists {
            brandField.tap()
            brandField.typeText("Nike")
            
            // Verify brand suggestions appear
            let suggestionsList = app.tables["brandSuggestions"]
            _ = suggestionsList.waitForExistence(timeout: 5)
        }
    }
    
    func testCreateFlow_ColorSelection() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Wait for AI colors
        let colorSection = app.scrollViews["colorSelection"]
        XCTAssertTrue(colorSection.waitForExistence(timeout: 15))
        
        // Select a color
        let colorButton = colorSection.buttons.firstMatch
        if colorButton.exists {
            colorButton.tap()
            
            // Verify color selected
            XCTAssertTrue(colorButton.isSelected)
        }
    }
    
    // MARK: - Cancel Flow Tests
    
    func testCreateFlow_CancelConfirmation() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Enter some data
        let titleField = app.textFields["titleTextField"]
        titleField.tap()
        titleField.typeText("Test")
        
        // Tap cancel
        let cancelButton = app.buttons["cancelButton"]
        cancelButton.tap()
        
        // Verify confirmation alert
        let alert = app.alerts["discardChangesAlert"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Confirm discard
        alert.buttons["Discard"].tap()
        
        // Verify back on home
        let homeView = app.otherElements["homeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5))
    }
    
    func testCreateFlow_CancelKeepEditing() {
        navigateToCreateScreen()
        addImageFromGallery()
        
        // Enter data
        let titleField = app.textFields["titleTextField"]
        titleField.tap()
        titleField.typeText("Test")
        
        // Tap cancel
        let cancelButton = app.buttons["cancelButton"]
        cancelButton.tap()
        
        // Select keep editing
        let alert = app.alerts["discardChangesAlert"]
        alert.buttons["Keep Editing"].tap()
        
        // Verify still on create screen
        let createTitle = app.navigationBars["Create Listing"]
        XCTAssertTrue(createTitle.exists)
        
        // Verify data preserved
        XCTAssertEqual(titleField.value as? String, "Test")
    }
    
    // MARK: - Helper Methods
    
    private func performLogin() {
        // Handle onboarding if needed
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
                
                // Wait for home
                _ = app.tabBars["mainTabBar"].waitForExistence(timeout: 10)
            }
        }
    }
    
    private func navigateToCreateScreen() {
        let createTab = app.tabBars["mainTabBar"].buttons["createTab"]
        createTab.tap()
        
        let createTitle = app.navigationBars["Create Listing"]
        XCTAssertTrue(createTitle.waitForExistence(timeout: 5))
    }
    
    private func addImageFromGallery() {
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
    
    private func waitForAIAnalysis() {
        let aiResults = app.scrollViews["aiAnalysisResults"]
        XCTAssertTrue(aiResults.waitForExistence(timeout: 15))
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}
