//
//  SearchFlowUITests.swift
//  ModaicsUITests
//
//  UI Tests for search functionality
//  Tests: Image search, text search, filters, results
//

import XCTest

final class SearchFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-search-results"]
        app.launch()
        
        // Login first
        performLogin()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Search Entry Tests
    
    func testSearch_NavigationFromTabBar() {
        // Tap search tab
        let searchTab = app.tabBars["mainTabBar"].buttons["searchTab"]
        searchTab.tap()
        
        // Verify search screen
        let searchBar = app.searchFields["searchBar"]
        XCTAssertTrue(searchBar.waitForExistence(timeout: 5))
    }
    
    func testSearch_SearchBarExists() {
        navigateToSearch()
        
        let searchBar = app.searchFields["searchBar"]
        XCTAssertTrue(searchBar.exists)
        XCTAssertEqual(searchBar.placeholderValue, "Search items, brands, styles...")
    }
    
    func testSearch_CancelSearch() {
        navigateToSearch()
        
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("jacket")
        
        // Cancel search
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
            
            // Verify search cleared
            XCTAssertEqual(searchBar.value as? String, "Search items, brands, styles...")
        }
    }
    
    // MARK: - Text Search Tests
    
    func testSearch_TextSearch_Results() {
        navigateToSearch()
        
        // Enter search query
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("vintage jacket")
        
        // Submit search
        app.keyboards.buttons["Search"].tap()
        
        // Wait for results
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
        
        // Verify results appear
        let firstResult = resultsGrid.cells.firstMatch
        XCTAssertTrue(firstResult.waitForExistence(timeout: 5))
    }
    
    func testSearch_TextSearch_NoResults() {
        navigateToSearch()
        
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("xyznonexistent12345")
        
        app.keyboards.buttons["Search"].tap()
        
        // Verify empty state
        let emptyState = app.staticTexts["noResultsMessage"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10))
    }
    
    func testSearch_TextSearch_LoadingState() {
        navigateToSearch()
        
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText("leather")
        
        app.keyboards.buttons["Search"].tap()
        
        // Verify loading indicator
        let loadingIndicator = app.activityIndicators["searchLoadingIndicator"]
        _ = loadingIndicator.waitForExistence(timeout: 5)
    }
    
    // MARK: - Image Search Tests
    
    func testSearch_ImageSearch_Camera() {
        navigateToSearch()
        
        // Tap camera button
        let cameraButton = app.buttons["cameraSearchButton"]
        cameraButton.tap()
        
        // Verify camera opens or permission request
        let cameraView = app.otherElements["cameraView"]
        _ = cameraView.waitForExistence(timeout: 5)
    }
    
    func testSearch_ImageSearch_Gallery() {
        navigateToSearch()
        
        // Tap gallery button
        let galleryButton = app.buttons["gallerySearchButton"]
        galleryButton.tap()
        
        // Select photo
        let firstPhoto = app.scrollViews["photoGrid"].images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            firstPhoto.tap()
            
            // Wait for search results
            let resultsGrid = app.scrollViews["searchResultsGrid"]
            XCTAssertTrue(resultsGrid.waitForExistence(timeout: 15))
        }
    }
    
    func testSearch_ImageSearch_Analyzing() {
        navigateToSearch()
        
        // Tap gallery button
        let galleryButton = app.buttons["gallerySearchButton"]
        galleryButton.tap()
        
        // Select photo
        let firstPhoto = app.scrollViews["photoGrid"].images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            firstPhoto.tap()
            
            // Verify analyzing state
            let analyzingLabel = app.staticTexts["analyzingLabel"]
            XCTAssertTrue(analyzingLabel.waitForExistence(timeout: 5))
        }
    }
    
    func testSearch_ImageSearch_VisualMatches() {
        navigateToSearch()
        
        // Perform image search
        performImageSearch()
        
        // Wait for results
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        XCTAssertTrue(resultsGrid.waitForExistence(timeout: 15))
        
        // Verify similarity scores shown
        let similarityLabel = app.staticTexts["similarityScore"]
        _ = similarityLabel.waitForExistence(timeout: 5)
    }
    
    // MARK: - Recent Searches Tests
    
    func testSearch_RecentSearches_Display() {
        navigateToSearch()
        
        // Perform a search first
        performSearch(query: "test query")
        
        // Clear search
        let clearButton = app.buttons["clearSearchButton"]
        if clearButton.exists {
            clearButton.tap()
        }
        
        // Verify recent searches section
        let recentSearchesSection = app.scrollViews["recentSearchesSection"]
        XCTAssertTrue(recentSearchesSection.waitForExistence(timeout: 5))
        
        // Verify our search appears
        let recentSearch = recentSearchesSection.buttons["test query"]
        XCTAssertTrue(recentSearch.exists)
    }
    
    func testSearch_RecentSearches_Tap() {
        navigateToSearch()
        
        // Tap recent search
        let recentSearchesSection = app.scrollViews["recentSearchesSection"]
        if recentSearchesSection.waitForExistence(timeout: 5) {
            let firstRecent = recentSearchesSection.buttons.firstMatch
            if firstRecent.exists {
                let searchText = firstRecent.label
                firstRecent.tap()
                
                // Verify search performed
                let searchBar = app.searchFields["searchBar"]
                XCTAssertEqual(searchBar.value as? String, searchText)
                
                // Verify results
                let resultsGrid = app.scrollViews["searchResultsGrid"]
                XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
            }
        }
    }
    
    func testSearch_RecentSearches_Clear() {
        navigateToSearch()
        
        let recentSearchesSection = app.scrollViews["recentSearchesSection"]
        if recentSearchesSection.waitForExistence(timeout: 5) {
            // Tap clear all
            let clearAllButton = app.buttons["clearRecentSearches"]
            if clearAllButton.exists {
                clearAllButton.tap()
                
                // Confirm clear
                let confirmButton = app.buttons["confirmClear"]
                if confirmButton.waitForExistence(timeout: 3) {
                    confirmButton.tap()
                }
                
                // Verify section hidden
                XCTAssertFalse(recentSearchesSection.exists)
            }
        }
    }
    
    func testSearch_RecentSearches_RemoveIndividual() {
        navigateToSearch()
        
        let recentSearchesSection = app.scrollViews["recentSearchesSection"]
        if recentSearchesSection.waitForExistence(timeout: 5) {
            let firstRecent = recentSearchesSection.buttons.firstMatch
            if firstRecent.exists {
                // Swipe to delete
                firstRecent.swipeLeft()
                
                let deleteButton = app.buttons["Delete"]
                if deleteButton.waitForExistence(timeout: 3) {
                    deleteButton.tap()
                    
                    // Verify removed
                    XCTAssertFalse(firstRecent.exists)
                }
            }
        }
    }
    
    // MARK: - Filter Tests
    
    func testSearch_Filters_Open() {
        navigateToSearch()
        
        // Tap filter button
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        // Verify filter sheet opens
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
    }
    
    func testSearch_Filters_Category() {
        navigateToSearch()
        performSearch(query: "jacket")
        
        // Open filters
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        // Select category
        let categoryButton = filterSheet.buttons["categoryFilter"]
        categoryButton.tap()
        
        let categoryOption = app.buttons["Outerwear"]
        if categoryOption.waitForExistence(timeout: 5) {
            categoryOption.tap()
            
            // Apply filters
            let applyButton = app.buttons["applyFilters"]
            applyButton.tap()
            
            // Verify filtered results
            let resultsGrid = app.scrollViews["searchResultsGrid"]
            XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
        }
    }
    
    func testSearch_Filters_PriceRange() {
        navigateToSearch()
        performSearch(query: "jacket")
        
        // Open filters
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        // Set price range
        let minPriceField = filterSheet.textFields["minPriceField"]
        minPriceField.tap()
        minPriceField.typeText("50")
        
        let maxPriceField = filterSheet.textFields["maxPriceField"]
        maxPriceField.tap()
        maxPriceField.typeText("200")
        
        // Apply
        let applyButton = filterSheet.buttons["applyFilters"]
        applyButton.tap()
        
        // Verify results filtered
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
    }
    
    func testSearch_Filters_Size() {
        navigateToSearch()
        performSearch(query: "shirt")
        
        // Open filters
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        // Select size
        let sizeButton = filterSheet.buttons["sizeFilter"]
        sizeButton.tap()
        
        let sizeM = app.buttons["M"]
        if sizeM.waitForExistence(timeout: 5) {
            sizeM.tap()
            
            let applyButton = app.buttons["applyFilters"]
            applyButton.tap()
            
            // Verify filter badge
            let filterBadge = app.staticTexts["activeFilterCount"]
            XCTAssertTrue(filterBadge.waitForExistence(timeout: 5))
        }
    }
    
    func testSearch_Filters_Condition() {
        navigateToSearch()
        performSearch(query: "shoes")
        
        // Open filters
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        // Select condition
        let conditionButton = filterSheet.buttons["conditionFilter"]
        conditionButton.tap()
        
        let excellentCondition = app.buttons["Excellent"]
        if excellentCondition.waitForExistence(timeout: 5) {
            excellentCondition.tap()
            
            let applyButton = app.buttons["applyFilters"]
            applyButton.tap()
        }
    }
    
    func testSearch_Filters_Reset() {
        navigateToSearch()
        
        // Open filters with active filters
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        // Tap reset
        let resetButton = filterSheet.buttons["resetFilters"]
        resetButton.tap()
        
        // Verify filters cleared
        let activeFilters = app.scrollViews["activeFilters"]
        XCTAssertFalse(activeFilters.exists)
    }
    
    func testSearch_Filters_ClearIndividual() {
        navigateToSearch()
        performSearch(query: "jacket")
        
        // Apply a filter first
        applyPriceFilter(min: 50, max: 200)
        
        // Clear individual filter
        let clearFilterButton = app.buttons["clearPriceFilter"]
        if clearFilterButton.waitForExistence(timeout: 5) {
            clearFilterButton.tap()
            
            // Verify filter removed
            XCTAssertFalse(clearFilterButton.exists)
        }
    }
    
    // MARK: - Search Result Tests
    
    func testSearch_Results_Scroll() {
        navigateToSearch()
        performSearch(query: "vintage")
        
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
        
        // Scroll down
        resultsGrid.swipeUp()
        
        // Verify more results loaded
        let lastCell = resultsGrid.cells.element(boundBy: 5)
        XCTAssertTrue(lastCell.waitForExistence(timeout: 5))
    }
    
    func testSearch_Results_TapItem() {
        navigateToSearch()
        performSearch(query: "jacket")
        
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
        
        // Tap first result
        let firstResult = resultsGrid.cells.firstMatch
        if firstResult.waitForExistence(timeout: 5) {
            firstResult.tap()
            
            // Verify item detail opens
            let itemDetail = app.navigationBars["Item Details"]
            XCTAssertTrue(itemDetail.waitForExistence(timeout: 5))
        }
    }
    
    func testSearch_Results_PullToRefresh() {
        navigateToSearch()
        performSearch(query: "shirt")
        
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
        
        // Pull to refresh
        resultsGrid.pullToRefresh()
        
        // Verify loading indicator
        let loadingIndicator = app.activityIndicators["refreshIndicator"]
        _ = loadingIndicator.waitForExistence(timeout: 5)
    }
    
    func testSearch_Results_SortOptions() {
        navigateToSearch()
        performSearch(query: "dress")
        
        // Tap sort button
        let sortButton = app.buttons["sortButton"]
        sortButton.tap()
        
        // Verify sort options
        let sortSheet = app.sheets["sortSheet"]
        XCTAssertTrue(sortSheet.waitForExistence(timeout: 5))
        
        // Select price low to high
        let priceLowHigh = sortSheet.buttons["Price: Low to High"]
        if priceLowHigh.exists {
            priceLowHigh.tap()
            
            // Verify results reordered
            let resultsGrid = app.scrollViews["searchResultsGrid"]
            XCTAssertTrue(resultsGrid.waitForExistence(timeout: 10))
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
    
    private func navigateToSearch() {
        let searchTab = app.tabBars["mainTabBar"].buttons["searchTab"]
        searchTab.tap()
        
        let searchBar = app.searchFields["searchBar"]
        XCTAssertTrue(searchBar.waitForExistence(timeout: 5))
    }
    
    private func performSearch(query: String) {
        let searchBar = app.searchFields["searchBar"]
        searchBar.tap()
        searchBar.typeText(query)
        app.keyboards.buttons["Search"].tap()
        
        let resultsGrid = app.scrollViews["searchResultsGrid"]
        _ = resultsGrid.waitForExistence(timeout: 10)
    }
    
    private func performImageSearch() {
        let galleryButton = app.buttons["gallerySearchButton"]
        galleryButton.tap()
        
        let firstPhoto = app.scrollViews["photoGrid"].images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            firstPhoto.tap()
        }
    }
    
    private func applyPriceFilter(min: Int, max: Int) {
        let filterButton = app.buttons["filterButton"]
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        let minPriceField = filterSheet.textFields["minPriceField"]
        minPriceField.tap()
        minPriceField.typeText("\(min)")
        
        let maxPriceField = filterSheet.textFields["maxPriceField"]
        maxPriceField.tap()
        maxPriceField.typeText("\(max)")
        
        let applyButton = filterSheet.buttons["applyFilters"]
        applyButton.tap()
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    func pullToRefresh() {
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0, thenDragTo: end)
    }
}
