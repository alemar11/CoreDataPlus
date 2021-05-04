//
//  CoreDataMigrator.swift
//  CoreDataMigration-Example
//
//  Created by William Boles on 11/09/2017.
//  Copyright © 2017 William Boles. All rights reserved.
//

import CoreData

protocol CoreDataMigratorProtocol {
  func requiresMigration(at storeURL: URL, toVersion version: CoreDataMigrationVersion) -> Bool
  func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion)
}

/**
 Responsible for handling Core Data model migrations.
 
 The default Core Data model migration approach is to go from earlier version to all possible future versions.
 
 So, if we have 4 model versions (1, 2, 3, 4), you would need to create the following mappings 1 to 4, 2 to 4 and 3 to 4. 
 Then when we create model version 5, we would create mappings 1 to 5, 2 to 5, 3 to 5 and 4 to 5. You can see that for each 
 new version we must create new mappings from all previous versions to the current version. This does not scale well, in the
 above example 4 new mappings have been created. For each new version you must add n-1 new mappings.
 
 Instead the solution below uses an iterative approach where we migrate mutliple times through a chain of model versions.
 
 So, if we have 4 model versions (1, 2, 3, 4), you would need to create the following mappings 1 to 2, 2 to 3 and 3 to 4.
 Then when we create model version 5, we only need to create one additional mapping 4 to 5. This greatly reduces the work
 required when adding a new version.
 */
class CoreDataMigrator: CoreDataMigratorProtocol {
  
  // MARK: - Check
  
  func requiresMigration(at storeURL: URL, toVersion version: CoreDataMigrationVersion) -> Bool {
    guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
      return false
    }
    
    return (CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) != version)
  }
  
  // MARK: - Migration
  
  var tokens = [NSKeyValueObservation]()
  public var progress: Progress?

  func migrateStore(at storeURL: URL, toVersion version: CoreDataMigrationVersion) {
    forceWALCheckpointingForStore(at: storeURL)
    
    var currentURL = storeURL
    let migrationSteps = self.migrationStepsForStore(at: storeURL, toVersion: version)
    
    var migrationProgress: Progress?
    if let progress = progress {
      migrationProgress = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: progress.totalUnitCount)
//      let childProgress = Progress(parent: progress, userInfo: nil)
//                  childProgress.totalUnitCount = 100
    }
    print("--------\(migrationSteps.count)--------\n")
    var i = 0
    for migrationStep in migrationSteps {
      i += 1
      print("------ STEP \(i)\n")
//      migrationProgress?.becomeCurrent(withPendingUnitCount: 1)
//      let manager = MigrationManager(sourceModel: migrationStep.sourceModel,
//                                     destinationModel: migrationStep.destinationModel, progress: migrationProgress!)
      
      
      let manager = LightMigrationManager(sourceModel: migrationStep.sourceModel,
                                     destinationModel: migrationStep.destinationModel)
      manager.estimatedTime = 5
      manager.interval = 0.5
      migrationProgress?.addChild(manager.progress, withPendingUnitCount: 100)
      
      
      // set to false will report migrationProgress for steps without mapping models
      // https://stackoverflow.com/questions/7430180/how-to-show-migration-progress-of-nsmigrationmanager-in-a-uilabel
      //if it's set to NO, we can't migrate due to too much memory
      //if it's set to YES (the default), we get no progress reporting!!
      // https://stackoverflow.com/questions/4720683/fastest-way-to-get-a-reference-to-the-nsmigrationmanager-in-an-automatic-migrati
      
      // http://rayray.github.io/2016/02/03/two-of-many.html
      // https://gist.github.com/alemar11/f5644343a773b9955b09b0edfdffbac8
      //manager.usesStoreSpecificMigrationManager = true
     
      let token = manager.observe(\.migrationProgress, options: [.old, .new]) { (manager, change) in
        print("🔴 \(change.oldValue) --> \(change.newValue) ")
      }
      
      let token2 = manager.observe(\.currentEntityMapping, options: [.new]) { (manager, change) in
        //print("➡️\(change.newValue)")
      }
      
      tokens.append(token)
      tokens.append(token2)
      
      let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
      
      do {
        try manager.migrateStore(from: currentURL, sourceType: NSSQLiteStoreType, options: nil, with: migrationStep.mappingModel, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
      } catch let error {
        fatalError("failed attempting to migrate from \(migrationStep.sourceModel) to \(migrationStep.destinationModel), error: \(error)")
      }
      
      if currentURL != storeURL {
        //Destroy intermediate step's store
        NSPersistentStoreCoordinator.destroyStore(at: currentURL)
      }
      
      currentURL = destinationURL
      migrationProgress?.resignCurrent()
      print("------ STEP \(i) ENDED\n")
    }
    
    NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)
    
    if (currentURL != storeURL) {
      NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }
  }
  
  private func migrationStepsForStore(at storeURL: URL, toVersion destinationVersion: CoreDataMigrationVersion) -> [CoreDataMigrationStep] {
    guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let sourceVersion = CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) else {
      fatalError("unknown store version at URL \(storeURL)")
    }
    
    return migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
  }
  
  private func migrationSteps(fromSourceVersion sourceVersion: CoreDataMigrationVersion, toDestinationVersion destinationVersion: CoreDataMigrationVersion) -> [CoreDataMigrationStep] {
    var sourceVersion = sourceVersion
    var migrationSteps = [CoreDataMigrationStep]()
    
    while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion() {
      let migrationStep = CoreDataMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
      migrationSteps.append(migrationStep)
      
      sourceVersion = nextVersion
    }
    
    return migrationSteps
  }
  
  // MARK: - WAL
  
  func forceWALCheckpointingForStore(at storeURL: URL) {
    guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let currentModel = NSManagedObjectModel.compatibleModelForStoreMetadata(metadata) else {
      return
    }
    
    do {
      let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
      
      let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
      let store = persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
      try persistentStoreCoordinator.remove(store)
    } catch let error {
      fatalError("failed to force WAL checkpointing, error: \(error)")
    }
  }
}

