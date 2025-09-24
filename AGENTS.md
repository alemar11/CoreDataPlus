# CoreDataPlus Repository Guidelines

## Project Overview
CoreDataPlus is a Swift package for Apple platforms (iOS, macOS, watchOS, tvOS) - no Linux support.

**Structure:**
- `Sources/` — organized by Core Data features (`Migration/`, `Notifications/`, `Transformers/`) plus utility extensions
- `Tests/` — XCTest suites using `<Feature>_Tests.swift` naming, fixtures in `Resources/`, helpers in `Utils/`
- `CoreDataPlus.xcodeproj` — mirrors SwiftPM for Xcode integration
- `Support/` — Info.plists and build collateral
- `bin/` — automation scripts (formatting, linting, DocC)

## Essential Commands
- `swift build` / `swift test` — build and test the package
- `bash bin/format.sh` / `bash bin/lint.sh` — format and lint code
- `bash bin/docc.sh` — generate documentation

## Code Standards
**Style:** 2-space indentation, 120-character wrap, trailing commas in multiline collections. Use lowerCamelCase for functions/properties, UpperCamelCase for types.

**Requirements:** Run formatter before PRs. Address SwiftLint warnings (line length limits, sorted imports). Avoid `@objcMembers`, force unwraps, and double spaces.

## Quality & Contributions
**Testing:** Write XCTest coverage for new features. Place fixtures in `Tests/Resources/`. Add regression tests for bug fixes and performance tests for migrations.

**PRs:** Use imperative commit messages ("Update Swift Package instructions"). Reference issues with `(#123)`. Describe changes, testing, and API impacts. Run format/lint/test scripts before review.
