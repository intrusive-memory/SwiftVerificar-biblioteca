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
        .package(path: "../SwiftVerificar-parser"),
        .package(path: "../SwiftVerificar-validation-profiles"),
        .package(path: "../SwiftVerificar-wcag-algs"),
        .package(path: "../SwiftVerificar-validation"),
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
