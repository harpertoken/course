// SPDX-License-Identifier: MIT

import Foundation
import Core
import SystemInterfaces
import SystemObservation

/// Supervisor that monitors and enforces policies on runtime processes
public class Supervisor: @unchecked Sendable {
    private let runtimeManager: RuntimeManager
    private let taskMetricsSampler: TaskMetricsSampler
    private let systemMetricsSampler: SystemMetricsSampler
    private let anomalyThreshold: Double
    private var isRunning = false
    private let queue = DispatchQueue(label: "Supervisor.queue")

    public init(
        runtimeManager: RuntimeManager,
        taskMetricsSampler: TaskMetricsSampler,
        systemMetricsSampler: SystemMetricsSampler,
        anomalyThreshold: Double = 0.5
    ) {
        self.runtimeManager = runtimeManager
        self.taskMetricsSampler = taskMetricsSampler
        self.systemMetricsSampler = systemMetricsSampler
        self.anomalyThreshold = anomalyThreshold
    }

    /// Start the supervisor loop
    public func start(interval: TimeInterval = 5.0) {
        guard !isRunning else { return }
        isRunning = true

        queue.async {
            while self.isRunning {
                self.monitorAndEnforce()
                Thread.sleep(forTimeInterval: interval)
            }
        }
    }

    /// Stop the supervisor loop
    public func stop() {
        isRunning = false
    }

    private func monitorAndEnforce() {
        Task {
            let processes = await runtimeManager.list()
            for (id, state) in processes {
                if case .running(let pid) = state {
                    if let taskMetrics = taskMetricsSampler.sample(pid: pid) {
                        let metricsDict: [String: String] = [
                            "cpu": "\(taskMetrics.cpuUsage)",
                            "memory": "\(taskMetrics.memoryResident)"
                        ]

                        let violated = await runtimeManager.checkPolicies(for: id, with: metricsDict)
                        if violated {
                            try? await runtimeManager.stop(id: id)
                        }
                    }
                }
            }

            // Check system metrics for anomalies
            if let metrics = systemMetricsSampler.sample(), let score = metrics.anomalyScore, score > anomalyThreshold {
                print("Anomaly detected in system metrics: \(score)")
            }
        }
    }
}
