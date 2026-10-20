// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScrcpyHub",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ScrcpyHub",
            targets: ["ScrcpyHub"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ScrcpyHub",
            dependencies: [],
            path: "Sources/ScrcpyHub"
        ),
    ]
)
