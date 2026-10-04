import XCTest
@testable import MotionCueSensor

final class SensorSendCadenceTests: XCTestCase {
    func testFiftyHertzSamplesYieldTwentyFiveHertzFrames() {
        var cadence = SensorSendCadence()
        var times: [Double] = []
        for i in 0..<500 {
            let time = 100 + Double(i) * 0.02
            if cadence.accept(timestamp: time, now: time + 0.005, reliable: true) { times.append(time) }
        }
        XCTAssertEqual(times.count, 250)
        for i in 1..<times.count { XCTAssertEqual(times[i] - times[i - 1], 0.04, accuracy: 0.001) }
    }

    func testSmallSamplingJitterDoesNotHalveTheRateOrCreateBursts() {
        var cadence = SensorSendCadence()
        var times: [Double] = []
        for i in 0..<500 {
            let time = 100 + Double(i) * 0.02 + sin(Double(i)) * 0.0004
            if cadence.accept(timestamp: time, now: time + 0.01, reliable: true) { times.append(time) }
        }
        XCTAssertEqual(times.count, 250)
        for i in 1..<times.count { XCTAssertGreaterThanOrEqual(times[i] - times[i - 1], 0.038) }
    }

    func testStaleDuplicateFutureAndUnreliableSamplesNeverSend() {
        var cadence = SensorSendCadence()
        XCTAssertFalse(cadence.accept(timestamp: 10, now: 11, reliable: true))
        XCTAssertFalse(cadence.accept(timestamp: 12, now: 11, reliable: true))
        XCTAssertFalse(cadence.accept(timestamp: 11, now: 11, reliable: false))
        XCTAssertFalse(cadence.accept(timestamp: .nan, now: 11, reliable: true))
        XCTAssertNil(cadence.nextDeadline)
        XCTAssertTrue(cadence.accept(timestamp: 11, now: 11, reliable: true))
        XCTAssertFalse(cadence.accept(timestamp: 11, now: 11, reliable: true))
        XCTAssertFalse(cadence.accept(timestamp: 10.99, now: 11, reliable: true))
    }

    func testLongGapSkipsMissedSlotsWithoutCatchUp() {
        var cadence = SensorSendCadence()
        XCTAssertTrue(cadence.accept(timestamp: 10, now: 10, reliable: true))
        XCTAssertTrue(cadence.accept(timestamp: 20, now: 20, reliable: true))
        XCTAssertFalse(cadence.accept(timestamp: 20.02, now: 20.02, reliable: true))
        XCTAssertTrue(cadence.accept(timestamp: 20.04, now: 20.04, reliable: true))
    }

    func testRestartAcceptsNewSensorClockEpoch() {
        var cadence = SensorSendCadence()
        XCTAssertTrue(cadence.accept(timestamp: 100, now: 100, reliable: true))
        XCTAssertFalse(cadence.accept(timestamp: 1, now: 1, reliable: true))
        cadence = SensorSendCadence()
        XCTAssertTrue(cadence.accept(timestamp: 1, now: 1, reliable: true))
    }
}
