import Foundation

enum JSONLReader {

    /// Scan all JSONL files under ~/.claude/projects and return deduplicated usage entries.
    static func scan() -> [UsageEntry] {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")

        guard let enumerator = FileManager.default.enumerator(
            at: base,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var seen = Set<String>()
        var entries: [UsageEntry] = []

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]

        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else { continue }
            guard let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .utf8) else { continue }

            for line in text.split(separator: "\n") where line.contains("\"type\":\"assistant\"") || line.contains("\"type\": \"assistant\"") {
                guard let lineData = line.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                      let type = obj["type"] as? String, type == "assistant",
                      let requestId = obj["requestId"] as? String,
                      let message = obj["message"] as? [String: Any],
                      let usage = message["usage"] as? [String: Any],
                      let model = message["model"] as? String,
                      model != "<synthetic>",
                      let ts = obj["timestamp"] as? String,
                      let date = iso.date(from: ts) ?? isoFallback.date(from: ts)
                else { continue }

                guard !seen.contains(requestId) else { continue }
                seen.insert(requestId)

                let entry = UsageEntry(
                    timestamp: date,
                    model: model,
                    inputTokens: usage["input_tokens"] as? Int ?? 0,
                    outputTokens: usage["output_tokens"] as? Int ?? 0,
                    cacheCreationTokens: usage["cache_creation_input_tokens"] as? Int ?? 0,
                    cacheReadTokens: usage["cache_read_input_tokens"] as? Int ?? 0,
                    requestId: requestId
                )
                entries.append(entry)
            }
        }

        return entries.sorted { $0.timestamp < $1.timestamp }
    }
}
