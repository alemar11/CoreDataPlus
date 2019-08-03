![CoreDataPlus](https://raw.githubusercontent.com/tinrobots/CoreDataPlus/assets/coredata_plus.png)

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift)
![Platforms](https://img.shields.io/badge/Platform-iOS%2010%2B%20|%20macOS%2010.12+%20|%20tvOS%2010+%20|%20watchOS%203+-blue.svg) 

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/CoreDataPlus.svg)](https://cocoapods.org/pods/CoreDataPlus)

[![codebeat badge](https://codebeat.co/badges/e07c40a7-3c22-4691-93f5-4c41c7f6152f)](https://codebeat.co/projects/github-com-tinrobots-coredataplus-master)

|Branch|Build Status|Code Coverage|
|----|----|----|
|Master|[![Build Status](https://travis-ci.org/tinrobots/CoreDataPlus.svg?branch=master)](https://travis-ci.org/tinrobots/CoreDataPlus)| ![Code Coverage](https://img.shields.io/codecov/c/github/tinrobots/CoreDataPlus/master.svg)|

## CoreDataPlus
[![GitHub release](https://img.shields.io/github/release/tinrobots/CoreDataPlus.svg)](https://github.com/tinrobots/CoreDataPlus/releases) 

Core data extensions.

- [Requirements](#requirements)
- [Documentation](#documentation)
- [Installation](#installation)
- [License](#license)
- [Contributing](#contributing)

## Requirements

- iOS 11.0+ / macOS 10.13+ / tvOS 11.0+ / watchOS 4.0+
- Xcode 10.2
- Swift 5.0

## Documentation

Documentation is [available online](http://www.tinrobots.org/CoreDataPlus/).

> [http://www.tinrobots.org/CoreDataPlus/](http://www.tinrobots.org/CoreDataPlus/)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build CoreDataPlus 1.0.0+.

To integrate CoreDataPlus into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CoreDataPlus', '~> 2.2.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate CoreDataPlus into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "tinrobots/CoreDataPlus" ~> 2.2.0
```

Run `carthage update` to build the framework and drag the built `CoreDataPlus.framework` into your Xcode project.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 
Once you have your Swift package set up, adding CoreDataPlus as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/tinrobots/CoreDataPlus.git", from: "2.2.0")
]
```

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate CoreDataPlus into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add CoreDataPlus as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/tinrobots/CoreDataPlus.git
```

- Open the new `CoreDataPlus` folder, and drag the `CoreDataPlus.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `CoreDataPlus.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `CoreDataPlus.xcodeproj` folders each with two different versions of the `CoreDataPlus.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `CoreDataPlus.framework`.

- Select the top `CoreDataPlus.framework` for iOS and the bottom one for macOS.

    > You can verify which one you selected by inspecting the build log for your project. The build target for `CoreDataPlus` will be listed as either `CoreDataPlus iOS`, `CoreDataPlus macOS`, `CoreDataPlus tvOS` or `CoreDataPlus watchOS`.


## License

[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://github.com/alemar11/Console/blob/master/LICENSE)

CoreDataPlus is released under the MIT license. See [LICENSE](./LICENSE.md) for details.

## Contributing

Pull requests are welcome!  
[Show your ❤ with a ★](https://github.com/tinrobots/CoreDataPlus/stargazers)
