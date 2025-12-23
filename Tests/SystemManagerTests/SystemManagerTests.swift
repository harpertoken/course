import XCTest
@testable import Core
@testable import SystemInterfaces
@testable import ControlPlane

final class SystemManagerTests: XCTestCase {
    func testPolicyInit() {
        let policy = Policy(maxCPUUsage: 50.0, maxMemoryUsage: 1000000, timeout: 60, maxRestarts: 3)
        XCTAssertEqual(policy.maxCPUUsage, 50.0)
        XCTAssertEqual(policy.maxMemoryUsage, 1000000)
        XCTAssertEqual(policy.timeout, 60)
        XCTAssertEqual(policy.maxRestarts, 3)
    }

    func testTaskDescriptorInit() {
        let id = UUID()
        let descriptor = TaskDescriptor(id: id, command: "/bin/echo", arguments: ["hello"])
        XCTAssertEqual(descriptor.id, id)
        XCTAssertEqual(descriptor.command, "/bin/echo")
        XCTAssertEqual(descriptor.arguments, ["hello"])
    }

    func testRuntimeManagerInit() async {
        let manager = RuntimeManager()
        let processes = await manager.list()
        XCTAssertTrue(processes.isEmpty)
    }

    func testDataHandlerBufferLimit() async {
        let handler = RuntimeProcess.DataHandler()
        let largeData = Data(repeating: 0, count: 2_000_000) // 2MB
        await handler.append(to: .stdout, data: largeData)
        let result = await handler.getData()
        XCTAssertEqual(result.stdout.count, 1_048_576) // Should be truncated to 1MB
    }
}
