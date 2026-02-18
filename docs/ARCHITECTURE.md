# Modaics iOS Architecture Guide

Complete guide to the iOS app's architecture, patterns, and organization.

---

## 🏗️ Architecture Overview

Modaics iOS uses **MVVM (Model-View-ViewModel)** architecture with **Clean Architecture** principles and **Dependency Injection**.

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    Views    │  │  ViewModels │  │   State Management  │  │
│  │  (SwiftUI)  │← │   (Logic)   │← │   (@Published)      │  │
│  └──────┬──────┘  └──────┬──────┘  └─────────────────────┘  │
└─────────┼────────────────┼──────────────────────────────────┘
          │                │
          │         ┌──────┴──────┐
          │         ▼             ▼
          │  ┌─────────────┐  ┌─────────────┐
          │  │  Use Cases  │  │   Models    │
          │  │  (Business) │  │  (Entities) │
          │  └──────┬──────┘  └─────────────┘
          │         │
          ▼         ▼
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │  APIClient  │  │AuthManager  │  │ PaymentSvc  │          │
│  │  (Backend)  │  │ (Firebase)  │  │   (Stripe)  │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Folder Structure

```
IOS/
├── App/
│   ├── ModaicsApp.swift          # App entry point
│   ├── ContentView.swift         # Root view (legacy)
│   └── RootView.swift            # Auth state routing
│
├── Views/                        # SwiftUI Views
│   ├── Auth/                     # Authentication flow
│   │   ├── SplashView.swift
│   │   ├── EnhancedLoginView.swift
│   │   ├── SignUpView.swift
│   │   ├── PasswordResetView.swift
│   │   └── TransitionView.swift
│   │
│   ├── Tab/                      # Main tab views
│   │   ├── HomeView.swift
│   │   ├── TabViews.swift
│   │   └── ProfileView.swift
│   │
│   ├── Item/                     # Item-related views
│   │   ├── EnhancedDiscoverView.swift
│   │   └── Item.swift
│   │
│   ├── Create/                   # Listing creation
│   │   ├── UnifiedCreateView.swift
│   │   └── SmartCreateView.swift
│   │
│   ├── Payment/                  # Payment flows
│   │   ├── PaymentButton.swift
│   │   ├── PaymentConfirmationView.swift
│   │   ├── TransactionHistoryView.swift
│   │   ├── PurchaseFlowView.swift
│   │   ├── SubscriptionFlowView.swift
│   │   └── P2PTransferView.swift
│   │
│   ├── Sketchbook/               # Brand sketchbooks
│   │   ├── Brand/
│   │   │   ├── BrandSketchbookScreen.swift
│   │   │   ├── SketchbookPostEditorView.swift
│   │   │   └── SketchbookSettingsView.swift
│   │   ├── Consumer/
│   │   │   ├── CommunitySketchbookFeedView.swift
│   │   │   └── BrandSketchbookPublicView.swift
│   │   └── Components/
│   │       ├── SketchbookHeaderView.swift
│   │       ├── SketchbookPostCardView.swift
│   │       └── SketchbookPollView.swift
│   │
│   ├── Search/                   # Search & filters
│   │   └── ModernFiltersView.swift
│   │
│   ├── Community/                # Community features
│   │   └── CommunityFeedView.swift
│   │
│   ├── FashionModels/            # Fashion models showcase
│   │   ├── CommunityPost.swift
│   │   ├── CommunityData.swift
│   │   ├── RealListings.swift
│   │   └── FashionViewModel.swift
│   │
│   ├── Leaderboard/              # Sustainability leaderboard
│   │   └── SustainabilityLeaderboard.swift
│   │
│   └── Settings/                 # App settings
│       └── SettingsView.swift
│
├── ViewModels/                   # MVVM ViewModels
│   ├── AuthViewModel.swift       # Auth state management
│   └── Sketchbook/
│       ├── SketchbookViewModel.swift
│       ├── BrandSketchbookViewModel.swift
│       └── ConsumerSketchbookViewModel.swift
│
├── Services/                     # Business logic services
│   ├── API/                      # API clients
│   │   ├── APIClient.swift
│   │   ├── APIConfiguration.swift
│   │   ├── SearchAPIService.swift
│   │   ├── SketchbookAPIService.swift
│   │   ├── ItemService.swift
│   │   ├── AIAnalysisService.swift
│   │   ├── WebSocketManager.swift
│   │   └── SearchAPIClient+Legacy.swift
│   │
│   ├── Auth/                     # Authentication
│   │   └── AuthManager.swift
│   │
│   ├── Sketchbook/               # Sketchbook service
│   │   └── SketchbookService.swift
│   │
│   ├── Models/                   # Service models
│   │   └── APIModels.swift
│   │
│   ├── Utils/                    # Utilities
│   │   ├── APILogger.swift
│   │   └── ImageUploader.swift
│   │
│   └── Mocks/                    # Mock services for testing
│       └── MockAPIService.swift
│
├── Models/                       # Domain models
│   └── User.swift                # User model (Firebase)
│
├── DesignSystem/                 # Theme & design system
│   └── NewTheme.swift            # Dark green Porsche theme
│
├── Shared/                       # Reusable components
│   ├── ShimmerView.swift
│   ├── SkeletonLoadingView.swift
│   ├── ToastView.swift
│   ├── PullToRefresh.swift
│   ├── ImageCache.swift
│   ├── PremiumImageLoader.swift
│   ├── EnhancedItemCard.swift
│   ├── BrandAssets.swift
│   └── AIAnalysisService.swift
│
├── Recommendations/              # ML recommendations
│   └── RecommendationManager.swift
│
└── New/                          # Experimental/new features
    └── SmartCreateView.swift
```

