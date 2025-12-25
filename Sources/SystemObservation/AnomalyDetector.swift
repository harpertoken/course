// SPDX-License-Identifier: MIT

import Foundation
import PythonKit

/// Anomaly detector using anomalib via PythonKit
public class AnomalyDetector {
    private let anomalib: PythonObject
    private let model: PythonObject

    public init(modelPath: String) throws {
        // Import anomalib
        anomalib = try Python.attemptImport("anomalib")
        let models = anomalib.models

        // Load the pre-trained model (example with Padim)
        // Actual loading depends on model type; adjust for your trained model
        let padim = models.Padim
        model = padim.load_from_checkpoint(modelPath)
    }

    /// Detects anomaly in system metrics
    /// - Parameter metrics: Array of metric values (e.g., [cpuUsage, memoryUsage])
    /// - Returns: Anomaly score (higher means more anomalous)
    public func detectAnomaly(metrics: [Double]) -> Double {
        // Convert Swift array to Python list
        let pyMetrics = Python.list(metrics)

        // Assuming the model has a predict method that takes a list and returns score
        // This is pseudo-code; adapt to actual anomalib API
        let result = model.predict(pyMetrics)

        // Extract anomaly score
        return Double(result["anomaly_score"]) ?? 0.0
    }
}
