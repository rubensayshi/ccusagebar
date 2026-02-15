import Foundation

enum ShellError: Error, LocalizedError {
    case commandFailed(Int32, String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .commandFailed(let code, let stderr):
            return "Command failed (\(code)): \(stderr)"
        case .timeout:
            return "Command timed out"
        }
    }
}

struct ShellExecutor {
    static func run(_ command: String, timeout: TimeInterval = 30) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", command]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                process.terminate()
                continuation.resume(throwing: ShellError.timeout)
            }
            timer.resume()

            process.terminationHandler = { proc in
                timer.cancel()
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8) ?? ""
                let errOutput = String(data: errData, encoding: .utf8) ?? ""

                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: ShellError.commandFailed(proc.terminationStatus, errOutput))
                }
            }

            do {
                try process.run()
            } catch {
                timer.cancel()
                continuation.resume(throwing: error)
            }
        }
    }
}