---

## 🔄 MVVM Pattern

### Overview

Each screen follows the MVVM pattern:

```swift
// MARK: - Model
struct Item: Identifiable, Codable {
    let id: String
    let title: String
    let price: Double
    // ...
}

// MARK: - ViewModel
@MainActor
class ItemDetailViewModel: ObservableObject {
    @Published var item: Item?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let itemService: ItemServiceProtocol
    
    init(itemService: ItemServiceProtocol = ItemService()) {
        self.itemService = itemService
    }
    
    func loadItem(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            item = try await itemService.fetchItem(id: id)
        } catch {
            self.error = error
        }
    }
}

// MARK: - View
struct ItemDetailView: View {
    @StateObject private var viewModel = ItemDetailViewModel()
    let itemId: String
    
    var body: some View {
        Group {
            if let item = viewModel.item {
                ItemContentView(item: item)
            } else if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error)
            }
        }
        .task {
            await viewModel.loadItem(id: itemId)
        }
    }
}
```

### State Flow

```
User Action → View → ViewModel → Service → API → Database
                ↑       ↓
                └── State Update ←── Response
```

---

## 🧭 Navigation

### Navigation Architecture

Modaics uses **NavigationStack** (iOS 16+) with programmatic navigation:

```swift
// MARK: - Navigation Router
@MainActor
class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
}

// MARK: - Routes
enum Route: Hashable {
    case itemDetail(itemId: String)
    case brandProfile(brandId: String)
    case sketchbook(brandId: String)
    case checkout(item: Item)
    case paymentConfirmation(transactionId: String)
}

// MARK: - Root Navigation View
struct RootNavigationView: View {
    @StateObject private var router = NavigationRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .itemDetail(let itemId):
                        ItemDetailView(itemId: itemId)
                    case .brandProfile(let brandId):
                        BrandProfileView(brandId: brandId)
                    case .sketchbook(let brandId):
                        BrandSketchbookScreen(brandId: brandId)
                    case .checkout(let item):
                        PurchaseFlowView(item: item)
                    case .paymentConfirmation(let transactionId):
                        PaymentConfirmationView(transactionId: transactionId)
                    }
                }
        }
        .environmentObject(router)
    }
}
```

### Tab Navigation

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(0)
            
            CommunityFeedView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }
                .tag(1)
            
            UnifiedCreateView()
                .tabItem {
                    Label("Sell", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            TransactionHistoryView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.bifold")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
    }
}
```

### Deep Linking

```swift
// MARK: - Deep Link Handler
class DeepLinkHandler {
    static func handle(url: URL, router: NavigationRouter) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return false
        }
        
        switch host {
        case "item":
            if let itemId = components.pathComponents.last {
                router.navigate(to: .itemDetail(itemId: itemId))
                return true
            }
            
        case "brand":
            if let brandId = components.pathComponents.last {
                router.navigate(to: .sketchbook(brandId: brandId))
                return true
            }
            
        case "payment":
            if let transactionId = components.queryItems?
                .first(where: { $0.name == "transaction_id" })?.value {
                router.navigate(to: .paymentConfirmation(transactionId: transactionId))
                return true
            }
            
        default:
            return false
        }
        
        return false
    }
}
```

---

## 📦 State Management

### Auth State (Global)

```swift
@MainActor
class AuthViewModel: ObservableObject {
    enum AuthState {
        case unknown
        case loading
        case authenticated(User)
        case unauthenticated
        case error(AuthError)
    }
    
