import Foundation

/// Descriptor for a runtime task
public struct TaskDescriptor: Codable, Hashable, Sendable {
    public let id: UUID
    public let command: String
    public let arguments: [String]
    public let environment: [String: String]?
    public let workingDirectory: URL?
    public let timeout: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case id, command, arguments, environment, workingDirectory, timeout
    }

    public init(
        id: UUID = UUID(),
        command: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        workingDirectory: URL? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.id = id
        self.command = command
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
        self.timeout = timeout
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.command = try container.decode(String.self, forKey: .command)
        self.arguments = try container.decodeIfPresent([String].self, forKey: .arguments) ?? []
        self.environment = try container.decodeIfPresent([String: String].self, forKey: .environment)
        self.workingDirectory = try container.decodeIfPresent(URL.self, forKey: .workingDirectory)
        self.timeout = try container.decodeIfPresent(TimeInterval.self, forKey: .timeout)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    }
}