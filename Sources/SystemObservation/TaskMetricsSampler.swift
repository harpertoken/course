import Foundation
import Darwin

/// Samples metrics for a specific task/process
public class TaskMetricsSampler {
    public init() {}
    private var previousCPUTimes: [Int32: TimeInterval] = [:]

    public struct TaskMetrics {
        public let pid: Int32
        public let cpuTime: TimeInterval
        public let cpuUsage: Double // percentage
        public let memoryResident: UInt64
        public let memoryVirtual: UInt64
        public let threadCount: Int32
    }

    public func sample(pid: Int32) -> TaskMetrics? {
        let port = task_t(pid)
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(port, task_flavor_t(TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        var userTime = TimeInterval(taskInfo.user_time.seconds)
        userTime += TimeInterval(taskInfo.user_time.microseconds) / 1_000_000
        var systemTime = TimeInterval(taskInfo.system_time.seconds)
        systemTime += TimeInterval(taskInfo.system_time.microseconds) / 1_000_000
        let currentCPUTime = userTime + systemTime

        let cpuUsage: Double
        if let previous = previousCPUTimes[pid] {
            let diff = currentCPUTime - previous
            cpuUsage = diff > 0 ? (diff / 1.0) * 100 : 0 // Simplified, assuming 1s interval
        } else {
            cpuUsage = 0
        }
        previousCPUTimes[pid] = currentCPUTime

        return TaskMetrics(
            pid: pid,
            cpuTime: currentCPUTime,
            cpuUsage: cpuUsage,
            memoryResident: UInt64(taskInfo.resident_size),
            memoryVirtual: UInt64(taskInfo.virtual_size),
            threadCount: taskInfo.suspend_count
        )
    }
}
