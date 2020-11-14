How to run `swift test` from terminal.

When you open a Swift package with Xcode, Xcode knows how to handle common Apple resource types out-of-the box. These include (not an exhaustive list):

- Asset Catalogs (.xcassets)
- Storyboards and NIBs (.storyboard, .xib, .nib)
- Core Data models (.xcdatamodel, xcmappingmodel)
- Localization folders (.lproj)

That means Xcode will compile `SampleModel.xcdatamodeld` into `SampleModel.md` and  `V2toV3.xcmappingmodel` into `V2toV3.cdm` and will copy them in the Resources folder of the test bundle automatically.

When using the terminal, though, we need to have already compiled versions of the model and mapping models and copy them in the resources bundle during the build phase.
That's why the `Fixtures` folder contains these binaries:

- `SampleModel.momd`
- `V2toV3.cdm`

The main problem to have tests working from both Xcode and terminal is that, when building from Xcode we need to exclude the compiled binaries described above because Xcode will create them automatically for us, while when building from termianl these binaries must be inclueded and copied.

> Since we can't disambiguate if tests are run by terminal or Xcode at Package.swift level, 