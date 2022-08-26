// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Greycats",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "GreycatsCore",
            targets: ["GreycatsCore"]
        ),
        .library(
            name: "Greycats",
            targets: ["Greycats"]
        ),
        .library(
            name: "GreycatsGraphics",
            targets: ["GreycatsGraphics"]
        ),
        .library(
            name: "GreycatsGeocode",
            targets: ["GreycatsGeocode"]
        ),
        .library(
            name: "GreycatsNavigator",
            targets: ["GreycatsNavigator"]
        ),
        .library(
            name: "GreycatsCamera",
            targets: ["GreycatsCamera"]
        ),
        .library(
            name: "GreycatsFilterHook",
            targets: ["GreycatsFilterHook"]
        ),
        .library(
            name: "GreycatsBreadcrumb",
            targets: ["GreycatsBreadcrumb"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GreycatsCore",
            path: "Greycats",
            sources: ["Core"]
        ),
        .target(
            name: "Greycats",
            dependencies: ["GreycatsCore"],
            path: "Greycats",
            sources: ["Layout"]
        ),
        .target(
            name: "GreycatsGraphics",
            path: "Greycats",
            sources: ["Graphics"]
        ),
        .target(
            name: "GreycatsGeocode",
            path: "Greycats",
            sources: ["Geocode.swift"]
        ),
        .target(
            name: "GreycatsNavigator",
            dependencies: ["Greycats"],
            path: "Greycats",
            sources: ["Navigator.swift"]
        ),
        .target(
            name: "GreycatsCamera",
            dependencies: ["GreycatsCore", "GreycatsGraphics"],
            path: "Greycats",
            sources: ["Camera.swift"]
        ),
        .target(
            name: "GreycatsFilterHook",
            dependencies: ["Greycats"],
            path: "Greycats",
            sources: ["FilterHook.swift"]
        ),
        .target(
            name: "GreycatsBreadcrumb",
            path: "Greycats",
            sources: ["Breadcrumb.swift"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
