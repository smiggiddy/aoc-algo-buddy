// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SlateKit",
    platforms: [.iOS(.v17), .macCatalyst(.v17)],
    products: [
        .library(name: "SlateKit", targets: ["SlateTerminal", "SlateRender", "SlateIO", "SlateTheme", "SlateInput"]),
    ],
    dependencies: [
        // Prebuilt GhosttyKit.xcframework (libghostty + libghostty-vt) as a binary target.
        // Pin this to a tag once you've verified the header revision you're building against;
        // `branch: "main"` tracks a moving API surface.
        .package(url: "https://github.com/Lakr233/libghostty-spm.git", branch: "main"),
    ],
    targets: [
        // C shim: supplies a libc-backed GhosttyAllocator vtable and a few
        // inline-only helpers that don't import cleanly into Swift.
        .target(
            name: "CGhosttyShim",
            dependencies: [.product(name: "GhosttyKit", package: "libghostty-spm")],
            publicHeadersPath: "include"
        ),

        .target(name: "SlateTheme"),

        .target(name: "SlateInput", dependencies: ["SlateTheme"]),

        .target(
            name: "SlateTerminal",
            dependencies: [
                "CGhosttyShim",
                "SlateInput",
                "SlateTheme",
                .product(name: "GhosttyKit", package: "libghostty-spm"),
            ]
        ),

        .target(name: "SlateIO", dependencies: ["SlateTerminal"]),

        .target(
            name: "SlateRender",
            dependencies: ["SlateTerminal", "SlateTheme"],
            resources: [.process("Shaders.metal")]
        ),

        .testTarget(name: "SlateThemeTests", dependencies: ["SlateTheme"]),
        .testTarget(name: "SlateInputTests", dependencies: ["SlateInput"]),
    ]
)
