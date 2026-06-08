import Foundation

enum Fmt {
    static func utilization(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    static func countdown(until resetsAt: Double?) -> String {
        guard let resetsAt else { return "" }
        let remaining = Date(timeIntervalSince1970: resetsAt).timeIntervalSinceNow
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
}
