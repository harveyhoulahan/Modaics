//
//  KeychainManager.swift
//  Modaics
//
//  Secure keychain storage for sensitive credentials
//

import Foundation
import Security

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.modaics.app"
    private let accessGroup: String? = nil // Set to App Group if using shared keychain
    
    private init() {}
    
    // MARK: - Keys
    enum KeychainKey: String {
        case authToken = "auth_token"
        case refreshToken = "refresh_token"
        case userEmail = "user_email"
        case userPassword = "user_password" // Only if user chooses "Remember Me"
        case biometricEnabled = "biometric_enabled"
    }
    
    // MARK: - Save Data
    @discardableResult
    func save(data: Data, for key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Save String
    @discardableResult
    func save(string: String, for key: KeychainKey) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, for: key)
    }
    
    // MARK: - Retrieve Data
    func retrieveData(for key: KeychainKey) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    // MARK: - Retrieve String
    func retrieveString(for key: KeychainKey) -> String? {
        guard let data = retrieveData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Delete All
    func deleteAll() -> Bool {
        var success = true
        for key in [KeychainKey.authToken, KeychainKey.refreshToken, KeychainKey.userEmail, KeychainKey.userPassword] {
            if !delete(key: key) {
                success = false
            }
        }
        return success
    }
    
    // MARK: - Update
    @discardableResult
    func update(data: Data, for key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // If item doesn't exist, create it
        if status == errSecItemNotFound {
            return save(data: data, for: key)
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods for Auth
    func saveAuthToken(_ token: String) -> Bool {
        return save(string: token, for: .authToken)
    }
    
    func retrieveAuthToken() -> String? {
        return retrieveString(for: .authToken)
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        return save(string: token, for: .refreshToken)
    }
    
    func retrieveRefreshToken() -> String? {
        return retrieveString(for: .refreshToken)
    }
    
    func saveUserEmail(_ email: String) -> Bool {
        return save(string: email, for: .userEmail)
    }
    
    func retrieveUserEmail() -> String? {
        return retrieveString(for: .userEmail)
    }
    
    func saveUserPassword(_ password: String) -> Bool {
        return save(string: password, for: .userPassword)
    }
    
    func retrieveUserPassword() -> String? {
        return retrieveString(for: .userPassword)
    }
    
    func clearAuthData() {
        delete(key: .authToken)
        delete(key: .refreshToken)
        delete(key: .userPassword)
    }
    
    // MARK: - Biometric Auth Settings
    func isBiometricEnabled() -> Bool {
        return retrieveString(for: .biometricEnabled) == "true"
    }
    
    func setBiometricEnabled(_ enabled: Bool) {
        save(string: enabled ? "true" : "false", for: .biometricEnabled)
    }
}
