# SystemManager Architecture

## Layers

- **Interface**: CLI and SwiftUI for management
- **Control Plane**: RuntimeManager, Supervisor, StatePersistence
- **Observation**: SystemMetricsSampler, ProcessListSampler, TaskMetricsSampler
- **System Interfaces**: RuntimeProcess, Mach APIs
- **Core**: TaskDescriptor, Policy

## Key Decisions

- User-space, Apple APIs only
- Modular Swift packages
- Async/await concurrency
- JSON persistence
- Actor-based data isolation

## Trade-offs

- Stateless CLI
- Basic metrics
- Simple UI

## Future

- SQLite persistence
- API server
- Advanced metrics

## Security

- User-space only
- Input validation

## Performance

- 5s observation intervals
- ~10MB footprint

## Testing

- Manual CLI/UI testing
- Build verification

## Deployment

- Swift 6.2+, macOS 14+
- No dependencies

## Code Example

```swift
actor DataHandler {
    private var stdoutData = Data()
    func append(to stream: StreamType, data: Data) { ... }
    func getData() -> (stdout: String, stderr: String) { ... }
}
```
swift run CLI run '{"command": "/bin/echo", "arguments": ["hello"]}'
```

## Examples

### Task Lists
- [x] Process management implemented
- [ ] API server pending

### Alerts
> [!TIP]
> Use `swift run CLI daemon` for background monitoring.

### Footnotes
Modern Swift concurrency[^concurrency].

[^concurrency]: Async/await and actors.

### Relative Links
See [README](../README.md) for usage.

---

*For more on GitHub-flavored Markdown, see [Basic writing and formatting syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).*