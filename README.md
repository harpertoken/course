# SystemManager

User-space system manager for macOS (Apple Silicon) using Swift. Orchestrates processes, monitors resources, enforces policies.

## Key Fix

Refactored to actor-based data handling in RuntimeProcess. Data mutations now isolated in DataHandler actor, eliminating Sendable warnings and ensuring thread safety.

```swift
actor DataHandler {
    private var stdoutData = Data()
    private var stderrData = Data()

    func append(to stream: StreamType, data: Data) {
        switch stream {
        case .stdout: stdoutData.append(data)
        case .stderr: stderrData.append(data)
        }
    }

    func getData() -> (stdout: String, stderr: String) {
        (String(data: stdoutData, encoding: .utf8) ?? "",
         String(data: stderrData, encoding: .utf8) ?? "")
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