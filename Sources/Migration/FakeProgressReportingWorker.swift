// CoreDataPlus

import Foundation

/// Worker that executes a task while faking its progress.
final class FakeProgressReportingWorker: NSObject, ProgressReporting {
  /// The faked progress.
  private(set) lazy var progress: Progress = {
    let progress = Progress(totalUnitCount: Int64(totalUnitCount))
    progress.cancellationHandler = { [weak self] in
      self?.cancellation?()
    }
    progress.pausingHandler = nil // not supported
    return progress
  }()

  /// The total number of units of work to be carried out.
  let totalUnitCount: Int
  /// An estimated interval to carry out all the units of work.
  let estimatedTime: TimeInterval

  private let interval: TimeInterval // progress update interval
  private let fakeTotalUnitCount: Float // 90% of the total, a 10% is left in case the estimated time isn't enough
  private var fakeProgress: Float = 0 // 0 to 1
  private let work: (_ isAlreadyCancelled: Bool) throws -> Void
  private let cancellation: (() -> Void)?

  /// Create a new insance of `FakeProgress`.
  /// - Parameters:
  ///   - estimatedTime: An estimated interval to carry out all the units of work (with a 10% tolerance).
  ///   - totalUnitCount: The total number of units of work to be carried out.
  ///   - interval: How often the progress is updated (default: 1 second).
  ///   - work: The actual work whose execution progress is faked by the underlying `Progress` instance. `isAlreadyCancelled` parameter
  ///   indicates wheter or not the progress has been already cancelled before the task is executed. (in this scenario the `cancellation` block gets called before the `work`block).
  ///   - cancellation: Cancellation closure executed when the underlying `Progress` instance is cancelled.
  init(estimatedTime: TimeInterval,
       totalUnitCount: Int = 100,
       interval: TimeInterval = 1,
       work: @escaping (_ isAlreadyCancelled: Bool) throws -> Void,
       cancellation: (() -> Void)? = nil) {
    self.estimatedTime = estimatedTime
    self.totalUnitCount = totalUnitCount
    self.interval = interval
    self.fakeTotalUnitCount = Float(totalUnitCount) * 0.9
    self.work = work
    self.cancellation = cancellation
  }

  /// Starts faking the progress and executes the work.
  func run() throws {
    let tick = Float(self.interval / self.estimatedTime) // progress increment tick
    let queue = DispatchQueue(label: "\(bundleIdentifier).FakeProgress", qos: .utility, attributes: [])
    var recursiveCheck: () -> Void = {}
    recursiveCheck = { [weak self] in
      guard let self = self else { return }
      guard self.fakeProgress < 1 else { return }

      self.progress.completedUnitCount = Int64(self.fakeTotalUnitCount * self.fakeProgress)
      self.fakeProgress += tick

      queue.asyncAfter(deadline: .now() + self.interval, execute: recursiveCheck)
    }
    queue.async(execute: recursiveCheck)

    try work(self.progress.isCancelled)

    queue.sync { fakeProgress = 1 }
    self.progress.completedUnitCount = self.progress.totalUnitCount
  }
}
