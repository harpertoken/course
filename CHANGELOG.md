# Changelog

## [0.1.1] - 2025-12-22

### Improvements
- Added 1MB buffer size limit to DataHandler in RuntimeProcess to prevent unbounded memory growth for verbose processes
- Added unit test for DataHandler buffer limit functionality

### Improvements
- Fixed all SwiftLint violations across the codebase (trailing newlines, line length limits, cyclomatic complexity in GPUMetricsSampler)
- Corrected CPU usage calculation in TaskMetricsSampler to use dynamic sampling intervals instead of a hardcoded 1-second assumption
- Fixed thread count reporting in TaskMetricsSampler to accurately show total threads instead of suspended threads
- Added GitHub Actions workflow for automated spell checking using codespell
- Fixed YAML linting issues in workflow files and .swiftlint.yml for proper formatting
- Created .codespellignore file to exclude common technical terms from spell checks

### Performance Improvements
- Optimized DataHandler buffer truncation using `suffix(maxSize)` instead of `removeFirst(excess)` for better performance (O(1) vs O(n)) when handling large data buffers

### Code Quality
- Refactored DataHandler truncation logic into a `truncateIfNeeded` helper method to eliminate code duplication between stdout and stderr handling

### Testing
- Enhanced `testDataHandlerBufferLimit` to comprehensively test both stdout and stderr streams, including incremental data appends and using named constants for maintainability

### Documentation
- Updated README code snippet to reflect the current actor-based DataHandler implementation with efficient truncation

## [0.1.0] - 2025-12-22

### Major Fixes/Improvements
- Added JSON-based persistence for process state
- Implemented daemon mode with background supervisor loop
- Built SwiftUI dashboard for GUI management
- Fixed concurrency with NSLock for thread-safe data access (intermediate)
- Fixed concurrency with actor-based data handling (final, eliminated Sendable warnings)
- Styled README and docs with GitHub Markdown
- Cleaned documentation for clarity
- Added policy enforcement with timeouts and resource limits
- Modular architecture with Swift packages
- Thread-safe data access in RuntimeProcess
- Added CI workflow with GitHub Actions
- Configured SwiftLint for code quality
- Added unit tests for core components
- Added binary releases via GitHub Actions
- Created Homebrew formula for easy installation

All fixes ensure safe, efficient, user-space system management on macOS.