// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slip",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Slip", targets: ["SlipApp"])
    ],
    targets: [
        .executableTarget(
            name: "SlipApp",
            path: "Sources/SlipApp"
        ),
        .testTarget(
            name: "SlipAppTests",
            dependencies: ["SlipApp"],
            path: "Tests/SlipAppTests"
        )
    ]
)
