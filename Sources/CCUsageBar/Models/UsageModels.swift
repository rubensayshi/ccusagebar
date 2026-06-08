import Foundation

// MARK: - Usage status file (~/.claude/usage-status.json)
//
// Written by scripts/statusline-usage.sh from Claude Code's statusLine
// `rate_limits` payload. resets_at is a Unix epoch (seconds).

struct RateLimitResponse: Codable {
    let fiveHour: WindowUtilization?
    let sevenDay: WindowUtilization?
}

struct WindowUtilization: Codable {
    let utilization: Double    // 0–100
    let resetsAt: Double?      // Unix epoch seconds
}

// MARK: - App state

struct UsageData {
    var rateLimit: RateLimitResponse?
    var lastUpdated: Date?
    var error: String?
    var isLoading: Bool = false
}
