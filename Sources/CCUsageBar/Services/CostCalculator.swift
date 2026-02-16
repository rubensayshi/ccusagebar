import Foundation

enum CostCalculator {

    private struct Pricing {
        let input: Double      // per M tokens
        let output: Double
        let cacheWrite: Double
        let cacheRead: Double
    }

    private static let pricing: [String: Pricing] = [
        "claude-opus-4-6":              Pricing(input: 5.00, output: 25.00, cacheWrite: 6.25, cacheRead: 0.50),
        "claude-sonnet-4-5-20250929":   Pricing(input: 3.00, output: 15.00, cacheWrite: 3.75, cacheRead: 0.30),
        "claude-haiku-4-5-20251001":    Pricing(input: 1.00, output: 5.00,  cacheWrite: 1.25, cacheRead: 0.10),
    ]

    // Fallback: Sonnet pricing
    private static let fallback = Pricing(input: 3.00, output: 15.00, cacheWrite: 3.75, cacheRead: 0.30)

    static func cost(for entry: UsageEntry) -> Double {
        let p = pricing[entry.model] ?? fallback
        return (Double(entry.inputTokens) * p.input
              + Double(entry.outputTokens) * p.output
              + Double(entry.cacheCreationTokens) * p.cacheWrite
              + Double(entry.cacheReadTokens) * p.cacheRead) / 1_000_000
    }
}
