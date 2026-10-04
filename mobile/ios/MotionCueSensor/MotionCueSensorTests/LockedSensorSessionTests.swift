import XCTest
@testable import MotionCueSensor

@MainActor
final class LockedSensorSessionTests: XCTestCase {
    func testNeedsExplicitEligibleStart() {
        let scheduler = TestSessionScheduler()
        let session = LockedSensorSession(scheduler: scheduler)
        session.start(eligible: false)
        XCTAssertEqual(session.snapshot.state, .idle)
        XCTAssertEqual(scheduler.jobs.count, 0)
        session.frameQueued()
        XCTAssertEqual(session.snapshot.frames, 0)
    }

    func testDuplicateStartDoesNotSubmitTwice() {
        let scheduler = TestSessionScheduler()
        let session = LockedSensorSession(scheduler: scheduler)
        session.start(eligible: true)
        session.start(eligible: true)
        XCTAssertEqual(scheduler.jobs.count, 1)
        XCTAssertEqual(session.snapshot.state, .requested)
        session.frameQueued()
        XCTAssertEqual(session.snapshot.frames, 0, "No progress before iOS grants the task")
    }

    func testProgressCountsQueuedFramesNotElapsedTicks() {
        let scheduler = TestSessionScheduler()
        var time = ContinuousClock.now
        let session = LockedSensorSession(scheduler: scheduler, now: { time })
        session.start(eligible: true)
        let task = scheduler.launch(0)
        time = time.advanced(by: .seconds(2))
        session.pulse(streamEligible: true)
        XCTAssertEqual(session.snapshot.frames, 0)
        session.frameQueued()
        session.frameQueued()
        time = time.advanced(by: .seconds(1))
        session.pulse(streamEligible: true)
        XCTAssertEqual(task.reports.last?.0, 2)
        XCTAssertEqual(task.reports.last?.1, 45_000)
    }

    func testGoalCompletesOnceWithoutAutomaticResubmission() {
        let scheduler = TestSessionScheduler()
        let session = LockedSensorSession(scheduler: scheduler, goal: 3)
        session.start(eligible: true)
        let task = scheduler.launch(0)
        for _ in 0..<4 { session.frameQueued() }
        session.stop()
        XCTAssertEqual(session.snapshot.state, .completed)
        XCTAssertEqual(session.snapshot.frames, 3)
        XCTAssertEqual(task.completions, [true])
        XCTAssertEqual(scheduler.jobs.count, 1)
        XCTAssertEqual(scheduler.cancelled.count, 1)
        XCTAssertNil(task.onExpiration)
    }

    func testStopExpirationAndStreamInterruptionEndUnsuccessfully() {
        for outcome in [SensorSessionState.stopped, .expired, .interrupted] {
            let scheduler = TestSessionScheduler()
            let session = LockedSensorSession(scheduler: scheduler)
            var ends = 0
            session.onEnd = { ends += 1 }
            session.start(eligible: true)
            let task = scheduler.launch(0)
            session.frameQueued()
            switch outcome {
            case .stopped: session.stop()
            case .expired: task.onExpiration?()
            default: session.pulse(streamEligible: false)
            }
            session.frameQueued()
            session.stop()
            XCTAssertEqual(session.snapshot.state, outcome)
            XCTAssertEqual(session.snapshot.frames, 1)
            XCTAssertEqual(task.completions, [false])
            XCTAssertEqual(ends, 1)
        }
    }

    func testHardDeadlineIncludesContinuousClockSleepGap() {
        let scheduler = TestSessionScheduler()
        var time = ContinuousClock.now
        let session = LockedSensorSession(scheduler: scheduler, timeLimit: 100, now: { time })
        session.start(eligible: true)
        let task = scheduler.launch(0)
        time = time.advanced(by: .seconds(101))
        session.frameQueued()
        XCTAssertEqual(session.snapshot.state, .timedOut)
        XCTAssertEqual(session.snapshot.frames, 0)
        XCTAssertEqual(task.completions, [false])
    }

    func testNoProgressFailsRatherThanFakingAHeartbeat() {
        let scheduler = TestSessionScheduler()
        var time = ContinuousClock.now
        let session = LockedSensorSession(scheduler: scheduler, now: { time })
        session.start(eligible: true)
        let task = scheduler.launch(0)
        time = time.advanced(by: .seconds(5))
        session.pulse(streamEligible: true)
        XCTAssertEqual(session.snapshot.state, .interrupted)
        XCTAssertEqual(task.completions, [false])
        XCTAssertEqual(session.snapshot.frames, 0)
    }

