import Foundation

enum Fmt {
    static func utilization(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    static func countdown(until resetsAt: String?) -> String {
        guard let resetsAt, let date = parseISO8601(resetsAt) else { return "" }
        let remaining = date.timeIntervalSinceNow
        guard remaining > 0 else { return "Resetting…" }
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m left" }
        return "\(m)m left"
    }

    static func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private static func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
