// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SystemManager",
    platforms: [.macOS(.v14)],
    targets: [
        // Core protocols and types
        .target(
            name: "Core",
            dependencies: []
        ),
        // System interface layer
        .target(
            name: "SystemInterfaces",
            dependencies: ["Core"]
        ),
        // Observation layer
        .target(
            name: "SystemObservation",
            dependencies: ["Core", "SystemInterfaces"]
        ),
        // Control plane
        .target(
            name: "ControlPlane",
            dependencies: ["Core", "SystemInterfaces", "SystemObservation"]
        ),
        // CLI interface
        .executableTarget(
            name: "CLI",
            dependencies: ["Core", "ControlPlane"]
        ),
        // SwiftUI dashboard
        .executableTarget(
            name: "UI",
            dependencies: ["Core", "ControlPlane"]
        ),
        // Tests
        .testTarget(
            name: "SystemManagerTests",
            dependencies: ["Core", "SystemInterfaces", "ControlPlane"]
        )
    ]
)
