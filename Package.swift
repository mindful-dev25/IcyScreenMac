// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "IcyScreenMac",
    platforms: [.macOS(.v11)],
    targets: [
        .executableTarget(
            name: "IcyScreenMac",
            path: "Sources/IcyScreenMac"
        )
    ]
)
