// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoffeeApp",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "CoffeeApp", targets: ["CoffeeApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "CoffeeApp",
            path: ".",
            sources: ["CoffeeAppApp.swift", "ContentView.swift", "MenuView.swift", "OrdersView.swift", "SettingsView.swift", "Config.swift"]
        ),
    ]
) 