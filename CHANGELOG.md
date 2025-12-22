# Changelog

## [Unreleased]

- Fixed all SwiftLint violations across the codebase (trailing newlines, line length limits)
- Corrected CPU usage calculation in TaskMetricsSampler to use dynamic sampling intervals instead of a hardcoded 1-second assumption
- Fixed thread count reporting in TaskMetricsSampler to accurately show total threads instead of suspended threads
- Added GitHub Actions workflow for automated spell checking using codespell
- Fixed YAML linting issues in workflow files and .swiftlint.yml for proper formatting
- Created .codespellignore file to exclude common technical terms from spell checks

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
- Improved thread count calculation in TaskMetricsSampler

All fixes ensure safe, efficient, user-space system management on macOS.