// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftVerificarBiblioteca",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftVerificarBiblioteca",
            targets: ["SwiftVerificarBiblioteca"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftVerificarBiblioteca"
        ),
        .testTarget(
            name: "SwiftVerificarBibliotecaTests",
            dependencies: ["SwiftVerificarBiblioteca"]
        ),
    ]
)