private extension CoreDataMigrationVersion {
  
  // MARK: - Compatible
  
  static func compatibleVersionForStoreMetadata(_ metadata: [String : Any]) -> CoreDataMigrationVersion? {
    let compatibleVersion = CoreDataMigrationVersion.allCases.first {
      let model = NSManagedObjectModel.managedObjectModel(forResource: $0.rawValue)
      
      return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }
    
    return compatibleVersion
  }
}

internal final class MigrationManager: NSMigrationManager, ProgressReporting {

  // MARK: ProgressReporting
  let progress: Progress
  
  override class func willChangeValue(forKey key: String) {
    print(key)
    super.willChangeValue(forKey: key)
  }

  // MARK: NSObject
  override func didChangeValue(forKey key: String) {
    super.didChangeValue(forKey: key)
    guard key == #keyPath(NSMigrationManager.migrationProgress) else { return }
    let progress = self.progress
    progress.completedUnitCount = max(progress.completedUnitCount,
                                      Int64(Float(progress.totalUnitCount) * self.migrationProgress)
    )
    print("🚩", progress.completedUnitCount)
  }

  // MARK: NSMigrationManager
  init(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, progress: Progress) {
    self.progress = progress
    super.init(sourceModel: sourceModel, destinationModel: destinationModel)
  }
}



class LightMigrationManager: NSMigrationManager, ProgressReporting {
  public var totalUnitCount = 100
  public var estimatedTime: TimeInterval = 60
  public var interval: TimeInterval = 1
  
  private lazy var fakeTotalUnitCount: Float = { Float(totalUnitCount) * 0.9 }() // 90% of the total, a 10% is left in case the estimated time isn't enough
  private var fakeProgress: Float = 0 // 0 to 1
  
  private(set) lazy var progress: Progress = {
    let progress = Progress(totalUnitCount: Int64(totalUnitCount))
    progress.cancellationHandler = { [weak self] in
      self?.cancel()
    }
    progress.pausingHandler = nil // not supported
    return progress
  }()
  
  private let manager: NSMigrationManager
  
  open override var usesStoreSpecificMigrationManager: Bool {
    get { manager.usesStoreSpecificMigrationManager }
    set { fatalError("Not implemented.") }
  }
  
  open override var mappingModel: NSMappingModel { manager.mappingModel }
  open override var sourceModel: NSManagedObjectModel { manager.sourceModel }
  open override var destinationModel: NSManagedObjectModel { manager.destinationModel }
  open override var sourceContext: NSManagedObjectContext { manager.sourceContext }
  open override var destinationContext: NSManagedObjectContext { manager.destinationContext }
  
