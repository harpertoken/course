# Changelog

## [Unreleased]

### Improvements
- Improved thread count calculation in TaskMetricsSampler

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