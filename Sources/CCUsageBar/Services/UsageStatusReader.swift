import Foundation

/// Reads the usage status file written by scripts/statusline-usage.sh.
enum UsageStatusReader {
    static let fileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/usage-status.json")

    struct Result {
        let rateLimit: RateLimitResponse?
        let updated: Date?
        let error: String?
    }

    static func read() -> Result {
        guard let data = try? Data(contentsOf: fileURL) else {
            return Result(rateLimit: nil, updated: nil,
                          error: "No usage data yet — start a Claude Code session")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let rl = try? decoder.decode(RateLimitResponse.self, from: data) else {
            return Result(rateLimit: nil, updated: nil, error: "Could not parse usage data")
        }

        var updated: Date?
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ts = obj["updated"] as? Double {
            updated = Date(timeIntervalSince1970: ts)
        }

        return Result(rateLimit: rl, updated: updated, error: nil)
    }
}
