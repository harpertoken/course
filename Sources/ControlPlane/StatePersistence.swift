import Foundation
import Core

/// Persists runtime manager state to disk
public class StatePersistence {
    private let fileURL: URL

    public init(fileURL: URL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".systemmanager_state.json")) {
        self.fileURL = fileURL
    }

    public func save(processes: [UUID: TaskDescriptor]) throws {
        let data = try JSONEncoder().encode(processes)
        try data.write(to: fileURL)
    }

    public func load() throws -> [UUID: TaskDescriptor] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([UUID: TaskDescriptor].self, from: data)
    }
}
