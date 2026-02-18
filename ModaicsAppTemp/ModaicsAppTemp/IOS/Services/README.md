# Modaics iOS Backend Integration

Complete API integration for the Modaics iOS app with the FastAPI backend.

## Overview

This directory contains a comprehensive, production-ready API layer that handles:
- **Authentication** with Firebase Auth Bearer tokens
- **Image search** by text, image, or combined
- **AI analysis** using GPT-4 Vision + CLIP
- **Item management** for adding items to the database
- **Sketchbook** community features
- **Real-time** WebSocket support (when enabled)
- **Offline support** with queued actions
- **Comprehensive logging** for debugging

## Architecture

```
Services/
├── API/
│   ├── APIConfiguration.swift      # Environment & endpoint configuration
│   ├── APIClient.swift              # Base client with retry logic & auth
│   ├── SearchAPIService.swift       # Search endpoints
│   ├── AIAnalysisService.swift      # AI analysis endpoints
│   ├── ItemService.swift            # Item management
│   ├── SketchbookAPIService.swift   # Sketchbook endpoints
│   ├── WebSocketManager.swift       # Real-time connections
│   └── SearchAPIClient+Legacy.swift # Backward compatibility
├── Models/
│   └── APIModels.swift              # All request/response models
├── Auth/
│   └── AuthManager.swift            # Firebase Auth token management
├── Cache/
│   └── (ImageCache.swift)           # Existing image cache
├── Utils/
│   ├── ImageUploader.swift          # Image compression & processing
│   └── APILogger.swift              # Debug logging
├── Mocks/
│   └── MockAPIService.swift         # Mock responses for testing
└── ServiceLocator.swift             # Central dependency injection
```

## Quick Start

### 1. Initialize at App Launch

```swift
import SwiftUI

@main
struct ModaicsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withServices() // Inject all services
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize API services
        Task {
            await ServiceLocator.shared.initialize()
        }
        
        return true
    }
}
```

### 2. Using Services in Views

```swift
struct SearchView: View {
    @EnvironmentObject var locator: ServiceLocator
    @StateObject private var searchService = SearchAPIService.shared
    
    @State private var query = ""
    @State private var results: [SearchResult] = []
    
    var body: some View {
        VStack {
            SearchBar(text: $query, onSearch: performSearch)
            
            if searchService.isLoading {
                ProgressView()
            }
            
            List(results) { result in
                SearchResultCard(result: result)
            }
        }
    }
    
    private func performSearch() {
        Task {
            results = try await searchService.searchByText(query: query)
        }
    }
}
```

### 3. Image Search

```swift
func searchByImage(image: UIImage) async {
    do {
        let results = try await SearchAPIService.shared.searchByImage(image)
        // Handle results
    } catch let error as APIError {
        // Handle specific API errors
        handleError(error)
    }
}
```

### 4. AI Analysis

```swift
func analyzeItem(image: UIImage) async {
    do {
        let result = try await AIAnalysisService.shared.analyzeImage(image)
        
        print("Detected: \(result.suggestedName)")
        print("Brand: \(result.suggestedBrand)")
        print("Category: \(result.suggestedCategory)")
        print("Confidence: \(result.confidence)")
        
    } catch {
        print("Analysis failed: \(error)")
    }
}
```

### 5. Add Item with AI

```swift
func addNewItem(image: UIImage) async {
    do {
        let result = try await ItemService.shared.addItemWithAIAnalysis(
            image: image,
            userOverrides: ItemOverrides(
                price: 99.99,
                condition: .excellent
            )
        )
        
        print("Item added with ID: \(result.itemId)")
        
    } catch APIError.offline {
        // Item queued for when online
        showOfflineMessage()
    } catch {
        showError(error)
    }
}
```

### 6. Sketchbook Operations

```swift
func loadSketchbook(brandId: String) async {
    do {
        let sketchbook = try await SketchbookAPIService.shared
            .getSketchbook(forBrand: brandId)
        
        let posts = try await SketchbookAPIService.shared
            .getPosts(sketchbookId: sketchbook.id)
        
    } catch {
        print("Failed to load: \(error)")
    }
}

func createPollPost(sketchbookId: Int) async throws {
    try await SketchbookAPIService.shared.createPost(
        sketchbookId: sketchbookId,
        title: "What's your favorite color?",
        postType: .poll,
        pollQuestion: "Choose your favorite:",
        pollOptions: [
            PollOption(id: "1", label: "Blue", votes: 0),
            PollOption(id: "2", label: "Red", votes: 0),
            PollOption(id: "3", label: "Green", votes: 0)
        ],
        pollClosesAt: Date().addingTimeInterval(86400)
    )
}
```

## Environment Configuration

### Switch Environments

```swift
// In Settings or Debug menu
ServiceLocator.shared.switchEnvironment(.production)

// Or directly
APIConfiguration.shared.environment = .staging
```

### Environment Options

