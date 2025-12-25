// SPDX-License-Identifier: MIT

import Foundation
import PythonKit

/// Anomaly detector using anomalib via PythonKit
public class AnomalyDetector {
    private let anomalib: PythonObject
    private let modelPath: String

    public init(modelPath: String) throws {
        self.modelPath = modelPath
        // Import anomalib
        anomalib = try Python.attemptImport("anomalib")
    }

    /// Detects anomaly in system metrics
    /// - Parameter metrics: Array of metric values (e.g., [cpuUsage, memoryUsage])
    /// - Returns: Anomaly score (higher means more anomalous), nil on error
    public func detectAnomaly(metrics: [Double]) -> Double? {
        do {
            // Import numpy for array conversion
            let np = Python.import("numpy")

            // Convert metrics to numpy array and reshape for image-like input
            // Anomalib expects image data; reshape [cpu, mem] to 1x2x1 "image"
            let pyMetrics = np.array(metrics).reshape([1, 2, 1])

            // Use anomalib's inference pipeline
            // Note: Assumes model trained on similar reshaped data
            let inferencer = anomalib.deploy.OpenVINOInferencer(
                path: modelPath,
                device: "CPU"
            )
            let result = inferencer.predict(pyMetrics)

            // Extract anomaly score
            return Double(result["anomaly_score"])
        } catch {
            print("Anomaly detection failed: \(error)")
            return nil
        }
    }
}
