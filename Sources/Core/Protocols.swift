// Core protocols for the SystemManager architecture

/// Protocol for entities that can be controlled at runtime
public protocol RuntimeControllable {
    func start() async throws
    func stop() async throws
    func restart() async throws
}

/// Protocol for resources that can be observed
public protocol ObservableResource {
    func metrics() async -> [String: String]
}

/// Protocol for system services
public protocol SystemService {
    // Placeholder for system service requirements
}