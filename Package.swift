// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AISubscriptionsLib",
    platforms: [.iOS(.v8)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "AISubscriptionsLib", targets: ["AISubscriptionsLib"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/bizz84/SwiftyStoreKit.git", .upToNextMinor(from: "0.16.4")),
        .package(url: "https://github.com/evgenyneu/keychain-swift", .upToNextMinor(from: "20.0.0")),
        .package(url: "https://github.com/ashleymills/Reachability.swift", .upToNextMinor(from: "5.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
			name: "AISubscriptionsLib",
			dependencies: [
				.product(name: "SwiftyStoreKit", package: "SwiftyStoreKit"),
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "Reachability", package: "Reachability.swift")
			]
		)
    ]
)
