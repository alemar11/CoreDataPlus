// CoreDataPlus

import CoreData

/// A `NSMigrationManager` proxy for lightweight migrations with a customizable faking `migrationProgress`.
public final class LightweightMigrationManager: NSMigrationManager {
  /// An estimated interval (with a 10% tolerance) to carry out the migration (default: 60 seconds).
  public var estimatedTime: TimeInterval = 60
  /// How often the progress is updated (default: 1 second).
  public var updateProgressInterval: TimeInterval = 1
  
  private let manager: NSMigrationManager
  private let totalUnitCount: Int64 = 100
  private lazy var fakeTotalUnitCount: Float = { Float(totalUnitCount) * 0.9 }() // 10% tolerance
  private var fakeProgress: Float = 0 // 0 to 1
  
  public override var usesStoreSpecificMigrationManager: Bool {
    get { manager.usesStoreSpecificMigrationManager }
    set { fatalError("usesStoreSpecificMigrationManager can't be set for lightweight migrations.") }
  }
  
  public override var mappingModel: NSMappingModel { manager.mappingModel }
  public override var sourceModel: NSManagedObjectModel { manager.sourceModel }
  public override var destinationModel: NSManagedObjectModel { manager.destinationModel }
  public override var sourceContext: NSManagedObjectContext { manager.sourceContext }
  public override var destinationContext: NSManagedObjectContext { manager.destinationContext }
  
  public override init(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) {
    self.manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
    self.manager.usesStoreSpecificMigrationManager = true // default
    super.init()
  }
  
  public override func migrateStore(from sourceURL: URL,
                                    sourceType sStoreType: String,
                                    options sOptions: [AnyHashable : Any]? = nil,
                                    with mappings: NSMappingModel?,
                                    toDestinationURL dURL: URL,
                                    destinationType dStoreType: String,
                                    destinationOptions dOptions: [AnyHashable : Any]? = nil) throws {
    let tick = Float(updateProgressInterval / estimatedTime) // progress increment tick
    let queue = DispatchQueue(label: "\(bundleIdentifier).\(String(describing: Self.self)).Progress", qos: .utility)
    var progressUpdater: () -> Void = {}
    progressUpdater = { [weak self] in
      guard let self = self else { return }
      guard self.fakeProgress < 1 else { return }
      
      if self.fakeProgress > 0 {
        let fakeCompletedUnitCount = self.fakeTotalUnitCount * self.fakeProgress
        self.migrationProgress = fakeCompletedUnitCount/self.fakeTotalUnitCount
      }
      self.fakeProgress += tick
      
      queue.asyncAfter(deadline: .now() + self.updateProgressInterval, execute: progressUpdater)
    }
    queue.async(execute: progressUpdater)
    
    do {
      try manager.migrateStore(from: sourceURL,
                               sourceType: sStoreType,
                               options: sOptions,
                               with: mappings,
                               toDestinationURL: dURL,
                               destinationType: dStoreType,
                               destinationOptions: dOptions)
    } catch {
      // stop the fake progress
      queue.sync { fakeProgress = 1 }
      // reset the migrationProgress (as expected for NSMigrationManager instances)
      // before throwing the error without firing KVO.
      // Although cancelling ligthweight migrations is ignored;
      // see comments in cancelMigrationWithError(_:)
      migrationProgress = 0
      throw error
    }
    
    queue.sync { fakeProgress = 1 }
    migrationProgress = 1.0
    // a NSMigrationManager instance may be used for multiple migrations;
    // the migrationProgress should be reset without firing KVO.
    migrationProgress = 0
  }
  
  public override func sourceEntity(for mEntity: NSEntityMapping) -> NSEntityDescription? {
    manager.sourceEntity(for: mEntity)
  }
  
  public override func destinationEntity(for mEntity: NSEntityMapping) -> NSEntityDescription? {
    manager.destinationEntity(for: mEntity)
  }
  
  public override func reset() {
    manager.reset()
  }
  
  public override func associate(sourceInstance: NSManagedObject, withDestinationInstance destinationInstance: NSManagedObject, for entityMapping: NSEntityMapping) {
    manager.associate(sourceInstance: sourceInstance, withDestinationInstance: destinationInstance, for: entityMapping)
  }
  
  public override func destinationInstances(forEntityMappingName mappingName: String, sourceInstances: [NSManagedObject]?) -> [NSManagedObject] {
    manager.destinationInstances(forEntityMappingName: mappingName, sourceInstances: sourceInstances)
  }
  
  public override func sourceInstances(forEntityMappingName mappingName: String, destinationInstances: [NSManagedObject]?) -> [NSManagedObject] {
    manager.sourceInstances(forEntityMappingName: mappingName, destinationInstances: destinationInstances)
  }
  
  public override var currentEntityMapping: NSEntityMapping { manager.currentEntityMapping }
  
  public override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOCompliance.html#//apple_ref/doc/uid/20002178-SW3
    if key == #keyPath(NSMigrationManager.migrationProgress) {
      return false
    }
    return super.automaticallyNotifiesObservers(forKey: key)
  }
  
  private var _migrationProgress: Float = 0.0
  
  public override var migrationProgress: Float {
    get { _migrationProgress }
    set {
      guard _migrationProgress != newValue else { return }
      
      if newValue == 0 { // reset if manager is reused
        _migrationProgress = newValue
      } else {
        willChangeValue(forKey: #keyPath(NSMigrationManager.migrationProgress))
        _migrationProgress = newValue
        didChangeValue(forKey: #keyPath(NSMigrationManager.migrationProgress))
      }
    }
  }
  
  public override var userInfo: [AnyHashable : Any]? {
    get { manager.userInfo }
    set { manager.userInfo = newValue }
  }
  
  public override func cancelMigrationWithError(_ error: Error) {
    // During my tests, cancelling a lightweight migration doesn't work
    // probably due to performance optimizations
    manager.cancelMigrationWithError(error)
  }
}
