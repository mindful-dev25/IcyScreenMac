// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IcyScreenMac",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "IcyScreenMac",
            path: "Sources/IcyScreenMac"
        )
    ]
)
