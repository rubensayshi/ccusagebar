import SwiftUI
import AppKit

struct MenuBarIcon: View {
    let fiveHourUtilization: Double   // 0–100
    let sevenDayUtilization: Double   // 0–100
    let fiveHourResetsAt: String?
    let sevenDayResetsAt: String?

    private var blockFraction: Double {
        min(fiveHourUtilization / 100.0, 1.0)
    }

    private var weeklyFraction: Double {
        min(sevenDayUtilization / 100.0, 1.0)
    }

    private var blockTimeFraction: Double {
        timeFraction(resetsAt: fiveHourResetsAt, windowSeconds: WindowDuration.fiveHour)
    }

    private var weeklyTimeFraction: Double {
        timeFraction(resetsAt: sevenDayResetsAt, windowSeconds: WindowDuration.sevenDay)
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

            // Outer track (5h background)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(NSColor.secondaryLabelColor.cgColor)
            ctx.setLineWidth(outerWidth)
            ctx.addArc(center: center, radius: outerRadius,
                       startAngle: startAngle, endAngle: endAngle, clockwise: true)
            ctx.strokePath()

            // Outer fill (5h)
            if blockFraction > 0 {
                let fillEnd = startAngle - totalSweep * blockFraction
                let color = paceNSColor(usage: blockFraction, time: blockTimeFraction)
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
                let color = paceNSColor(usage: weeklyFraction, time: weeklyTimeFraction)
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

    private func paceNSColor(usage: Double, time: Double) -> NSColor {
        guard time > 0.01 else {
            return usage > 0 ? .systemYellow : .systemGreen
        }
        let ratio = usage / time
        switch ratio {
        case ..<0.8: return .systemGreen
        case ..<1.0: return .systemYellow
        case ..<1.3: return .systemOrange
        default:     return .systemRed
        }
    }
}
