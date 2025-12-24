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
        let maxSize = 1_048_576 // 1 MB limit
        let largeDataSize = 2_000_000 // 2 MB
        let chunkSize = 500_000 // 0.5 MB chunks

        // Test stdout with single large append
        let handler = RuntimeProcess.DataHandler()
        let largeData = Data(repeating: 0, count: largeDataSize)
        await handler.append(to: .stdout, data: largeData)
        var result = await handler.getData()
        XCTAssertEqual(result.stdout.count, maxSize)

        // Test stderr with incremental appends
        let newHandler = RuntimeProcess.DataHandler()
        for _ in 0..<5 {
            let chunk = Data(repeating: 1, count: chunkSize)
            await newHandler.append(to: .stderr, data: chunk)
        }
        // 5 * 500k = 2.5MB, should be truncated to 1MB
        result = await newHandler.getData()
        XCTAssertEqual(result.stderr.count, maxSize)
    }
}
