import Foundation
import Core
import SystemInterfaces

/// Manages runtime processes
public class RuntimeManager: SystemService, @unchecked Sendable {
    private var processes: [UUID: RuntimeProcess] = [:]
    private let queue = DispatchQueue(label: "RuntimeManager.queue", attributes: .concurrent)
    private let persistence = StatePersistence()

    public init() {
        // Load persisted state on init
        do {
            let persisted = try persistence.load()
            // Note: Can't restart processes, just log
            print("Loaded \(persisted.count) persisted processes (not restarted)")
        } catch {
            // No persisted state or error, ignore
        }
    }

    /// Spawn a new process from descriptor
    public func spawn(descriptor: TaskDescriptor) async throws -> UUID {
        let process = RuntimeProcess(descriptor: descriptor)
        try await process.start()

        queue.async(flags: .barrier) {
            self.processes[descriptor.id] = process
            // Persist the descriptor
            let descriptors = self.processes.mapValues { $0.taskDescriptor }
            try? self.persistence.save(processes: descriptors)
        }

        return descriptor.id
    }

    /// Stop a process by ID
    public func stop(id: UUID) async throws {
        guard let process = queue.sync(execute: { processes[id] }) else {
            throw RuntimeManagerError.processNotFound(id)
        }
        try await process.stop()
        queue.async(flags: .barrier) {
            self.processes.removeValue(forKey: id)
            // Persist updated state
            let descriptors = self.processes.mapValues { $0.taskDescriptor }
            try? self.persistence.save(processes: descriptors)
        }
    }

    /// Restart a process by ID
    public func restart(id: UUID) async throws {
        guard let process = queue.sync(execute: { processes[id] }) else {
            throw RuntimeManagerError.processNotFound(id)
        }
        try await process.restart()
    }

    /// List all running processes
    public func list() async -> [UUID: RuntimeProcess.State] {
        return queue.sync {
            processes.mapValues { $0.currentState }
        }
    }

    /// Get metrics for a specific process
    public func metrics(for id: UUID) async -> [String: Any]? {
        guard let process = queue.sync(execute: { processes[id] }) else {
            return nil
        }
        return await process.metrics()
    }

    /// Check if policies are violated for a process
    public func checkPolicies(for id: UUID, with metrics: [String: Any]) async -> Bool {
        guard let process = queue.sync(execute: { processes[id] }) else {
            return false
        }
        // Assuming RuntimeProcess has checkPolicies, but wait, it's in SystemInterfaces
        // Since ControlPlane depends on SystemInterfaces, ok
        // But RuntimeProcess is in SystemInterfaces, yes.
        // But to call, need to cast or something, but since it's private, wait no, the method is public in RuntimeProcess.
        // But the instance is private in RuntimeManager.
        // So, I can call process.checkPolicies(metrics)
        // But since it's actor? No, I made it class.
        return process.checkPolicies(metrics: metrics)
    }
}

enum RuntimeManagerError: Error {
    case processNotFound(UUID)
}