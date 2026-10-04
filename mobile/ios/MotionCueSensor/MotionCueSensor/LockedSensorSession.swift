@preconcurrency import BackgroundTasks
import Foundation

enum SensorSessionState: String {
    case idle, requested, running, completed, stopped, expired, denied, interrupted, timedOut, unsupported

    var isBusy: Bool { self == .requested || self == .running }
    var label: String {
        switch self {
        case .idle: "Not started"
        case .requested: "Starting"
        case .running: "Running"
        case .completed: "Completed"
        case .stopped: "Stopped"
        case .expired: "Ended by iOS"
        case .denied: "Not allowed"
        case .interrupted: "Stream interrupted"
        case .timedOut: "Time limit"
        case .unsupported: "Requires iOS 26"
        }
    }
}

struct SensorSessionSnapshot: Equatable {
    var state: SensorSessionState = .idle
    var frames = 0
    var goal = 45_000
    var elapsedSeconds = 0
    var schedulerError: Int?
}

@MainActor
protocol SensorSessionTask: AnyObject {
    var onExpiration: (() -> Void)? { get set }
    func report(frames: Int, goal: Int)
    func complete(success: Bool)
}

@MainActor
protocol SensorSessionScheduling {
    var isSupported: Bool { get }
    func submit(identifier: String, onLaunch: @escaping (SensorSessionTask) -> Void,
                onFailure: @escaping (Int) -> Void)
    func cancel(identifier: String)
}

/// A finite, explicitly started job, not a renewable background keep-alive.
/// Progress counts fresh frames actually queued by CoreBluetooth, never timer ticks or Windows ACKs.
@MainActor
final class LockedSensorSession {
    var onUpdate: ((SensorSessionSnapshot) -> Void)?
    var onEnd: (() -> Void)?

    private let scheduler: SensorSessionScheduling
    private let now: () -> ContinuousClock.Instant
    private let goal: Int
    private let timeLimit: Double
    private var state: SensorSessionState = .idle
    private var frames = 0
    private var schedulerError: Int?
    private var identifier: String?
    private var task: SensorSessionTask?
    private var requestedAt: ContinuousClock.Instant?
    private var startedAt: ContinuousClock.Instant?
    private var lastFrameAt: ContinuousClock.Instant?
    private var lastReportAt: ContinuousClock.Instant?
    private var endedAt: ContinuousClock.Instant?

    init(scheduler: SensorSessionScheduling? = nil, goal: Int = 45_000,
         timeLimit: Double = 35 * 60, now: @escaping () -> ContinuousClock.Instant = { .now }) {
        self.scheduler = scheduler ?? AppleSensorSessionScheduler()
        self.goal = max(1, goal)
        self.timeLimit = max(1, timeLimit)
        self.now = now
    }

    var snapshot: SensorSessionSnapshot {
        SensorSessionSnapshot(state: state, frames: frames, goal: goal,
            elapsedSeconds: Int(max(0, elapsed(since: startedAt, until: endedAt))), schedulerError: schedulerError)
    }

    func start(eligible: Bool) {
        guard eligible, !state.isBusy else { return }
        guard scheduler.isSupported else { state = .unsupported; publish(); return }
        // Register an exact handler for each job. The plist permits this prefix; no wildcard handler matching.
        let job = "com.motioncue.sensor.lock-session.\(UUID().uuidString)"
        identifier = job
        frames = 0
        schedulerError = nil
        task = nil
        requestedAt = now()
        startedAt = nil
        lastFrameAt = nil
        lastReportAt = nil
        endedAt = nil
        state = .requested
        publish()
        scheduler.submit(identifier: job, onLaunch: { [weak self] task in
            guard let self, self.identifier == job, self.state == .requested else {
                task.complete(success: false)
                return
            }
            self.task = task
            self.startedAt = self.now()
            self.lastFrameAt = self.startedAt
            task.onExpiration = { [weak self] in
                guard let self, self.identifier == job else { return }
                self.finish(.expired)
            }
            self.state = .running
            self.publish()
        }, onFailure: { [weak self] code in
            guard let self, self.identifier == job, self.state.isBusy else { return }
            self.schedulerError = code
            self.finish(.denied)
        })
    }

