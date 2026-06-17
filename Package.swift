// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SpotlightProgress",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SpotlightProgress", targets: ["SpotlightProgress"])
    ],
    targets: [
        .executableTarget(
            name: "SpotlightProgress",
            path: "src/macos",
            exclude: ["Info.plist"]
        )
    ]
)
