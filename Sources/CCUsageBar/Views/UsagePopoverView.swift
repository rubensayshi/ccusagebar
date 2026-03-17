import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var service: UsageService

    var body: some View {
        VStack(spacing: 0) {
            if service.data.isLoading && service.data.lastUpdated == nil {
                ProgressView("Fetching usage…")
                    .padding(24)
                settingsButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                content
            }
        }
        .frame(width: 300)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 12) {
            if let fiveHour = service.data.rateLimit?.fiveHour {
                BlockUsageView(window: fiveHour)
            } else {
                HStack {
                    Text("No 5-Hour Data")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            Divider()

            WeeklyUsageView(
                overall: service.data.rateLimit?.sevenDay,
                sonnet: service.data.rateLimit?.sevenDaySonnet,
                opus: service.data.rateLimit?.sevenDayOpus
            )

            Divider()

            footer
        }
        .padding(16)

        if let error = service.data.error {
            Text(error)
                .font(.caption2)
                .foregroundStyle(.red)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }

    private var footer: some View {
        HStack {
            Button {
                Task { await service.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .disabled(service.data.isLoading)

            if service.data.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
            }

            Spacer()

            if let meta = service.data.credentialMeta, let tier = meta.subscriptionType {
                Text(tier.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let date = service.data.lastUpdated {
                Text("Last: \(Fmt.shortTime(date))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            settingsButton
        }
    }

    private var settingsButton: some View {
        Button {
            DispatchQueue.main.async {
                SettingsWindowController.open()
            }
        } label: {
            Image(systemName: "gear")
                .font(.caption)
        }
        .buttonStyle(.borderless)
    }
}
