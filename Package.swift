// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HandyToDo",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HandyToDo",
            path: "Sources/HandyToDo"
        )
    ]
)
