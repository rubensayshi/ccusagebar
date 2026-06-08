import SwiftUI

struct ProgressBarView: View {
    let fraction: Double
    let timeFraction: Double
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(paceColor(usage: fraction, time: timeFraction))
                    .frame(width: geo.size.width * min(fraction, 1.0))
            }
        }
        .frame(height: height)
    }
}

/// Pace-based color: usage fraction vs time fraction.
func paceColor(usage: Double, time: Double) -> Color {
    guard time > 0.01 else {
        return usage > 0 ? .yellow : .green
    }
    let ratio = usage / time
    switch ratio {
    case ..<0.8: return .green
    case ..<1.0: return .yellow
    case ..<1.3: return .orange
    default:     return .red
    }
}

func paceLabel(usage: Double, time: Double) -> String {
    guard time > 0.01 else {
        return usage > 0 ? "Early usage" : "No usage yet"
    }
    let ratio = usage / time
    switch ratio {
    case ..<0.8: return "Under budget pace"
    case ..<1.0: return "Near budget pace"
    case ..<1.3: return "Over budget pace"
    default:     return "Well over pace"
    }
}

/// Time fraction elapsed in a window, given its reset epoch and total duration.
func timeFraction(resetsAt: Double?, windowSeconds: TimeInterval) -> Double {
    guard let resetsAt else { return 0 }
    let remaining = Date(timeIntervalSince1970: resetsAt).timeIntervalSinceNow
    let elapsed = windowSeconds - remaining
    return min(max(elapsed / windowSeconds, 0), 1)
}

/// Window durations in seconds.
enum WindowDuration {
    static let fiveHour: TimeInterval = 5 * 3600
    static let sevenDay: TimeInterval = 7 * 24 * 3600
}
