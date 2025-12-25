// SPDX-License-Identifier: MIT

import Foundation
import Darwin
import PythonKit

/// Samples system-wide CPU and memory metrics
public class SystemMetricsSampler {
    public struct Metrics {
        public let cpuUsage: Double // percentage
        public let memoryUsage: UInt64 // bytes used
        public let memoryTotal: UInt64 // bytes total
        public let timestamp: Date
        public let anomalyScore: Double?
    }

    private var previousCPUInfo: host_cpu_load_info?
    private var anomalyDetector: AnomalyDetector?

    public init(modelPath: String? = nil) {
        if let path = modelPath {
            anomalyDetector = try? AnomalyDetector(modelPath: path)
        }
    }

    public func sample() -> Metrics? {
        let timestamp = Date()

        // CPU
        let cpuUsage = sampleCPU() ?? 0

        // Memory
        let memoryInfo = sampleMemory()

        // Anomaly detection
        let anomalyScore: Double? = anomalyDetector?.detectAnomaly(metrics: [cpuUsage, Double(memoryInfo.used)])

        return Metrics(
            cpuUsage: cpuUsage,
            memoryUsage: memoryInfo.used,
            memoryTotal: memoryInfo.total,
            timestamp: timestamp,
            anomalyScore: anomalyScore
        )
    }

    private func sampleCPU() -> Double? {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var cpuLoad = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let user = Double(cpuLoad.cpu_ticks.0)
        let system = Double(cpuLoad.cpu_ticks.1)
        let idle = Double(cpuLoad.cpu_ticks.2)
        let nice = Double(cpuLoad.cpu_ticks.3)

        let total = user + system + idle + nice

        guard let previous = previousCPUInfo else {
            previousCPUInfo = cpuLoad
            return nil // first sample
        }

        let prevUser = Double(previous.cpu_ticks.0)
        let prevSystem = Double(previous.cpu_ticks.1)
        let prevIdle = Double(previous.cpu_ticks.2)
        let prevNice = Double(previous.cpu_ticks.3)

        let prevTotal = prevUser + prevSystem + prevIdle + prevNice

        let diffUser = user - prevUser
        let diffSystem = system - prevSystem
        let diffTotal = total - prevTotal

        previousCPUInfo = cpuLoad

        guard diffTotal > 0 else { return 0 }
        return ((diffUser + diffSystem) / diffTotal) * 100
    }

    private func sampleMemory() -> (used: UInt64, total: UInt64) {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize: UInt64 = 4096 // macOS standard page size
            let wiredCount = vmStats.active_count + vmStats.inactive_count + vmStats.wire_count
            let used = UInt64(wiredCount) * pageSize
            let total = UInt64(wiredCount + vmStats.free_count) * pageSize
            return (used, total)
        } else {
            return (0, 0)
        }
    }
}