- `.development` - Local server (localhost for simulator, device IP for physical device)
- `.staging` - Staging server (https://api-staging.modaics.com)
- `.production` - Production server (https://api.modaics.com)

## Error Handling

All services throw `APIError` which provides detailed error information:

```swift
do {
    let results = try await searchService.searchByText(query: "shoes")
} catch APIError.unauthorized {
    // Redirect to login
} catch APIError.offline {
    // Show offline UI
} catch APIError.rateLimited {
    // Show retry after message
} catch let APIError.serverError(message, code) {
    // Show server error with details
} catch {
    // Handle unknown errors
}
```

### Error Types

- `invalidURL` - URL construction failed
- `networkError` - Network connectivity issues
- `invalidResponse` - Malformed server response
- `decodingError` - JSON parsing failed
- `serverError` - Server returned error status
- `unauthorized` - 401, token expired or invalid
- `forbidden` - 403, insufficient permissions
- `notFound` - 404, resource doesn't exist
- `rateLimited` - 429, too many requests
- `requestTimeout` - Request took too long
- `offline` - No internet connection
- `cancelled` - Request was cancelled

## Authentication

Authentication is handled automatically using Firebase Auth:

```swift
// Sign in (Firebase)
try await Auth.auth().signIn(withEmail: email, password: password)

// The APIClient automatically attaches Bearer tokens to requests

// Sign out
try await AuthManager.shared.signOut()
```

## Caching

Each service has built-in caching:

```swift
// Cache is used by default
let results = try await searchService.searchByText(query: "shoes")

// Skip cache for fresh data
let fresh = try await searchService.searchByText(query: "shoes", useCache: false)

// Clear caches
searchService.clearCache()
analysisService.clearCache()
sketchbookService.clearCache()
```

## Image Processing

Images are automatically compressed and resized before upload:

```swift
// Process image for upload
let result = try await ImageUploader.shared.processImage(image)

print("Original: \(result.originalSize) bytes")
print("Compressed: \(result.compressedSize) bytes")
print("Reduction: \(result.sizeReductionPercentage)%")

// Access base64 for manual requests
let base64 = result.base64String
```

## Offline Support

When offline, certain actions are queued:

```swift
// Item will be queued if offline
try await itemService.addItem(image: image, title: title, ...)

// Check pending actions
let hasPending = await itemService.hasPendingOfflineActions()
let count = await itemService.pendingOfflineActionsCount()

// Process queue when back online
await itemService.processOfflineQueue()
```

## Debug Logging

Comprehensive logging is available:

```swift
// Log levels
APILogger.shared.minimumLogLevel = .verbose  // Debug
APILogger.shared.minimumLogLevel = .error    // Production

// Log to file
APILogger.shared.logToFile = true

// Export logs for debugging
if let logURL = APILogger.shared.exportLogs() {
    // Share log file
}

// Clear logs
APILogger.shared.clearLogs()
```

## Mock Mode

For testing without a backend:

```swift
// Enable mock mode
APIConfiguration.shared.useMockData = true

// Or use the convenience method
SearchAPIService.shared.enableMockMode()

// Configure mock behavior
MockAPIService.shared.shouldSimulateNetworkDelay = true
MockAPIService.shared.simulatedDelay = 0.5
MockAPIService.shared.shouldSimulateErrors = true
MockAPIService.shared.errorRate = 0.1
```

## WebSocket (Real-time)

When WebSocket endpoints are ready:

```swift
// Connect
await WebSocketManager.shared.connect()

// Subscribe to updates
WebSocketManager.shared.subscribeToSketchbook(sketchbookId)

// Listen for events
WebSocketManager.shared.eventPublisher
    .sink { event in
        switch event {
        case .message(let message):
            handleMessage(message)
        case .connected, .disconnected, .error:
            break
        }
    }
    .store(in: &cancellables)

// Disconnect
WebSocketManager.shared.disconnect()
```

## Service Locator Pattern

Access all services through `ServiceLocator`:

```swift
let locator = ServiceLocator.shared

// Services
locator.searchService
locator.analysisService
locator.itemService
locator.sketchbookService
locator.authManager
locator.apiClient
locator.imageUploader
locator.webSocketManager
locator.logger

// Configuration
locator.configuration.environment
locator.configuration.baseURL
```

## Testing

### Unit Tests

```swift
func testSearchByText() async throws {
    // Given
    let mockService = MockAPIService.shared
    mockService.shouldSimulateErrors = false
    
    // When
    let results = try await mockService.mockSearchByText(query: "shoes")
    
    // Then
    XCTAssertFalse(results.isEmpty)
}
```

### UI Tests with Mock Data

```swift
// In setUp
APIConfiguration.shared.useMockData = true

// Run tests...
```

## Migration from Old API Client

The old `SearchAPIClient` is still available for backward compatibility:

```swift
// Old way (still works)
let client = SearchAPIClient()
let results = try await client.searchByText(query: "shoes")

// New way (recommended)
let results = try await SearchAPIService.shared.searchByText(query: "shoes")
```

## Best Practices

1. **Always use `@MainActor`** for UI updates
2. **Handle errors gracefully** - show appropriate UI for each error type
3. **Use caching** - improves performance and reduces API calls
4. **Monitor network** - check reachability before requests
5. **Log extensively** in debug builds for easier debugging
6. **Use mock mode** for UI development without backend

## API Endpoints

### Search
- `POST /search_by_text` - Text-only search
- `POST /search_by_image` - Image-only search
- `POST /search_combined` - Image + text search

### AI Analysis
- `POST /analyze_image` - Analyze image with AI
- `POST /generate_description` - Generate product description

### Items
- `POST /add_item` - Add new item to database

### Sketchbook
- `GET /sketchbook/brand/{brand_id}` - Get sketchbook
- `PUT /sketchbook/{id}/settings` - Update settings
- `GET /sketchbook/{id}/posts` - Get posts
- `POST /sketchbook/{id}/posts` - Create post
- `DELETE /sketchbook/posts/{post_id}` - Delete post
- `GET /sketchbook/{id}/membership/{user_id}` - Check membership
- `POST /sketchbook/{id}/membership` - Request membership
- `POST /sketchbook/posts/{post_id}/vote` - Vote in poll
- `POST /sketchbook/posts/{post_id}/react` - Add reaction
- `GET /community/sketchbook-feed` - Community feed

## Support

For issues or questions about the API integration, refer to:
- `APILogger.shared` logs for debugging
- Mock mode for testing without backend
- Backend documentation at `/docs` when server is running
