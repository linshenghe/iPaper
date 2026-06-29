import Foundation
import Security

final class KeychainService {
    private let service = "com.linshenghe.papertracker"
    private let account = "api_key"

    func saveAPIKey(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        // Delete existing first
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func loadAPIKey() throws -> String? {
        var loadQuery = query
        loadQuery[kSecReturnData as String] = true
        loadQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(loadQuery as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "API key 编码失败"
        case .saveFailed: return "API key 保存到 Keychain 失败"
        case .loadFailed: return "从 Keychain 读取 API key 失败"
        case .deleteFailed: return "从 Keychain 删除 API key 失败"
        }
    }
}
