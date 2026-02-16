import SwiftUI

struct WeeklyUsageView: View {
    let cost: Double
    let limit: Double

    @AppStorage("weeklyResetDay") private var resetDay: Int = 4
    @AppStorage("weeklyResetHour") private var resetHour: Int = 9

    private var fraction: Double { cost / limit }

    private var timeFraction: Double {
        weeklyTimeFraction(resetDay: resetDay, resetHour: resetHour)
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