  public override init(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) {
    self.manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
    self.manager.usesStoreSpecificMigrationManager = true // default
    super.init()
  }
  
  open override func migrateStore(from sourceURL: URL, sourceType sStoreType: String, options sOptions: [AnyHashable : Any]? = nil, with mappings: NSMappingModel?, toDestinationURL dURL: URL, destinationType dStoreType: String, destinationOptions dOptions: [AnyHashable : Any]? = nil) throws {
    progress.completedUnitCount = 0 // the NSMigrationManager instance may be used for multiple migrations
    _migrationProgress = 0.0
    let tick = Float(interval / estimatedTime) // progress increment tick
    let queue = DispatchQueue(label: "\("test").FakeProgress", qos: .utility, attributes: [])
    var recursiveCheck: () -> Void = {}
    recursiveCheck = { [weak self] in
      guard let self = self else { return }
      guard self.fakeProgress < 1 else { return }

      let completed = Int64(self.fakeTotalUnitCount * self.fakeProgress)
      if completed > 0 {
        self.migrationProgress = Float(completed)/self.fakeTotalUnitCount
        self.progress.completedUnitCount = Int64(self.fakeTotalUnitCount * self.fakeProgress)
      }
      self.fakeProgress += tick

      queue.asyncAfter(deadline: .now() + self.interval, execute: recursiveCheck)
    }
    queue.async(execute: recursiveCheck)
    sleep(4)
    try manager.migrateStore(from: sourceURL,
                             sourceType: sStoreType,
                             options: sOptions,
                             with: mappings,
                             toDestinationURL: dURL,
                             destinationType: dStoreType,
                             destinationOptions: dOptions)
    
    queue.sync { fakeProgress = 1 }
    self.migrationProgress = 1.0
    progress.completedUnitCount = self.progress.totalUnitCount
  }
  
  open override func sourceEntity(for mEntity: NSEntityMapping) -> NSEntityDescription? {
    manager.sourceEntity(for: mEntity)
  }

  open override func destinationEntity(for mEntity: NSEntityMapping) -> NSEntityDescription? {
    manager.destinationEntity(for: mEntity)
  }
  
  open override func reset() {
    manager.reset()
  }
  
  open override func associate(sourceInstance: NSManagedObject, withDestinationInstance destinationInstance: NSManagedObject, for entityMapping: NSEntityMapping) {
    manager.associate(sourceInstance: sourceInstance, withDestinationInstance: destinationInstance, for: entityMapping)
  }
  
  open override func destinationInstances(forEntityMappingName mappingName: String, sourceInstances: [NSManagedObject]?) -> [NSManagedObject] {
    manager.destinationInstances(forEntityMappingName: mappingName, sourceInstances: sourceInstances)
  }
  
  open override func sourceInstances(forEntityMappingName mappingName: String, destinationInstances: [NSManagedObject]?) -> [NSManagedObject] {
    manager.sourceInstances(forEntityMappingName: mappingName, destinationInstances: destinationInstances)
  }
    
  open override var currentEntityMapping: NSEntityMapping { manager.currentEntityMapping }
  
  private var _migrationProgress: Float = 0.0
  
  override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOCompliance.html#//apple_ref/doc/uid/20002178-SW3
    if key == #keyPath(NSMigrationManager.migrationProgress) {
      return false
    }
    return super.automaticallyNotifiesObservers(forKey: key)
  }
  
  open override var migrationProgress: Float {
    get { _migrationProgress }
    set {
      guard _migrationProgress != newValue else { return }
      willChangeValue(forKey: #keyPath(NSMigrationManager.migrationProgress))
      _migrationProgress = newValue
      didChangeValue(forKey: #keyPath(NSMigrationManager.migrationProgress))
    }
  }
  
  open override var userInfo: [AnyHashable : Any]? {
    get { manager.userInfo }
    set { manager.userInfo = newValue }
  }
  
  private var error: Error?
  //let lock = NSLock()

  open override func cancelMigrationWithError(_ error: Error) {
//    lock.lock()
//    defer { lock.unlock() }
    // TODO: lock
    if !progress.isCancelled {
      self.error = error
      progress.cancel()
    }
  }

  private func cancel() {
    let error = self.error ?? NSError(domain: "test", code: 1, userInfo: nil)
    self.error = nil // the NSMigrationManager instance may be used for multiple migrations
    manager.cancelMigrationWithError(error)
  }
}
