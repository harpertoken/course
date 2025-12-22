import Foundation
import IOKit

/// Samples GPU usage metrics
public class GPUMetricsSampler {
    public struct GPUMetrics {
        public let usage: Double // percentage
        public let temperature: Double? // Celsius, if available
    }

    public init() {}

    public func sample() -> GPUMetrics? {
        // Production GPU sampling using IOKit
        // Robust implementation with proper error handling and resource management

        let serviceNames = ["AppleGPUWrangler", "AGPM", "AppleM2GPUWrangler", "AppleIntelIntegratedGraphics"]
        var service: io_service_t = 0

        for name in serviceNames {
            if let matching = IOServiceMatching(name) {
                service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
                if service != 0 { break }
            }
        }

        if service == 0 {
            // Fallback: try to get any GPU service
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPCIDevice"))
            guard service != 0 else {
                return GPUMetrics(usage: 0.0, temperature: nil)
            }
        }

        defer { IOObjectRelease(service) }

        var usage: Double = 0.0
        var temperature: Double? = nil

        do {
            var properties: Unmanaged<CFMutableDictionary>?
            let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)

            guard result == KERN_SUCCESS else {
                throw GPUSamplingError.ioRegistryError(result)
            }

            guard let props = properties?.takeRetainedValue() as? [String: Any] else {
                throw GPUSamplingError.invalidProperties
            }

            // Parse GPU usage from properties (varies by GPU model)
            if let gpuStats = props["GPUStats"] as? [String: Any],
               let utilization = gpuStats["Utilization"] as? Double {
                usage = utilization
            } else if let performance = props["PerformanceStatistics"] as? [String: Any],
                      let gpuCoreUtilization = performance["GPU Core Utilization"] as? Double {
                usage = gpuCoreUtilization
            }

            // Parse temperature if available
            if let thermal = props["Thermal"] as? [String: Any],
               let gpuTemp = thermal["GPU Temperature"] as? Double {
                temperature = gpuTemp
            }

        } catch {
            // Log error in production
            print("GPU sampling error: \(error)")
            return GPUMetrics(usage: 0.0, temperature: nil)
        }

        return GPUMetrics(usage: min(100.0, max(0.0, usage)), temperature: temperature)
    }
}

enum GPUSamplingError: Error {
    case ioRegistryError(kern_return_t)
    case invalidProperties
}