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
    dependencies: [
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-parser.git", from: "0.1.0"),
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-validation-profiles.git", from: "0.1.0"),
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-wcag-algs.git", from: "0.1.0"),
        .package(url: "https://github.com/intrusive-memory/SwiftVerificar-validation.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "SwiftVerificarBiblioteca",
            dependencies: [
                .product(name: "SwiftVerificarParser", package: "SwiftVerificar-parser"),
                .product(name: "SwiftVerificarValidationProfiles", package: "SwiftVerificar-validation-profiles"),
                .product(name: "SwiftVerificarWCAGAlgs", package: "SwiftVerificar-wcag-algs"),
                .product(name: "SwiftVerificarValidation", package: "SwiftVerificar-validation"),
            ]
        ),
        .testTarget(
            name: "SwiftVerificarBibliotecaTests",
            dependencies: [
                "SwiftVerificarBiblioteca",
                .product(name: "SwiftVerificarValidationProfiles", package: "SwiftVerificar-validation-profiles"),
            ]
        ),
    ]
)
