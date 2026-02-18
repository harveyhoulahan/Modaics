//
//  ItemService.swift
//  Modaics
//
//  Item management service for adding, updating, and managing fashion items
//

import Foundation
import UIKit

// MARK: - Add Item Result

struct AddItemResult {
    let itemId: Int
    let success: Bool
    let message: String
}

// MARK: - Item Service

@MainActor
class ItemService: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = ItemService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var uploadProgress: Double = 0
    @Published private(set) var lastError: APIError?
    @Published private(set) var recentlyAddedItems: [ItemDetail] = []
    
    // MARK: - Private Properties
    
    private let apiClient: APIClient
    private let offlineQueue: OfflineActionQueue
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        self.offlineQueue = OfflineActionQueue()
    }
    
    // MARK: - Add Item
    
    /// Add a new item to the database with full details
    func addItem(
        image: UIImage,
        title: String,
        description: String,
        price: Double? = nil,
        brand: String? = nil,
        category: String? = nil,
        size: String? = nil,
        condition: String? = nil,
        imageUrl: String? = nil
    ) async throws -> AddItemResult {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        // Process image
        uploadProgress = 0.2
        let uploadResult = try await ImageUploader.shared.processImage(image)
        uploadProgress = 0.5
        
        // Get current user ID
        let ownerId = AuthManager.shared.userId
        
        // Build request
        let request = AddItemRequest(
            imageBase64: uploadResult.base64String,
            title: title,
            description: description,
            price: price,
            brand: brand,
            category: category,
            size: size,
            condition: condition,
            ownerId: ownerId,
            source: "modaics",
            imageUrl: imageUrl
        )
        
        uploadProgress = 0.7
        
        do {
            let response: AddItemResponse = try await apiClient.request(
                APIRequest(
                    endpoint: .addItem,
                    body: request,
                    timeout: APIConfiguration.shared.uploadTimeout,
                    requiresAuth: true
                )
            )
            
            uploadProgress = 1.0
            
            let result = AddItemResult(
                itemId: response.itemId,
                success: response.success,
                message: response.message
            )
            
            return result
            
        } catch let error as APIError {
            // If offline, queue for later
            if case .offline = error, APIConfiguration.shared.enableOfflineSupport {
                await offlineQueue.queueAddItem(request: request)
                throw APIError.offline
            }
            
            lastError = error
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }
    
    /// Add item with AI analysis auto-fill
    func addItemWithAIAnalysis(
        image: UIImage,
        userOverrides: ItemOverrides? = nil
    ) async throws -> AddItemResult {
        isLoading = true
        defer { isLoading = false }
        
        // Step 1: Analyze image
        uploadProgress = 0.1
        let analysis = try await AIAnalysisService.shared.analyzeImage(image)
        uploadProgress = 0.5
        
        // Step 2: Apply user overrides
        let title = userOverrides?.title ?? analysis.suggestedName
        let description = userOverrides?.description ?? analysis.suggestedDescription
        let price = userOverrides?.price ?? analysis.suggestedPrice
        let brand = userOverrides?.brand ?? analysis.suggestedBrand
        let category = userOverrides?.category ?? analysis.suggestedCategory.rawValue
        let size = userOverrides?.size ?? analysis.suggestedSize
        let condition = userOverrides?.condition ?? analysis.suggestedCondition.rawValue
        
        uploadProgress = 0.7
        
        // Step 3: Add item
        return try await addItem(
            image: image,
            title: title,
            description: description,
            price: price,
            brand: brand.isEmpty ? nil : brand,
            category: category,
            size: size,
            condition: condition
        )
    }
    
    /// Quick add with minimal parameters
    func quickAdd(
        image: UIImage,
        title: String
    ) async throws -> AddItemResult {
        return try await addItem(
            image: image,
            title: title,
            description: ""
        )
    }
    
    // MARK: - Batch Operations
    
    /// Add multiple items in sequence
    func addItems(
        items: [ItemCreationData]
    ) async throws -> [AddItemResult] {
        var results: [AddItemResult] = []
        
        for (index, item) in items.enumerated() {
            do {
                let result = try await addItem(
                    image: item.image,
                    title: item.title,
                    description: item.description,
                    price: item.price,
                    brand: item.brand,
                    category: item.category,
                    size: item.size,
                    condition: item.condition
                )
                results.append(result)
            } catch {
                // Continue with other items even if one fails
                print("⚠️ Failed to add item \(index): \(error)")
            }
            
            uploadProgress = Double(index + 1) / Double(items.count)
        }
        
        return results
    }
    
    // MARK: - Offline Support
    
    /// Process any queued offline actions
    func processOfflineQueue() async {
        guard APIConfiguration.shared.enableOfflineSupport else { return }
        
        let queuedItems = await offlineQueue.getQueuedAddItems()
        
        for request in queuedItems {
            do {
                let _: AddItemResponse = try await apiClient.request(
                    APIRequest(
                        endpoint: .addItem,
                        body: request,
                        timeout: APIConfiguration.shared.uploadTimeout,
                        requiresAuth: true
                    )
                )
                
                await offlineQueue.removeQueuedAddItem(request: request)
                
            } catch {
                print("⚠️ Failed to process queued item: \(error)")
            }
        }
    }
    
    /// Check if there are pending offline actions
    func hasPendingOfflineActions() async -> Bool {
        await offlineQueue.hasQueuedItems()
    }
    
    /// Get count of pending offline actions
    func pendingOfflineActionsCount() async -> Int {
        await offlineQueue.queuedItemsCount()
    }
    
    // MARK: - Reset
    
    func reset() {
        isLoading = false
        uploadProgress = 0
        lastError = nil
    }
}

// MARK: - Supporting Types

struct ItemCreationData {
    let image: UIImage
    let title: String
    let description: String
    let price: Double?
    let brand: String?
    let category: String?
    let size: String?
    let condition: String?
}

struct ItemOverrides {
    var title: String?
    var description: String?
    var price: Double?
    var brand: String?
    var category: String?
    var size: String?
    var condition: String?
}

// MARK: - Offline Action Queue

private actor OfflineActionQueue {
    private var queuedAddItems: [AddItemRequest] = []
    private let userDefaultsKey = "offline_queued_items"
    
    init() {
        // Load queued items from UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let items = try? JSONDecoder().decode([AddItemRequest].self, from: data) {
            queuedAddItems = items
        }
    }
    
    func queueAddItem(request: AddItemRequest) {
        queuedAddItems.append(request)
        save()
    }
    
    func removeQueuedAddItem(request: AddItemRequest) {
        // Remove by matching key fields
        queuedAddItems.removeAll { item in
            item.title == request.title &&
            item.ownerId == request.ownerId
        }
        save()
    }
    
    func getQueuedAddItems() -> [AddItemRequest] {
        return queuedAddItems
    }
    
    func hasQueuedItems() -> Bool {
        return !queuedAddItems.isEmpty
    }
    
    func queuedItemsCount() -> Int {
        return queuedAddItems.count
    }
    
    func clear() {
        queuedAddItems.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(queuedAddItems) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

// MARK: - Convenience Extensions

extension ItemService {
    
    /// Check if the service is currently uploading
    var isUploading: Bool {
        isLoading && uploadProgress > 0
    }
    
    /// Estimated time remaining for upload
    func estimatedTimeRemaining(currentProgress: Double, elapsedTime: TimeInterval) -> TimeInterval? {
        guard currentProgress > 0 else { return nil }
        let totalEstimatedTime = elapsedTime / currentProgress
        return totalEstimatedTime - elapsedTime
    }
}
