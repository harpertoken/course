# SystemManager

User-space system manager for macOS (Apple Silicon) using Swift. Orchestrates processes, monitors resources, enforces policies.

## Key Fix

Refactored to actor-based data handling in RuntimeProcess. Data mutations now isolated in DataHandler actor, eliminating Sendable warnings and ensuring thread safety.

```swift
actor DataHandler {
    private var stdoutData = Data()
    private var stderrData = Data()
    private let maxSize = 1_048_576 // 1 MB limit

    private func truncateIfNeeded(_ data: inout Data) {
        if data.count > maxSize {
            data = data.suffix(maxSize)
        }
    }

    func append(to stream: StreamType, data: Data) {
        switch stream {
        case .stdout:
            stdoutData.append(data)
            truncateIfNeeded(&stdoutData)
        case .stderr:
            stderrData.append(data)
            truncateIfNeeded(&stderrData)
        }
    }

    func getData() -> (stdout: String, stderr: String) {
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        return (stdout, stderr)
    }
}
```

*Prior fix: Added NSLock for thread-safe Data mutation.*

```swift
private let dataLock = NSLock()
// In append:
dataLock.lock()
stdoutData.append(data)
dataLock.unlock()
// In getData:
dataLock.lock()
let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
dataLock.unlock()
```

## Links

- [Features](docs/features.md)
- [Usage](docs/usage.md)
- [Architecture](docs/architecture-notes.md)
- [Roadmap](https://github.com/orgs/harpertoken/projects/1)