import Foundation
import Darwin

/// Samples metrics for a specific task/process
public class TaskMetricsSampler {
    public init() {}

    public struct TaskMetrics {
        public let pid: Int32
        public let cpuTime: TimeInterval
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

        return TaskMetrics(
            pid: pid,
            cpuTime: TimeInterval(taskInfo.user_time.seconds) + TimeInterval(taskInfo.user_time.microseconds) / 1_000_000 +
                     TimeInterval(taskInfo.system_time.seconds) + TimeInterval(taskInfo.system_time.microseconds) / 1_000_000,
            memoryResident: UInt64(taskInfo.resident_size),
            memoryVirtual: UInt64(taskInfo.virtual_size),
            threadCount: taskInfo.suspend_count
        )
    }
}