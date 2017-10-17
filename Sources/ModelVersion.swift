//
// CoreDataPlus
//
// Copyright © 2016-2017 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CoreData

private enum ModelVersionKey {
  static let momd = "momd"
  static let omo  = "omo"
  static let mom  = "mom"
}

/// **CoreDataPlus**
///
/// Types adopting the `ModelVersion` protocol can be used to describe a Core Data Model and its versioning.
public protocol ModelVersion: Equatable {

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// List with all versions until now.
  static var allVersions: [Self] { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Current model version.
  static var currentVersion: Self { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Version name.
  var versionName: String { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// The next `ModelVersion` in the progressive migration.
  var successor: Self? { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// NSBundle object containing the model file.
  var modelBundle: Bundle { get }

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Model name.
  var modelName: String { get }

}

extension ModelVersion {

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Model file name.
  var momd: String { return "\(modelName).\(ModelVersionKey.momd)" }

}

extension ModelVersion {

  /// **CoreDataPlus**
  ///
  /// Protocol `ModelVersion`.
  ///
  /// Return the NSManagedObjectModel for this `ModelVersion`.
  public func managedObjectModel() -> NSManagedObjectModel {
    let momURL = modelBundle.url(forResource: versionName, withExtension: "\(ModelVersionKey.mom)", subdirectory: momd)
    print(modelBundle.bundleURL)
    // as of iOS 11, Apple is advising that opening the .omo file for a managed object model is not supported, since the file format can change from release to release
    //let omoURL = modelBundle.url(forResource: versionName, withExtension: "\(ModelVersionKey.omo)", subdirectory: momd)
    //guard let url = omoURL ?? momURL else { fatalError("Model version \(self) not found.") }

    guard let url = momURL else { fatalError("Model version '\(self)' not found.") }
    guard let model = NSManagedObjectModel(contentsOf: url) else { fatalError("Error initializing Managed Object Model: cannot open model at \(url).") }

    return model
  }

}

extension ModelVersion {

  public var successor: Self? { return nil }

}
