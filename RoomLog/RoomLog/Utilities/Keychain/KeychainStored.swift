//
//  KeychainStored.swift
//  RoomLog
//
//  Created by 김도연 on 4/7/26.
//

import Foundation
import Security

public actor KeychainTokenStore: TokenStore {
    
    private let service: String = "com.team404.roomlog"
    private let accessTokenKey: String = "accessToken"
    private let refreshTokenKey: String = "refreshToken"
    
    public init() {}
    
    // MARK: - TokenStore Protocol
    
    public func getAccessToken() async -> String? {
        return loadFromKeychain(key: accessTokenKey)
    }
    
    public func getRefreshToken() async -> String? {
        return loadFromKeychain(key: refreshTokenKey)
    }
    
    public func save(accessToken: String, refreshToken: String) async throws {
        try saveToKeychain(key: accessTokenKey, value: accessToken)
        try saveToKeychain(key: refreshTokenKey, value: refreshToken)
    }
    
    public func clear() async throws {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
    }
    
    // MARK: - Private Methods
    
    private func saveToKeychain(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        deleteFromKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Errors

public enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case saveFailed(status: OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "토큰 인코딩 실패"
        case .saveFailed(let status):
            return "Keychain 저장 실패 (status: \(status))"
        }
    }
}
