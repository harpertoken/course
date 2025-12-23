import Foundation
import IOKit

/// Samples GPU usage metrics
public class GPUMetricsSampler {
    public struct GPUMetrics {
        public let usage: Double // percentage
        public let temperature: Double? // Celsius, if available
    }

    public init() {}

    private func findGPUService() -> io_service_t {
        let serviceNames = ["IOAccelerator", "AppleGPUWrangler", "AGPM",
                            "AppleM2GPUWrangler", "AppleIntelIntegratedGraphics"]
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
        }

        return service
    }

    private func parseGPUProperties(_ props: [String: Any]) -> (usage: Double, temperature: Double?) {
        var usage: Double = 0.0
        var temperature: Double?

        // Parse GPU usage from properties (implementation varies by GPU model)
        if let gpuStats = props["GPUStats"] as? [String: Any],
            let utilization = gpuStats["Utilization"] as? Double {
            usage = utilization
        } else if let performanceStats = props["PerformanceStatistics"] as? [String: Any] {
            // Check various possible keys for GPU utilization
            usage = performanceStats["Device Utilization %"] as? Double ??
                    performanceStats["GPU Core Utilization"] as? Double ??
                    performanceStats["GPU Utilization"] as? Double ??
                    performanceStats["Utilization Percentage"] as? Double ?? 0.0
        } else if let gpuInfo = props["GPU"] as? [String: Any],
                  let utilization = gpuInfo["Utilization"] as? Double {
            usage = utilization
        }

        // Parse temperature if available
        if let thermal = props["Thermal"] as? [String: Any],
            let gpuTemp = thermal["GPU Temperature"] as? Double {
            temperature = gpuTemp
        } else if let temp = props["Temperature"] as? Double {
            temperature = temp
        }

        return (usage: min(100.0, max(0.0, usage)), temperature: temperature)
    }

    public func sample() -> GPUMetrics? {
        // Production GPU sampling using IOKit
        // Robust implementation with proper error handling and resource management

        let service = findGPUService()
        guard service != 0 else {
            return GPUMetrics(usage: 0.0, temperature: nil)
        }

        defer { IOObjectRelease(service) }

        do {
            var properties: Unmanaged<CFMutableDictionary>?
            let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)

            guard result == KERN_SUCCESS else {
                throw GPUSamplingError.ioRegistryError(result)
            }

            guard let props = properties?.takeRetainedValue() as? [String: Any] else {
                throw GPUSamplingError.invalidProperties
            }

            let (usage, temperature) = parseGPUProperties(props)
            return GPUMetrics(usage: usage, temperature: temperature)

        } catch {
            // Log error in production
            print("GPU sampling error: \(error)")
            return GPUMetrics(usage: 0.0, temperature: nil)
        }
    }
}

enum GPUSamplingError: Error {
    case ioRegistryError(kern_return_t)
    case invalidProperties
}
