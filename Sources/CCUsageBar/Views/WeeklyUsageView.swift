import SwiftUI

struct WeeklyUsageView: View {
    let cost: Double
    let limit: Double

    private var fraction: Double { cost / limit }

    /// Mon 00:00 = 0, Sun 23:59 = ~1
    private var timeFraction: Double {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun..7=Sat
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let daysSinceMonday = (weekday + 5) % 7
        let minutesSinceMonday = Double(daysSinceMonday * 1440 + hour * 60 + minute)
        return minutesSinceMonday / (7 * 1440)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This Week")
                .font(.headline)

            HStack {
                Text("\(Fmt.currency(cost)) / \(Fmt.currency(limit))")
                    .font(.system(.body, design: .monospaced))
                Spacer()
                Text(Fmt.percentage(fraction))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(paceColor(usage: fraction, time: timeFraction))
            }

            ProgressBarView(fraction: fraction, timeFraction: timeFraction)

            HStack {
                Text(paceLabel(usage: fraction, time: timeFraction))
                    .font(.caption)
                    .foregroundStyle(paceColor(usage: fraction, time: timeFraction))
                Spacer()
                if timeFraction > 0.01 {
                    let hoursElapsed = timeFraction * 7 * 24
                    Text("Burn: \(Fmt.burnRate(cost / hoursElapsed))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Proj: \(Fmt.currency(cost / timeFraction))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
