import Foundation

/// Policy rules for runtime processes
public struct Policy {
    public let maxCPUUsage: Double? // percentage
    public let maxMemoryUsage: UInt64? // bytes
    public let timeout: TimeInterval? // seconds
    public let maxRestarts: Int?

    public init(
        maxCPUUsage: Double? = nil,
        maxMemoryUsage: UInt64? = nil,
        timeout: TimeInterval? = nil,
        maxRestarts: Int? = nil
    ) {
        self.maxCPUUsage = maxCPUUsage
        self.maxMemoryUsage = maxMemoryUsage
        self.timeout = timeout
        self.maxRestarts = maxRestarts
    }
}