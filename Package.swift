// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Modaics",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "Modaics", targets: ["Modaics"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git",
                 from: "10.21.0"),
        .package(
            url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git",
            from: "2.2.0"       // ✅ this tag exists),
        .package(url: "https://github.com/airbnb/lottie-ios.git",
                 from: "4.3.0")
    ],
    targets: [
        .target(
            name: "Modaics",
            dependencies: [
                .product(name: "FirebaseAuth",       package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage",   package: "firebase-ios-sdk"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "Lottie",            package: "lottie-ios")
            ],
            path: "IOS"          //  <-- points at your Xcode sources
        )
    ]
)
