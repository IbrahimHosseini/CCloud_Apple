// swift-tools-version: 6.2

import PackageDescription

// Clean Architecture layers, innermost first. A module only depends on the ones above it:
//
//   CCloudDomain        entities, repository protocols, use cases (Foundation only)
//   CCloudData          → Domain                       API client, DTOs, persistence
//   CCloudPresentation  → Domain                       ViewModels, app-wide state
//   CCloudDesignSystem  → Domain, Presentation         SwiftUI components, theme, strings
//   CCloudPlayer        → ... + DesignSystem, VLCKit   playback engines and player UI
//   CCloudFeatures      → ... + Player                 screens, per-platform navigation
//   CCloudComposition   → everything                   composition root (DI wiring)
//
// Only the composition root sees CCloudData, so the compiler enforces the dependency rule.

let package = Package(
    name: "CCloudKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .tvOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "CCloudComposition", targets: ["CCloudComposition"]),
    ],
    dependencies: [
        // Official VideoLAN VLCKit 3.6.0 binaries (MobileVLCKit / TVVLCKit / VLCKit)
        // packaged as a single xcframework. Plays what AVPlayer can't (MKV, AVI, ...).
        .package(url: "https://github.com/tylerjonesio/vlckit-spm", exact: "3.6.0"),
    ],
    targets: [
        // MARK: Domain — entities, repository ports, use cases. Pure Swift.
        .target(name: "CCloudDomain"),

        // MARK: Data — REST API client, DTOs, local persistence.
        .target(
            name: "CCloudData",
            dependencies: ["CCloudDomain"]
        ),

        // MARK: Presentation — ViewModels and app-wide observable state.
        .target(
            name: "CCloudPresentation",
            dependencies: ["CCloudDomain"]
        ),

        // MARK: Design system — shared SwiftUI components, theme, fonts, strings.
        .target(
            name: "CCloudDesignSystem",
            dependencies: ["CCloudDomain", "CCloudPresentation"],
            resources: [.process("Resources")]
        ),

        // MARK: Player — AVPlayer and VLCKit playback engines and their UI.
        .target(
            name: "CCloudPlayer",
            dependencies: [
                "CCloudDomain",
                "CCloudPresentation",
                "CCloudDesignSystem",
                .product(name: "VLCKitSPM", package: "vlckit-spm"),
            ]
        ),

        // MARK: Features — screens and per-platform navigation shells.
        .target(
            name: "CCloudFeatures",
            dependencies: [
                "CCloudDomain",
                "CCloudPresentation",
                "CCloudDesignSystem",
                "CCloudPlayer",
            ]
        ),

        // MARK: Composition root — wires Data into Domain ports (DI).
        .target(
            name: "CCloudComposition",
            dependencies: [
                "CCloudDomain",
                "CCloudData",
                "CCloudPresentation",
                "CCloudDesignSystem",
                "CCloudPlayer",
                "CCloudFeatures",
            ]
        ),

        // MARK: Tests
        .testTarget(
            name: "CCloudDomainTests",
            dependencies: ["CCloudDomain"]
        ),
        .testTarget(
            name: "CCloudDataTests",
            dependencies: ["CCloudData", "CCloudDomain"]
        ),
        .testTarget(
            name: "CCloudPresentationTests",
            dependencies: ["CCloudPresentation", "CCloudDomain"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
