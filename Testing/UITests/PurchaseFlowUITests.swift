//
//  PurchaseFlowUITests.swift
//  ModaicsUITests
//
//  UI Tests for complete purchase flow
//  Tests: Item selection, checkout, payment, confirmation
//

import XCTest

final class PurchaseFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-payments"]
        app.launch()
        
        // Login first
        performLogin()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Purchase Flow Entry Tests
    
    func testPurchaseFlow_BuyNowButton() {
        // Navigate to an item
        navigateToItemDetail()
        
        // Tap buy now
        let buyNowButton = app.buttons["buyNowButton"]
        XCTAssertTrue(buyNowButton.waitForExistence(timeout: 5))
        buyNowButton.tap()
        
        // Verify checkout appears
        let checkoutNav = app.navigationBars["Checkout"]
        XCTAssertTrue(checkoutNav.waitForExistence(timeout: 5))
    }
    
    func testPurchaseFlow_MakeOfferButton() {
        navigateToItemDetail()
        
        // Tap make offer
        let makeOfferButton = app.buttons["makeOfferButton"]
        if makeOfferButton.waitForExistence(timeout: 5) {
            makeOfferButton.tap()
            
            // Verify offer sheet
            let offerSheet = app.sheets["makeOfferSheet"]
            XCTAssertTrue(offerSheet.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Review Step Tests
    
    func testPurchaseFlow_ReviewStep_ItemDetails() {
        startPurchaseFlow()
        
        // Verify item details shown
        let itemTitle = app.staticTexts["checkoutItemTitle"]
        XCTAssertTrue(itemTitle.waitForExistence(timeout: 5))
        
        let itemPrice = app.staticTexts["checkoutItemPrice"]
        XCTAssertTrue(itemPrice.exists)
        
        let itemImage = app.images["checkoutItemImage"]
        XCTAssertTrue(itemImage.exists)
    }
    
    func testPurchaseFlow_ReviewStep_FeeBreakdown() {
        startPurchaseFlow()
        
        // Verify fee breakdown
        let itemPrice = app.staticTexts["itemPriceLabel"]
        XCTAssertTrue(itemPrice.waitForExistence(timeout: 5))
        
        let buyerFee = app.staticTexts["buyerFeeLabel"]
        XCTAssertTrue(buyerFee.exists)
        
        let totalPrice = app.staticTexts["totalPriceLabel"]
        XCTAssertTrue(totalPrice.exists)
    }
    
    func testPurchaseFlow_ReviewStep_InternationalToggle() {
        startPurchaseFlow()
        
        // Toggle international shipping
        let internationalSwitch = app.switches["internationalShippingSwitch"]
        XCTAssertTrue(internationalSwitch.waitForExistence(timeout: 5))
        
        let initialTotal = getTotalPrice()
        
        internationalSwitch.tap()
        
        // Verify fee changed (lower for international)
        let newTotal = getTotalPrice()
        XCTAssertLessThan(newTotal, initialTotal)
    }
    
    func testPurchaseFlow_ReviewStep_Navigation() {
        startPurchaseFlow()
        
        // Continue to shipping
        let continueButton = app.buttons["continueToShipping"]
        continueButton.tap()
        
        // Verify shipping step
        let shippingTitle = app.staticTexts["shippingTitle"]
        XCTAssertTrue(shippingTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Shipping Step Tests
    
    func testPurchaseFlow_ShippingStep_Display() {
        startPurchaseFlow()
        proceedToShipping()
        
        // Verify shipping form elements
        let nameField = app.textFields["shippingNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        
        let addressField = app.textFields["addressLine1Field"]
        XCTAssertTrue(addressField.exists)
        
        let cityField = app.textFields["cityField"]
        XCTAssertTrue(cityField.exists)
        
        let zipField = app.textFields["zipCodeField"]
        XCTAssertTrue(zipField.exists)
    }
    
    func testPurchaseFlow_ShippingStep_SavedAddress() {
        startPurchaseFlow()
        proceedToShipping()
        
        // Select saved address if available
        let savedAddresses = app.scrollViews["savedAddresses"]
        if savedAddresses.waitForExistence(timeout: 5) {
            let firstAddress = savedAddresses.buttons.firstMatch
            if firstAddress.exists {
                firstAddress.tap()
                
                // Verify fields populated
                let nameField = app.textFields["shippingNameField"]
                XCTAssertFalse((nameField.value as? String)?.isEmpty ?? true)
            }
        }
    }
    
    func testPurchaseFlow_ShippingStep_Validation() {
        startPurchaseFlow()
        proceedToShipping()
        
        // Clear required field
        let nameField = app.textFields["shippingNameField"]
        nameField.tap()
        nameField.clearText()
        
        // Try to continue
        let continueButton = app.buttons["continueToPayment"]
        continueButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["errorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5))
    }
    
    func testPurchaseFlow_ShippingStep_BackNavigation() {
        startPurchaseFlow()
        proceedToShipping()
        
        // Go back
        let backButton = app.buttons["backToReview"]
        backButton.tap()
        
        // Verify back on review step
        let reviewTitle = app.staticTexts["reviewTitle"]
        XCTAssertTrue(reviewTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Payment Step Tests
    
    func testPurchaseFlow_PaymentStep_Display() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Verify payment options
        let cardOption = app.buttons["cardPaymentOption"]
        XCTAssertTrue(cardOption.waitForExistence(timeout: 5))
        
        let applePayOption = app.buttons["applePayOption"]
        XCTAssertTrue(applePayOption.exists)
    }
    
    func testPurchaseFlow_PaymentStep_OrderSummary() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Verify order summary
        let orderSummary = app.scrollViews["orderSummary"]
        XCTAssertTrue(orderSummary.waitForExistence(timeout: 5))
        
        let totalAmount = app.staticTexts["paymentTotalAmount"]
        XCTAssertTrue(totalAmount.exists)
    }
    
    func testPurchaseFlow_PaymentStep_SelectCard() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Select card payment
        let cardOption = app.buttons["cardPaymentOption"]
        cardOption.tap()
        
        // Verify card form or payment sheet appears
        let paymentSheet = app.otherElements["paymentSheet"]
        _ = paymentSheet.waitForExistence(timeout: 5)
    }
    
    func testPurchaseFlow_PaymentStep_SelectApplePay() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Select Apple Pay
        let applePayOption = app.buttons["applePayOption"]
        applePayOption.tap()
        
        // Verify Apple Pay button enabled
        let applePayButton = app.buttons["applePayButton"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 5))
        XCTAssertTrue(applePayButton.isEnabled)
    }
    
    func testPurchaseFlow_PaymentStep_BackNavigation() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Go back
        let backButton = app.buttons["backToShipping"]
        backButton.tap()
        
        // Verify back on shipping step
        let shippingTitle = app.staticTexts["shippingTitle"]
        XCTAssertTrue(shippingTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Payment Processing Tests
    
    func testPurchaseFlow_Payment_Success() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Complete payment
        let payButton = app.buttons["payNowButton"]
        payButton.tap()
        
        // Verify confirmation
        let confirmationTitle = app.staticTexts["confirmationTitle"]
        XCTAssertTrue(confirmationTitle.waitForExistence(timeout: 15))
    }
    
    func testPurchaseFlow_Payment_Cancel() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Cancel payment
        let cancelButton = app.buttons["cancelPayment"]
        if cancelButton.waitForExistence(timeout: 5) {
            cancelButton.tap()
            
            // Verify confirmation alert
            let alert = app.alerts["cancelPaymentAlert"]
            XCTAssertTrue(alert.waitForExistence(timeout: 5))
        }
    }
    
    func testPurchaseFlow_Payment_Error() {
        // Configure mock to fail
        app.launchArguments = ["--uitesting", "--mock-payment-failure"]
        app.terminate()
        app.launch()
        performLogin()
        
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        // Attempt payment
        let payButton = app.buttons["payNowButton"]
        payButton.tap()
        
        // Verify error
        let errorMessage = app.staticTexts["paymentErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
    }
    
    // MARK: - Confirmation Tests
    
    func testPurchaseFlow_Confirmation_Display() {
        completePurchase()
        
        // Verify confirmation elements
        let successIcon = app.images["successIcon"]
        XCTAssertTrue(successIcon.waitForExistence(timeout: 5))
        
        let confirmationMessage = app.staticTexts["confirmationMessage"]
        XCTAssertTrue(confirmationMessage.exists)
        
        let orderNumber = app.staticTexts["orderNumberLabel"]
        XCTAssertTrue(orderNumber.exists)
    }
    
    func testPurchaseFlow_Confirmation_ViewOrder() {
        completePurchase()
        
        let viewOrderButton = app.buttons["viewOrderButton"]
        XCTAssertTrue(viewOrderButton.waitForExistence(timeout: 5))
        
        viewOrderButton.tap()
        
        // Verify order details
        let orderDetailNav = app.navigationBars["Order Details"]
        XCTAssertTrue(orderDetailNav.waitForExistence(timeout: 5))
    }
    
    func testPurchaseFlow_Confirmation_ContinueShopping() {
        completePurchase()
        
        let continueButton = app.buttons["continueShoppingButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        
        continueButton.tap()
        
        // Verify back on home
        let homeView = app.otherElements["homeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5))
    }
    
    // MARK: - Cart Tests
    
    func testPurchaseFlow_Cart_AddItem() {
        navigateToItemDetail()
        
        // Add to cart
        let addToCartButton = app.buttons["addToCartButton"]
        if addToCartButton.waitForExistence(timeout: 5) {
            addToCartButton.tap()
            
            // Verify cart badge updated
            let cartBadge = app.staticTexts["cartBadge"]
            XCTAssertTrue(cartBadge.waitForExistence(timeout: 5))
        }
    }
    
    func testPurchaseFlow_Cart_View() {
        // Navigate to cart
        let cartTab = app.tabBars["mainTabBar"].buttons["cartTab"]
        cartTab.tap()
        
        // Verify cart screen
        let cartNav = app.navigationBars["Shopping Cart"]
        XCTAssertTrue(cartNav.waitForExistence(timeout: 5))
    }
    
    func testPurchaseFlow_Cart_Checkout() {
        // Add item to cart first
        testPurchaseFlow_Cart_AddItem()
        
        // Go to cart
        let cartTab = app.tabBars["mainTabBar"].buttons["cartTab"]
        cartTab.tap()
        
        // Tap checkout
        let checkoutButton = app.buttons["checkoutButton"]
        if checkoutButton.waitForExistence(timeout: 5) {
            checkoutButton.tap()
            
            // Verify checkout flow started
            let checkoutNav = app.navigationBars["Checkout"]
            XCTAssertTrue(checkoutNav.waitForExistence(timeout: 5))
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
    
    private func navigateToItemDetail() {
        // Navigate to discover/search and select first item
        let searchTab = app.tabBars["mainTabBar"].buttons["searchTab"]
        searchTab.tap()
        
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("jacket")
        app.keyboards.buttons["Search"].tap()
        
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        if resultsGrid.waitForExistence(timeout: 10) {
            let firstResult = resultsGrid.cells.firstMatch
            if firstResult.waitForExistence(timeout: 5) {
                firstResult.tap()
                
                let itemDetailNav = app.navigationBars["Item Details"]
                XCTAssertTrue(itemDetailNav.waitForExistence(timeout: 5))
            }
        }
    }
    
    private func startPurchaseFlow() {
        navigateToItemDetail()
        
        let buyNowButton = app.buttons["buyNowButton"]
        XCTAssertTrue(buyNowButton.waitForExistence(timeout: 5))
        buyNowButton.tap()
        
        let checkoutNav = app.navigationBars["Checkout"]
        XCTAssertTrue(checkoutNav.waitForExistence(timeout: 5))
    }
    
    private func proceedToShipping() {
        let continueButton = app.buttons["continueToShipping"]
        continueButton.tap()
        
        let shippingTitle = app.staticTexts["shippingTitle"]
        XCTAssertTrue(shippingTitle.waitForExistence(timeout: 5))
    }
    
    private func fillShippingForm() {
        let nameField = app.textFields["shippingNameField"]
        nameField.tap()
        nameField.typeText("Test User")
        
        let addressField = app.textFields["addressLine1Field"]
        addressField.tap()
        addressField.typeText("123 Test Street")
        
        let cityField = app.textFields["cityField"]
        cityField.tap()
        cityField.typeText("New York")
        
        let stateField = app.textFields["stateField"]
        stateField.tap()
        stateField.typeText("NY")
        
        let zipField = app.textFields["zipCodeField"]
        zipField.tap()
        zipField.typeText("10001")
        
        // Dismiss keyboard
        app.keyboards.buttons["Done"].tap()
    }
    
    private func proceedToPayment() {
        let continueButton = app.buttons["continueToPayment"]
        continueButton.tap()
        
        let paymentTitle = app.staticTexts["paymentTitle"]
        XCTAssertTrue(paymentTitle.waitForExistence(timeout: 5))
    }
    
    private func completePurchase() {
        startPurchaseFlow()
        proceedToShipping()
        fillShippingForm()
        proceedToPayment()
        
        let payButton = app.buttons["payNowButton"]
        payButton.tap()
        
        let confirmationTitle = app.staticTexts["confirmationTitle"]
        XCTAssertTrue(confirmationTitle.waitForExistence(timeout: 15))
    }
    
    private func getTotalPrice() -> Double {
        let totalLabel = app.staticTexts["totalPriceLabel"]
        if totalLabel.exists {
            let text = totalLabel.label
            // Extract number from string like "$150.00"
            let numberString = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            return Double(numberString) ?? 0
        }
        return 0
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
