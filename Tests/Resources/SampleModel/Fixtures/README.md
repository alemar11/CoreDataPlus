### Run tests from terminal

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

The main problem to have tests working from both Xcode and terminal is that, when building from Xcode, to avoid conflict errors, we need to exclude the compiled binaries described above because Xcode will create them automatically for us, while when building from terminal these binaries must be included and copied.

In the `Package.swift` these inclusions and exclusions are done automatically based on whether or not tests are being run from the command line. 

### Generate new binaries

If you change the models, you are going to need new binaries; you can get them just running some Xcode tests with with a break point set at `ModelVersion._managedObjectModel()`: grab the new binaries stored at that URL and update the ones used in the tests.