    func stop() { finish(.stopped) }

    func interrupt() { finish(.interrupted) }

    func pulse(streamEligible: Bool) {
        guard state.isBusy else { return }
        guard streamEligible else { finish(.interrupted); return }
        if state == .requested {
            if elapsed(since: requestedAt) >= 10 { finish(.denied) }
            return
        }
        guard elapsed(since: startedAt) < timeLimit else { finish(.timedOut); return }
        guard elapsed(since: lastFrameAt) < 5 else { finish(.interrupted); return }
        if lastReportAt == nil || elapsed(since: lastReportAt) >= 1 { publish() }
    }

    func frameQueued() {
        guard state == .running else { return }
        guard elapsed(since: startedAt) < timeLimit else { finish(.timedOut); return }
        frames += 1
        lastFrameAt = now()
        if frames >= goal { finish(.completed) }
    }

    private func finish(_ result: SensorSessionState) {
        guard state.isBusy else { return }
        state = result
        endedAt = now()
        if let identifier { scheduler.cancel(identifier: identifier) }
        identifier = nil
        task?.onExpiration = nil
        task?.report(frames: frames, goal: goal)
        task?.complete(success: result == .completed)
        task = nil
        publish()
        onEnd?()
        // No resubmission or chained jobs: only another foreground button tap can start a new job.
    }

    private func publish() {
        lastReportAt = now()
        task?.report(frames: frames, goal: goal)
        onUpdate?(snapshot)
    }

    private func elapsed(since instant: ContinuousClock.Instant?, until end: ContinuousClock.Instant? = nil) -> Double {
        guard let instant else { return 0 }
        // ContinuousClock includes time spent asleep, unlike the IMU/systemUptime measurement clock.
        let parts = instant.duration(to: end ?? now()).components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}

@MainActor
final class AppleSensorSessionScheduler: SensorSessionScheduling {
    var isSupported: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    func submit(identifier: String, onLaunch: @escaping (SensorSessionTask) -> Void,
                onFailure: @escaping (Int) -> Void) {
        guard #available(iOS 26.0, *) else { onFailure(1); return }
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            MainActor.assumeIsolated {
                guard let continued = task as? BGContinuedProcessingTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                onLaunch(AppleSensorSessionTask(continued))
            }
        }
        guard registered else { onFailure(3); return }
        let request = BGContinuedProcessingTaskRequest(identifier: identifier,
            title: "MotionCue sensor session", subtitle: "45,000 frames · about 30 min")
        request.strategy = .fail
        // Default CPU resources only: no GPU, location, audio or HealthKit capability.
        // Configure on the foreground main actor, then hand off once. No further request mutation.
        DispatchQueue.global(qos: .userInitiated).async {
            let result: (Error?) -> Void = { error in
                guard let error else { return }
                let nsError = error as NSError
                let code = nsError.domain == BGTaskScheduler.errorDomain ? nsError.code : 0
                DispatchQueue.main.async { onFailure(code) }
            }
            if #available(iOS 27.0, *) {
                BGTaskScheduler.shared.submitTaskRequest(request, completionHandler: result)
            } else {
                do { try BGTaskScheduler.shared.submit(request) }
                catch { result(error) }
            }
        }
    }

    func cancel(identifier: String) { BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier) }
}

@available(iOS 26.0, *)
@MainActor
private final class AppleSensorSessionTask: SensorSessionTask {
    var onExpiration: (() -> Void)?
    private let task: BGContinuedProcessingTask
    private var didComplete = false

    init(_ task: BGContinuedProcessingTask) {
        self.task = task
        task.expirationHandler = { [weak self] in
            DispatchQueue.main.async { self?.onExpiration?() }
        }
    }

    func report(frames: Int, goal: Int) {
        guard !didComplete else { return }
        task.progress.totalUnitCount = Int64(goal)
        task.progress.completedUnitCount = Int64(min(frames, goal))
    }

    func complete(success: Bool) {
        guard !didComplete else { return }
        didComplete = true
        task.expirationHandler = nil
        task.setTaskCompleted(success: success)
    }
}
