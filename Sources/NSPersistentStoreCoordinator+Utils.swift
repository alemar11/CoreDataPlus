//
// CoreDataPlus
//
// Copyright © 2016-2020 Tinrobots.
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

extension NSPersistentStoreCoordinator {
  /// **CoreDataPlus**
  ///
  /// Safely deletes a store at a given url.
  public static func destroyStore(at url: URL) throws {
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    /// destroyPersistentStore safely deletes everything in the database and leaves an empty database behind.
    try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)

    let fileManager = FileManager.default

    let storePath = url.path
    try fileManager.removeItem(atPath: storePath)

    let writeAheadLog = storePath + "-wal"
    _ = try? fileManager.removeItem(atPath: writeAheadLog)

    let sharedMemoryfile = storePath + "-shm"
    _ = try? fileManager.removeItem(atPath: sharedMemoryfile)
  }

  /// **CoreDataPlus**
  ///
  /// Replaces the destination persistent store with the source store.
  /// - Attention: The stored must be SQLite
  public static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws {
    let persistentStoreCoordinator = self.init(managedObjectModel: NSManagedObjectModel())
    try persistentStoreCoordinator.replacePersistentStore(at: targetURL, destinationOptions: nil, withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
  }
}

// About moving stores disabling the WAL journaling mode
// https://developer.apple.com/library/archive/qa/qa1809/_index.html
//
//  ```
//  let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]] // the migration will be done without -wal and -shm files
//  try! psc!.migratePersistentStore(store, to: url, options: options, withType: NSSQLiteStoreType)
//  ```
