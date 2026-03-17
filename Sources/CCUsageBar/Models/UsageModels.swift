import Foundation

// MARK: - API response models

struct RateLimitResponse: Codable {
    let fiveHour: WindowUtilization?
    let sevenDay: WindowUtilization?
    let sevenDaySonnet: WindowUtilization?
    let sevenDayOpus: WindowUtilization?
    let extraUsage: ExtraUsage?
}

struct WindowUtilization: Codable {
    let utilization: Double   // 0–100
    let resetsAt: String?     // ISO 8601
}

struct ExtraUsage: Codable {
    let isEnabled: Bool
    let monthlyLimit: Int?
    let usedCredits: Double?
    let utilization: Double?
}

// MARK: - Keychain credential metadata

struct CredentialMeta {
    let rateLimitTier: String?
    let subscriptionType: String?
}

// MARK: - App state

struct UsageData {
    var rateLimit: RateLimitResponse?
    var credentialMeta: CredentialMeta?
    var lastUpdated: Date?
    var error: String?
    var isLoading: Bool = false
}
