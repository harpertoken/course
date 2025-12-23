import Foundation
import Core

/// Represents a runtime process with lifecycle management
public class RuntimeProcess: RuntimeControllable, ObservableResource, @unchecked Sendable {
    public enum State: CustomStringConvertible, Sendable {
        case idle
        case starting
        case running(pid: Int32)
        case stopped(exitCode: Int32?)
        case failed(message: String)

        public var description: String {
            switch self {
            case .idle: return "Idle"
            case .starting: return "Starting"
            case .running(let pid): return "Running (PID: \(pid))"
            case .stopped(let code): return "Stopped (Code: \(code ?? -1))"
            case .failed(let message): return "Failed: \(message)"
            }
        }

        public var canStop: Bool {
            switch self {
            case .running: return true
            default: return false
            }
        }
    }

    private let descriptor: TaskDescriptor
    private let policy: Policy?
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var state: State = .idle
    private let dataHandler = DataHandler()

    actor DataHandler {
        private var stdoutData = Data()
        private var stderrData = Data()
        private let maxSize = 1_048_576 // 1 MB limit

        func append(to stream: StreamType, data: Data) {
            switch stream {
            case .stdout:
                stdoutData.append(data)
                if stdoutData.count > maxSize {
                    let excess = stdoutData.count - maxSize
                    stdoutData.removeFirst(excess)
                }
            case .stderr:
                stderrData.append(data)
                if stderrData.count > maxSize {
                    let excess = stderrData.count - maxSize
                    stderrData.removeFirst(excess)
                }
            }
        }

        func getData() -> (stdout: String, stderr: String) {
            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            return (stdout, stderr)
        }
    }
    private var startTime: Date?
    private var restartCount: Int = 0

    public var currentState: State { state }
    public var taskDescriptor: TaskDescriptor { descriptor }

    public init(descriptor: TaskDescriptor, policy: Policy? = nil) {
        self.descriptor = descriptor
        self.policy = policy
    }

    public func start() async throws {
        guard case .idle = state else {
            throw RuntimeError.invalidState("Process is not idle")
        }

        state = .starting

        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: descriptor.command)
            process.arguments = descriptor.arguments
            if let env = descriptor.environment {
                process.environment = env
            }
            if let workingDirectory = descriptor.workingDirectory {
                process.currentDirectoryURL = workingDirectory
            }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            self.process = process
            self.stdoutPipe = stdoutPipe
            self.stderrPipe = stderrPipe
            self.startTime = Date()

            // Set up reading pipes
            setupPipeReading(pipe: stdoutPipe, for: .stdout)
            setupPipeReading(pipe: stderrPipe, for: .stderr)

            try process.run()

            state = .running(pid: process.processIdentifier)

            // Wait for process to complete asynchronously
            Task {
                process.waitUntilExit()
                await handleProcessTermination()
            }
        } catch {
            state = .failed(message: error.localizedDescription)
            throw error
        }
    }

    public func stop() async throws {
        guard case .running = state else {
            throw RuntimeError.invalidState("Process is not running")
        }

        process?.terminate()
        // Wait a bit for graceful termination
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        if process?.isRunning == true {
            process?.interrupt()
        }

        state = .stopped(exitCode: process?.terminationStatus)
    }

    public func restart() async throws {
        restartCount += 1
        try await stop()
        try await start()
    }

    public func metrics() async -> [String: String] {
        var metrics: [String: String] = [
            "id": descriptor.id.uuidString,
            "command": descriptor.command,
            "state": String(describing: state)
        ]

        if case .running(let pid) = state {
            metrics["pid"] = "\(pid)"
        }

        let (stdout, stderr) = await dataHandler.getData()

        metrics["stdout"] = stdout
        metrics["stderr"] = stderr

        return metrics
    }

    private func setupPipeReading(pipe: Pipe, for stream: StreamType) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                // EOF
                handle.readabilityHandler = nil
            } else {
                Task {
                    await self?.dataHandler.append(to: stream, data: data)
                }
            }
        }
    }

    private func handleProcessTermination() async {
        guard let process = process else { return }
        let exitCode = process.terminationStatus
        state = .stopped(exitCode: exitCode)
    }

    /// Check if policies are violated
    public func checkPolicies(metrics: [String: Any]) -> Bool {
        guard let policy = policy else { return false }

        if let maxCPU = policy.maxCPUUsage, let cpu = metrics["cpu"] as? Double, cpu > maxCPU {
            return true
        }

        if let maxMem = policy.maxMemoryUsage, let mem = metrics["memory"] as? UInt64, mem > maxMem {
            return true
        }

        if let timeout = policy.timeout, let start = startTime, Date().timeIntervalSince(start) > timeout {
            return true
        }

        if let maxRestarts = policy.maxRestarts, restartCount >= maxRestarts {
            return true
        }

        return false
    }

    enum StreamType {
        case stdout, stderr
    }
}

enum RuntimeError: Error {
    case invalidState(String)
}