    @Published var state: AuthState = .unknown
    @Published var currentUser: User?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().authStateDidChangePublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] firebaseUser in
                if let firebaseUser = firebaseUser {
                    Task {
                        await self?.fetchUserProfile(firebaseUser: firebaseUser)
                    }
                } else {
                    self?.state = .unauthenticated
                    self?.currentUser = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) async {
        state = .loading
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await fetchUserProfile(firebaseUser: result.user)
        } catch {
            state = .error(AuthError(from: error))
        }
    }
    
    private func fetchUserProfile(firebaseUser: FirebaseAuth.User) async {
        do {
            let user = try await Firestore.firestore()
                .collection("users")
                .document(firebaseUser.uid)
                .getDocument()
                .data(as: User.self)
            
            self.currentUser = user
            self.state = .authenticated(user)
        } catch {
            self.state = .error(.profileLoadFailed)
        }
    }
}
```

### Local State (Screen-Level)

```swift
@MainActor
class ItemCreateViewModel: ObservableObject {
    // Input State
    @Published var selectedImages: [UIImage] = []
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var price: String = ""
    @Published var selectedCategory: Category?
    @Published var selectedCondition: Condition = .good
    
    // Computed State
    var isValid: Bool {
        !title.isEmpty &&
        !price.isEmpty &&
        selectedCategory != nil &&
        !selectedImages.isEmpty
    }
    
    // UI State
    @Published var isAnalyzing = false
    @Published var isUploading = false
    @Published var analysisResult: AIAnalysisResult?
    @Published var error: ItemCreateError?
    
    // Actions
    func analyzeImages() async {
        guard let firstImage = selectedImages.first else { return }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let result = try await AIAnalysisService.shared.analyze(image: firstImage)
            analysisResult = result
            
            // Auto-fill form
            title = result.detectedItem
            description = result.description
            price = String(format: "%.2f", result.estimatedPrice ?? 0)
        } catch {
            self.error = .analysisFailed
        }
    }
    
    func createListing() async throws {
        guard isValid else { throw ItemCreateError.invalidForm }
        
        isUploading = true
        defer { isUploading = false }
        
        // Upload images
        let imageUrls = try await uploadImages()
        
        // Create item
        let item = Item(
            title: title,
            description: description,
            price: Double(price) ?? 0,
            // ...
        )
        
        try await ItemService.shared.createItem(item, imageUrls: imageUrls)
    }
}
```

### Environment Values

```swift
// MARK: - Environment Keys
private struct AuthViewModelKey: EnvironmentKey {
    static let defaultValue = AuthViewModel()
}

private struct PaymentServiceKey: EnvironmentKey {
    static let defaultValue = PaymentService()
}

extension EnvironmentValues {
    var authViewModel: AuthViewModel {
        get { self[AuthViewModelKey.self] }
        set { self[AuthViewModelKey.self] = newValue }
    }
    
    var paymentService: PaymentService {
        get { self[PaymentServiceKey.self] }
        set { self[PaymentServiceKey.self] = newValue }
    }
}

// Usage in Views
struct SomeView: View {
    @Environment(\.authViewModel) var authViewModel
    @Environment(\.paymentService) var paymentService
    
    var body: some View {
        // Use services...
    }
}
```

---

## 🔌 Dependency Injection

### Service Locator Pattern

```swift
// MARK: - Service Locator
class ServiceLocator {
    static let shared = ServiceLocator()
    
    private var services: [String: Any] = [:]
    
    func register<T>(_ service: T, for type: T.Type = T.self) {
        let key = String(describing: type)
        services[key] = service
    }
    
    func resolve<T>(_ type: T.Type = T.self) -> T {
        let key = String(describing: type)
        guard let service = services[key] as? T else {
            fatalError("Service \(key) not registered")
        }
        return service
    }
}

// MARK: - Setup
extension ServiceLocator {
    func setupServices() {
        register(APIClient() as APIClientProtocol)
        register(ItemService(apiClient: resolve()) as ItemServiceProtocol)
        register(PaymentService() as PaymentServiceProtocol)
        register(AuthManager() as AuthManagerProtocol)
    }
}

// MARK: - Usage in ViewModels
class ItemDetailViewModel: ObservableObject {
    private let itemService: ItemServiceProtocol
    private let paymentService: PaymentServiceProtocol
    
    init(
        itemService: ItemServiceProtocol = ServiceLocator.shared.resolve(),
        paymentService: PaymentServiceProtocol = ServiceLocator.shared.resolve()
    ) {
        self.itemService = itemService
        self.paymentService = paymentService
    }
}
```

### Protocol-Oriented Design

```swift
// MARK: - Protocols
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func upload(data: Data, to url: URL) async throws -> URL
}

