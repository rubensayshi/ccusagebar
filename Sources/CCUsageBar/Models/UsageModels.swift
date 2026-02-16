import Foundation

// MARK: - Raw usage entry from JSONL

struct UsageEntry {
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let requestId: String
}

// MARK: - Blocks response

struct BlocksResponse: Codable {
    let blocks: [Block]
}

struct Block: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let isActive: Bool
    let isGap: Bool
    let totalTokens: Int
    let costUSD: Double
    let models: [String]
    let burnRate: BurnRate?
    let projection: Projection?
}

struct BurnRate: Codable {
    let tokensPerMinute: Double
    let costPerHour: Double
}

struct Projection: Codable {
    let totalTokens: Int
    let totalCost: Double
    let remainingMinutes: Int
}

// MARK: - Daily response

struct DailyResponse: Codable {
    let daily: [DailyEntry]
    let totals: DailyTotals
}

struct DailyEntry: Codable {
    let date: String
    let totalTokens: Int
    let totalCost: Double
}

struct DailyTotals: Codable {
    let totalCost: Double
    let totalTokens: Int
}

// MARK: - Weekly response

struct WeeklyResponse: Codable {
    let weekly: [WeeklyEntry]
    let totals: WeeklyTotals
}

struct WeeklyEntry: Codable {
    let week: String
    let totalTokens: Int
    let totalCost: Double
}

struct WeeklyTotals: Codable {
    let totalCost: Double
    let totalTokens: Int
}

// MARK: - App state

struct UsageData {
    var activeBlock: Block?
    var dailyCost: Double = 0
    var weeklyCost: Double = 0
    var lastUpdated: Date?
    var error: String?
    var isLoading: Bool = false
}
