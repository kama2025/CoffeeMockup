// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoffeeApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "CoffeeApp",
            targets: ["CoffeeApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "CoffeeApp",
            dependencies: [],
            path: "CoffeeApp"
        )
    ]
)