protocol ItemServiceProtocol {
    func fetchItem(id: String) async throws -> Item
    func fetchItems(category: String?, limit: Int) async throws -> [Item]
    func createItem(_ item: Item, imageUrls: [URL]) async throws
    func search(query: String) async throws -> [Item]
}

protocol PaymentServiceProtocol {
    func createPaymentIntent(for item: Item) async throws -> PaymentIntent
    func processPayment(_ intent: PaymentIntent) async throws -> Transaction
    func fetchTransactions() async throws -> [Transaction]
}

// MARK: - Implementations
class APIClient: APIClientProtocol {
    // Implementation
}

class ItemService: ItemServiceProtocol {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // Implementation
}
```

---

## 🎨 Design System Integration

### Theme Usage

```swift
struct ExampleView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient.forestBackground
                .ignoresSafeArea()
            
            VStack(spacing: ForestSpacing.large) {
                // Text
                Text("Title")
                    .font(.forestDisplay(32))
                    .foregroundStyle(.luxeGoldGradient)
                
                Text("Body text")
                    .font(.forestBody(16))
                    .foregroundColor(.sageWhite)
                
                // Card
                VStack {
                    Text("Card Content")
                }
                .padding(ForestSpacing.large)
                .forestCard()
                
                // Button
                Button("Action") {}
                    .buttonStyle(ForestPrimaryButtonStyle())
            }
            .padding(ForestSpacing.xlarge)
        }
    }
}
```

---

## 🧪 Testing

### ViewModel Testing

```swift
import XCTest
@testable import Modaics

@MainActor
final class AuthViewModelTests: XCTestCase {
    var sut: AuthViewModel!
    var mockAuthManager: MockAuthManager!
    
    override func setUp() {
        super.setUp()
        mockAuthManager = MockAuthManager()
        sut = AuthViewModel(authManager: mockAuthManager)
    }
    
    override func tearDown() {
        sut = nil
        mockAuthManager = nil
        super.tearDown()
    }
    
    func testSignInSuccess() async {
        // Given
        let expectedUser = User(id: "123", email: "test@example.com")
        mockAuthManager.signInResult = .success(expectedUser)
        
        // When
        await sut.signIn(email: "test@example.com", password: "password")
        
        // Then
        XCTAssertEqual(sut.state, .authenticated(expectedUser))
    }
    
    func testSignInFailure() async {
        // Given
        mockAuthManager.signInResult = .failure(.invalidCredentials)
        
        // When
        await sut.signIn(email: "test@example.com", password: "wrong")
        
        // Then
        XCTAssertEqual(sut.state, .error(.invalidCredentials))
    }
}
```

### View Testing

```swift
import XCTest
import SwiftUI
import ViewInspector
@testable import Modaics

@MainActor
final class LoginViewTests: XCTestCase {
    func testLoginButtonDisabledWhenFieldsEmpty() throws {
        // Given
        let viewModel = AuthViewModel(authManager: MockAuthManager())
        let view = EnhancedLoginView().environmentObject(viewModel)
        
        // When
        let button = try view.inspect().find(button: "Sign In")
        
        // Then
        XCTAssertTrue(try button.isDisabled())
    }
}
```

---

## 📱 Best Practices

### 1. Always use @MainActor for ViewModels

```swift
@MainActor
class MyViewModel: ObservableObject {
    // All UI updates happen on main thread
}
```

### 2. Use task modifiers for async work

```swift
struct MyView: View {
    @StateObject var viewModel = MyViewModel()
    
    var body: some View {
        ContentView()
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
    }
}
```

### 3. Handle errors gracefully

```swift
enum ViewState<T> {
    case loading
    case loaded(T)
    case error(Error)
}

struct ContentView: View {
    @State private var state: ViewState<Item> = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .loaded(let item):
                ItemView(item: item)
            case .error(let error):
                ErrorView(error: error, retry: loadData)
            }
        }
    }
}
```

### 4. Use proper access control

```swift
class ViewModel: ObservableObject {
    // Public for View binding
    @Published var items: [Item] = []
    @Published var isLoading = false
    
    // Private to ViewModel
    private let service: ItemService
    private var cancellables = Set<AnyCancellable>()
    
    // Internal for testing
    internal func processItems(_ raw: [RawItem]) -> [Item] {
        // Implementation
    }
}
```

---

## 📚 Additional Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [MVVM Pattern Guide](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Swift Concurrency](https://developer.apple.com/documentation/swift/swift-standard-library/concurrency)

---

**Last Updated**: February 2025  
**iOS Version Target**: iOS 17.0+