    func testLaunchTimeoutAndLateTaskCannotReviveStoppedJob() {
        let scheduler = TestSessionScheduler()
        var time = ContinuousClock.now
        let session = LockedSensorSession(scheduler: scheduler, now: { time })
        session.start(eligible: true)
        time = time.advanced(by: .seconds(10))
        session.pulse(streamEligible: true)
        XCTAssertEqual(session.snapshot.state, .denied)
        let late = scheduler.launch(0)
        XCTAssertEqual(late.completions, [false])
        XCTAssertEqual(session.snapshot.state, .denied)
    }

    func testDistinctJobRejectsOldCallbacksAfterNewStart() {
        let scheduler = TestSessionScheduler()
        let session = LockedSensorSession(scheduler: scheduler)
        session.start(eligible: true)
        session.stop()
        session.start(eligible: true)
        XCTAssertNotEqual(scheduler.jobs[0].identifier, scheduler.jobs[1].identifier)
        let old = scheduler.launch(0)
        scheduler.jobs[0].onFailure(3)
        XCTAssertEqual(old.completions, [false])
        XCTAssertEqual(session.snapshot.state, .requested)
        let current = scheduler.launch(1)
        session.frameQueued()
        XCTAssertEqual(session.snapshot.state, .running)
        XCTAssertEqual(session.snapshot.frames, 1)
        XCTAssertTrue(current.completions.isEmpty)
    }

    func testFailureRetainsOnlyNumericError() {
        let scheduler = TestSessionScheduler()
        let session = LockedSensorSession(scheduler: scheduler)
        session.start(eligible: true)
        scheduler.jobs[0].onFailure(4)
        XCTAssertEqual(session.snapshot.state, .denied)
        XCTAssertEqual(session.snapshot.schedulerError, 4)
        XCTAssertEqual(scheduler.jobs.count, 1)
        XCTAssertEqual(session.snapshot.runtimeMetrics[.schedulerError], 4)
    }

    func testUnsupportedOSDoesNotSubmit() {
        let scheduler = TestSessionScheduler()
        scheduler.isSupported = false
        let session = LockedSensorSession(scheduler: scheduler)
        session.start(eligible: true)
        XCTAssertEqual(session.snapshot.state, .unsupported)
        XCTAssertTrue(scheduler.jobs.isEmpty)
    }

    func testEndedElapsedTimeIsFrozenUntilAnExplicitRestart() {
        let scheduler = TestSessionScheduler()
        var time = ContinuousClock.now
        let session = LockedSensorSession(scheduler: scheduler, now: { time })
        session.start(eligible: true)
        _ = scheduler.launch(0)
        time = time.advanced(by: .seconds(2))
        session.stop()
        time = time.advanced(by: .seconds(100))
        XCTAssertEqual(session.snapshot.elapsedSeconds, 2)
        session.start(eligible: true)
        XCTAssertEqual(session.snapshot.elapsedSeconds, 0)
    }

    func testProgressReportingIsThrottledAndFreshProgressKeepsJobAlive() {
        let scheduler = TestSessionScheduler()
        var time = ContinuousClock.now
        let session = LockedSensorSession(scheduler: scheduler, now: { time })
        session.start(eligible: true)
        let task = scheduler.launch(0)
        for _ in 0..<100 {
            session.frameQueued()
            session.pulse(streamEligible: true)
        }
        XCTAssertEqual(task.reports.count, 1)
        time = time.advanced(by: .seconds(4))
        session.frameQueued()
        time = time.advanced(by: .seconds(4))
        session.pulse(streamEligible: true)
        XCTAssertEqual(session.snapshot.state, .running)
        XCTAssertEqual(task.reports.last?.0, 101)
    }
}

@MainActor
private final class TestSessionScheduler: SensorSessionScheduling {
    struct Job {
        let identifier: String
        let onLaunch: (SensorSessionTask) -> Void
        let onFailure: (Int) -> Void
    }
    var isSupported = true
    var jobs: [Job] = []
    var cancelled: [String] = []

    func submit(identifier: String, onLaunch: @escaping (SensorSessionTask) -> Void,
                onFailure: @escaping (Int) -> Void) {
        jobs.append(Job(identifier: identifier, onLaunch: onLaunch, onFailure: onFailure))
    }
    func cancel(identifier: String) { cancelled.append(identifier) }
    func launch(_ index: Int) -> TestSessionTask {
        let task = TestSessionTask()
        jobs[index].onLaunch(task)
        return task
    }
}

@MainActor
private final class TestSessionTask: SensorSessionTask {
    var onExpiration: (() -> Void)?
    var reports: [(Int, Int)] = []
    var completions: [Bool] = []
    func report(frames: Int, goal: Int) { reports.append((frames, goal)) }
    func complete(success: Bool) { completions.append(success) }
}
