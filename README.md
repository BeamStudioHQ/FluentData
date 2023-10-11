[![MIT license](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square)](https://raw.githubusercontent.com/Beam-Studio/FluentData/main/LICENSE)
[![Swift 5.9 supported](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat-square)](https://github.com/apple/swift)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://swift.org/package-manager/)

![Supports iOS 14+](https://img.shields.io/badge/iOS-14+-dc9656.svg?style=flat-square)
![Supports macOS 12+](https://img.shields.io/badge/macOS-12+-a1b56c.svg?style=flat-square)
![Supports watchOS 7+](https://img.shields.io/badge/watchOS-7+-86c1b9.svg?style=flat-square)
![Supports tvOS 14+](https://img.shields.io/badge/tvOS-14+-7cafc2.svg?style=flat-square)

# FluentData
> an alternative to SwiftData, built with [Fluent](https://github.com/vapor/fluent)

## Features

- Multiple storage options:
    - Memory: database starts fresh everytime, no data persist across app launches
    - File: database is stored locally on device
    - iCloud: database is synced via the iCloud settings of the device (works only on iOS and macOS)
    - Bundle: database is loaded from a file in the bundle, it will be loaded in read-only mode
- Migrations: so your data model can painlessly evolve with your application 
- Query result updates with Combine: update your views automatically when database gets updated
- Middlewares: execute code when data is inserted, updated and/or deleted
- Compatible with Alexey Naumov's vision of [Clean Architecture for SwiftUI](https://nalexn.github.io/clean-architecture-swiftui/).

## Installation

To install FluentData you can follow the [tutorial published by Apple](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)
using the URL for the FluentData repo with the current version:

1. In Xcode, select “File” → “Add Packages...”
1. Enter https://github.com/Beam-Studio/FluentData.git

or you can add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/Beam-Studio/FluentData.git", from: "main")
```

## Usage

You can have a look at the documentation of FluentData [here](https://beam-studio.github.io/FluentData/documentation/fluentdata).

## License

This project is released under the MIT license.
