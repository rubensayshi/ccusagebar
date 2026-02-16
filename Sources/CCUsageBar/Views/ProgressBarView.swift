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
/// Shared logic — matches MenuBarIcon.paceColor thresholds.
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
