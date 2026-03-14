// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "beacon",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Beacon",
            path: "Sources/Beacon",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Vision"),
                .linkedFramework("Accelerate"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("Carbon"),
            ]
        ),
        .testTarget(
            name: "BeaconTests",
            dependencies: ["Beacon"]
        )
    ]
)
