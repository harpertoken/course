# Usage

## Building

```bash
swift build
```

## CLI

Run a process:
```bash
swift run CLI run '{"command": "/bin/echo", "arguments": ["hello"]}'
```

List processes:
```bash
swift run CLI list
```

Stop a process:
```bash
swift run CLI stop <uuid>
```

Get stats:
```bash
swift run CLI stats <uuid>
```

Daemon mode:
```bash
swift run CLI daemon
```

## GUI

```bash
swift run UI
```

## Modules

- Core: Protocols and data types
- SystemInterfaces: RuntimeProcess for lifecycle
- SystemObservation: Samplers for metrics
- ControlPlane: RuntimeManager and Supervisor
- CLI: Command-line interface
- UI: SwiftUI dashboard