//
//  ServiceLocator.swift
//  Modaics
//
//  Central service locator for dependency injection and service access
//  Provides a unified interface to all API services
//

import Foundation
import SwiftUI

// MARK: - Service Locator

@MainActor
final class ServiceLocator: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = ServiceLocator()
    
    // MARK: - Services
    
    let configuration: APIConfiguration
    let authManager: AuthManager
    let apiClient: APIClient
    let imageUploader: ImageUploader
    
    // API Services
    let searchService: SearchAPIService
    let analysisService: AIAnalysisService
    let itemService: ItemService
    let sketchbookService: SketchbookAPIService
    
    // Real-time
    let webSocketManager: WebSocketManager
    
    // Utilities
    let logger: APILogger
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = APIConfiguration.shared
        self.authManager = AuthManager.shared
        self.apiClient = APIClient.shared
        self.imageUploader = ImageUploader.shared
        
        self.searchService = SearchAPIService.shared
        self.analysisService = AIAnalysisService.shared
        self.itemService = ItemService.shared
        self.sketchbookService = SketchbookAPIService.shared
        
        self.webSocketManager = WebSocketManager.shared
        self.logger = APILogger.shared
    }
    
    // MARK: - Setup
    
    /// Initialize all services (call at app startup)
    func initialize() async {
        logger.info("🚀 Initializing ServiceLocator...")
        
        // Check authentication state
        if let user = authManager.currentUser {
            logger.auth("User already authenticated: \(user.uid)")
        } else {
            logger.auth("No authenticated user")
        }
        
        // Check API health if in debug mode
        #if DEBUG
        let isHealthy = await searchService.checkHealth()
        logger.info("API Health Check: \(isHealthy ? "✅ Healthy" : "❌ Unhealthy")")
        #endif
        
        // Process any offline queue
        if configuration.enableOfflineSupport {
            await itemService.processOfflineQueue()
        }
        
        logger.info("✅ ServiceLocator initialized")
    }
    
    // MARK: - Environment
    
    /// Switch API environment
    func switchEnvironment(_ environment: APIEnvironment) {
        logger.info("🔄 Switched to \(environment.displayName) environment")
        
        // Clear caches when switching environments
        searchService.clearCache()
        analysisService.clearCache()
        sketchbookService.clearCache()
    }
    
    // MARK: - Reset
    
    /// Reset all services (useful for logout)
    func reset() {
        searchService.clearCache()
        analysisService.reset()
        itemService.reset()
        sketchbookService.clearCache()
        webSocketManager.disconnect()
        
        logger.info("🔄 All services reset")
    }
}

// MARK: - View Extension

extension View {
    /// Inject ServiceLocator into the environment
    func withServices() -> some View {
        self.environmentObject(ServiceLocator.shared)
    }
}

// MARK: - Preview Support

#if DEBUG
extension ServiceLocator {
    
    /// Create a ServiceLocator for previews with mock data
    static func forPreviews() -> ServiceLocator {
        let locator = ServiceLocator.shared
        locator.configuration.useMockData = true
        return locator
    }
}
#endif
