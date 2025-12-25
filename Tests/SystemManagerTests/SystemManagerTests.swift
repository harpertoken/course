// SPDX-License-Identifier: MIT

import XCTest
@testable import Core
@testable import SystemInterfaces
@testable import ControlPlane
@testable import SystemObservation

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
        let largeDataSize = 2_000_000 // 2 MB
        let chunkSize = 500_000 // 0.5 MB chunks
        let handler = RuntimeProcess.DataHandler()

        // Test stdout with single large append
        let largeData = Data(repeating: 0, count: largeDataSize)
        await handler.append(to: .stdout, data: largeData)
        var result = await handler.getData()
        XCTAssertEqual(result.stdout.count, RuntimeProcess.DataHandler.maxSize)
        XCTAssertEqual(result.stderr.count, 0, "Stderr should be empty after stdout append")

        // Test stderr with incremental appends on the same handler
        for _ in 0..<5 {
            let chunk = Data(repeating: 1, count: chunkSize)
            await handler.append(to: .stderr, data: chunk)
        }
        // 5 * 500k = 2.5MB, should be truncated to 1MB
        result = await handler.getData()
        XCTAssertEqual(result.stdout.count, RuntimeProcess.DataHandler.maxSize, "Stdout data should remain unaffected")
        XCTAssertEqual(result.stderr.count, RuntimeProcess.DataHandler.maxSize)
    }

    func testSystemMetricsSampler() {
        let sampler = SystemMetricsSampler()
        // First sample might return nil for CPU
        _ = sampler.sample()
        // Second sample should have CPU
        if let metrics = sampler.sample() {
            XCTAssertGreaterThanOrEqual(metrics.cpuUsage, 0)
            XCTAssertGreaterThan(metrics.memoryUsage, 0)
            XCTAssertGreaterThan(metrics.memoryTotal, 0)
            XCTAssertNotNil(metrics.timestamp)
            // Anomaly score should be nil since no model provided
            XCTAssertNil(metrics.anomalyScore)
        }
    }

    func testAnomalyDetector() {
        // Test AnomalyDetector initialization with invalid path
        let detector = try? AnomalyDetector(modelPath: "/invalid/path")
        XCTAssertNil(detector, "Should return nil for invalid model path")

        // Integration test: If anomalib is available (in CI), verify import works
        // Note: Full prediction test requires trained model, which is complex for CI
        // Manual testing: Train model with scripts/train_dummy_model.py, then test detection
        // For now, initialization test ensures no crashes
    }
}
