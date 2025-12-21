import Foundation
import Core
import SystemInterfaces
import SystemObservation

/// Supervisor that monitors and enforces policies on runtime processes
public class Supervisor: @unchecked Sendable {
    private let runtimeManager: RuntimeManager
    private let taskMetricsSampler: TaskMetricsSampler
    private var isRunning = false
    private let queue = DispatchQueue(label: "Supervisor.queue")

    public init(runtimeManager: RuntimeManager, taskMetricsSampler: TaskMetricsSampler) {
        self.runtimeManager = runtimeManager
        self.taskMetricsSampler = taskMetricsSampler
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
                        let metricsDict: [String: Any] = [
                            "cpu": 0.0, // TODO: implement task CPU sampling
                            "memory": taskMetrics.memoryResident
                        ]

                        let violated = await runtimeManager.checkPolicies(for: id, with: metricsDict)
                        if violated {
                            try? await runtimeManager.stop(id: id)
                        }
                    }
                }
            }
        }
    }
}