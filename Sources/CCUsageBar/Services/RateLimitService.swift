import Foundation
import Security

actor RateLimitService {
    static let shared = RateLimitService()

    private var cachedToken: String?
    private var lastKeychainFailure: Date?
    private let keychainCooldown: TimeInterval = 300

    // MARK: - Keychain JSON shape

    private struct KeychainBlob: Codable {
        let claudeAiOauth: OAuthData?
        let rateLimitTier: String?
        let subscriptionType: String?

        struct OAuthData: Codable {
            let accessToken: String?
        }
    }

    // MARK: - Public

    func fetchUsage() async -> RateLimitResponse? {
        guard let token = readAccessToken() else { return nil }
        return await request(token: token)
    }

    func readCredentialMeta() -> CredentialMeta? {
        guard let blob = readKeychainBlob() else { return nil }
        return CredentialMeta(rateLimitTier: blob.rateLimitTier,
                              subscriptionType: blob.subscriptionType)
    }

    // MARK: - Network

    private func request(token: String, isRetry: Bool = false) async -> RateLimitResponse? {
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)

            if let http = response as? HTTPURLResponse, http.statusCode == 401, !isRetry {
                cachedToken = nil
                if let fresh = readAccessToken() {
                    return await request(token: fresh, isRetry: true)
                }
                return nil
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(RateLimitResponse.self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Keychain

    private func readAccessToken() -> String? {
        if let cached = cachedToken { return cached }
        guard let blob = readKeychainBlob() else { return nil }
        cachedToken = blob.claudeAiOauth?.accessToken
        return cachedToken
    }

    private func readKeychainBlob() -> KeychainBlob? {
        if let last = lastKeychainFailure,
           Date().timeIntervalSince(last) < keychainCooldown {
            return nil
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            lastKeychainFailure = Date()
            return nil
        }

        lastKeychainFailure = nil
        return try? JSONDecoder().decode(KeychainBlob.self, from: data)
    }
}
