import Foundation
import SwiftUI
import Combine

@MainActor
class UsageService: ObservableObject {
    @Published var data = UsageData()

    @AppStorage("refreshInterval") private var refreshIntervalMinutes: Int = 5

    private var timer: Timer?
    private var fileWatcher: FileWatcher?

    init() {
        startAutoRefresh()
        startWatching()
    }

    func startAutoRefresh() {
        refresh()
        scheduleTimer()
    }

    func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func startWatching() {
        fileWatcher = FileWatcher(url: UsageStatusReader.fileURL) { [weak self] in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        data.isLoading = true

        let result = UsageStatusReader.read()
        data.rateLimit = result.rateLimit
        data.error = result.error
        data.lastUpdated = result.updated ?? Date()

        if let fiveHour = result.rateLimit?.fiveHour {
            NotificationService.shared.checkThresholds(utilization: fiveHour.utilization)
        }

        data.isLoading = false
    }
}

/// Watches a single file for changes via a kqueue dispatch source. The file is
/// rewritten atomically (write-tmp + rename), so we watch the parent directory
/// and re-arm to survive the inode swap.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        start()
    }

    private func start() {
        let dir = url.deletingLastPathComponent()
        fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: .write, queue: .global())
        src.setEventHandler { [weak self] in self?.onChange() }
        src.setCancelHandler { [weak self] in
            if let fd = self?.fd, fd >= 0 { close(fd) }
        }
        source = src
        src.resume()
    }

    deinit {
        source?.cancel()
    }
}
