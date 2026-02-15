import Foundation

enum Fmt {
    static func currency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    static func percentage(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    static func timeRemaining(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m left"
        }
        return "\(m)m left"
    }

    static func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    static func burnRate(_ costPerHour: Double) -> String {
        String(format: "$%.2f/hr", costPerHour)
    }
}
