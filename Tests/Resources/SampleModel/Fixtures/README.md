To run swift tests from terminal we need to have compiled versions of the model and mapping models
that gets copied in the resources bundle during the build phase.

These are the files currently used:

- `SampleModel.momd`
- `V2toV3.cdm`

Apple recommends you create a Resources folder under the Sources folder but it’s not required.
Xcode knows how to handle common Apple resource types out-of-the box. These include (not an exhaustive list):

- Asset Catalogs (.xcassets)
- Storyboards and NIBs (.storyboard, .xib, .nib)
- Core Data models (.xcdatamodel, xcmappingmodel)
- Localization folders (.lproj)
