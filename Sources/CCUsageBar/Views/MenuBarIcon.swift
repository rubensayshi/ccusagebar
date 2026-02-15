import SwiftUI
import AppKit

struct MenuBarIcon: View {
    let blockCost: Double
    let blockLimit: Double
    let blockRemainingMinutes: Int?
    let weeklyCost: Double
    let weeklyLimit: Double

    private let blockTotalMinutes: Double = 300 // 5h window

    private var blockFraction: Double {
        guard blockLimit > 0 else { return 0 }
        return min(blockCost / blockLimit, 1.0)
    }

    private var weeklyFraction: Double {
        guard weeklyLimit > 0 else { return 0 }
        return min(weeklyCost / weeklyLimit, 1.0)
    }

    /// How far through the 5h block window (0..1)
    private var blockTimeFraction: Double {
        guard let remaining = blockRemainingMinutes else { return 0 }
        let elapsed = blockTotalMinutes - Double(remaining)
        return min(max(elapsed / blockTotalMinutes, 0), 1)
    }

    /// How far through the week (0..1), Mon 00:00 = 0, Sun 23:59 = ~1
    private var weeklyTimeFraction: Double {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun..7=Sat
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        // Convert to Monday-based: Mon=0..Sun=6
        let daysSinceMonday = (weekday + 5) % 7
        let minutesSinceMonday = Double(daysSinceMonday * 1440 + hour * 60 + minute)
        return minutesSinceMonday / (7 * 1440)
    }

    var body: some View {
        Image(nsImage: renderGauge())
    }

    private func renderGauge() -> NSImage {
        let size: CGFloat = 22
        let outerWidth: CGFloat = 3.0
        let innerWidth: CGFloat = 2.0
        let gap: CGFloat = 1.0
        let outerInset = outerWidth / 2 + 0.5
        let innerInset = outerInset + outerWidth / 2 + gap + innerWidth / 2

        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = size / 2 - outerInset
            let innerRadius = size / 2 - innerInset
            let startAngle: CGFloat = 210 * .pi / 180
            let endAngle: CGFloat = -30 * .pi / 180
            let totalSweep = startAngle - endAngle

            // Outer track (block background)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(NSColor.secondaryLabelColor.cgColor)
            ctx.setLineWidth(outerWidth)
            ctx.addArc(center: center, radius: outerRadius,
                       startAngle: startAngle, endAngle: endAngle, clockwise: true)
            ctx.strokePath()

            // Outer fill (block)
            if blockFraction > 0 {
                let fillEnd = startAngle - totalSweep * blockFraction
                let color = paceColor(usage: blockFraction, time: blockTimeFraction)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(outerWidth)
                ctx.addArc(center: center, radius: outerRadius,
                           startAngle: startAngle, endAngle: fillEnd, clockwise: true)
                ctx.strokePath()
            }

            // Inner track (weekly background)
            ctx.setStrokeColor(NSColor.secondaryLabelColor.cgColor)
            ctx.setLineWidth(innerWidth)
            ctx.addArc(center: center, radius: innerRadius,
                       startAngle: startAngle, endAngle: endAngle, clockwise: true)
            ctx.strokePath()

            // Inner fill (weekly)
            if weeklyFraction > 0 {
                let fillEnd = startAngle - totalSweep * weeklyFraction
                let color = paceColor(usage: weeklyFraction, time: weeklyTimeFraction)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(innerWidth)
                ctx.addArc(center: center, radius: innerRadius,
                           startAngle: startAngle, endAngle: fillEnd, clockwise: true)
                ctx.strokePath()
            }

            return true
        }
        image.isTemplate = false
        return image
    }

    /// Color based on usage pace vs time elapsed.
    /// ratio = usageFraction / timeFraction — how far ahead of linear budget.
    private func paceColor(usage: Double, time: Double) -> NSColor {
        guard time > 0.01 else {
            // Very start of window — any usage is technically "ahead"
            return usage > 0 ? .systemYellow : .systemGreen
        }
        let ratio = usage / time
        switch ratio {
        case ..<0.8: return .systemGreen   // well under budget pace
        case ..<1.0: return .systemYellow  // approaching budget pace
        case ..<1.3: return .systemOrange  // moderately ahead
        default:     return .systemRed     // significantly ahead
        }
    }
}
