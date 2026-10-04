import XCTest
@testable import MotionCueSensor

final class SensorSafetyTests: XCTestCase {
    func testFreshUniqueSamplesOnly() {
        var gate = SampleFreshnessGate()
        XCTAssertTrue(gate.accept(timestamp: 10, now: 10.04, reliable: true))
        XCTAssertFalse(gate.accept(timestamp: 10, now: 10.05, reliable: true))
        XCTAssertFalse(gate.accept(timestamp: 9.99, now: 10.05, reliable: true))
        XCTAssertTrue(gate.accept(timestamp: 10.02, now: 10.05, reliable: true))
    }

    func testRejectsStaleFutureNonfiniteAndUnreliableSamples() {
        var gate = SampleFreshnessGate()
        XCTAssertFalse(gate.accept(timestamp: 10, now: 10.101, reliable: true))
        XCTAssertFalse(gate.accept(timestamp: 11, now: 10, reliable: true))
        XCTAssertFalse(gate.accept(timestamp: .nan, now: 10, reliable: true))
        XCTAssertFalse(gate.accept(timestamp: 10, now: .infinity, reliable: true))
        XCTAssertFalse(gate.accept(timestamp: 10, now: 10, reliable: false))
        XCTAssertNil(gate.lastTimestamp)
    }

    func testPendingFrameExpiresBeforeBluetoothRetry() {
        let frame = PendingSensorFrame(data: Data([1]), sampleTimestamp: 20, session: UUID())
        XCTAssertTrue(frame.isFresh(now: 20.04))
        XCTAssertFalse(frame.isFresh(now: 20.11))
    }

    func testStationaryCalibrationAndSessionResetFlag() {
        let calibrator = calibrated()
        XCTAssertTrue(calibrator.state.isCalibrated)
        let frame = calibrator.frame(from: sample(1.02), sequence: 0, elapsedMilliseconds: 0, sessionReset: true)
        XCTAssertNotNil(frame)
        XCTAssertTrue(frame!.flags.contains(.clockReset))
    }

    func testDuplicateCalibrationSamplesRejected() {
        let c = VehicleAxisCalibrator()
        c.begin()
        _ = c.acceptForCalibration(sample(1))
        assertInvalid(c.acceptForCalibration(sample(1)))
    }

    func testInterruptedCalibrationRejected() {
        let c = VehicleAxisCalibrator()
        c.begin()
        _ = c.acceptForCalibration(sample(1))
        assertInvalid(c.acceptForCalibration(sample(1.2)))
    }

    func testMovingCalibrationRejected() {
        let c = VehicleAxisCalibrator()
        c.begin()
        for i in 0..<50 { _ = c.acceptForCalibration(sample(Double(i) * 0.02, acceleration: 0.4)) }
        assertInvalid(c.state)
    }

    func testRotatingCalibrationRejected() {
        let c = VehicleAxisCalibrator()
        c.begin()
        for i in 0..<50 { _ = c.acceptForCalibration(sample(Double(i) * 0.02, rotation: 0.2)) }
        assertInvalid(c.state)
    }

    func testInvalidGravityRejected() {
        let c = VehicleAxisCalibrator()
        c.begin()
        for i in 0..<50 { _ = c.acceptForCalibration(sample(Double(i) * 0.02, gravity: 0)) }
        assertInvalid(c.state)
    }

    func testInvalidStreamingSampleStopsCalibration() {
        let c = calibrated()
        XCTAssertNil(c.frame(from: sample(1.02, acceleration: .nan), sequence: 1, elapsedMilliseconds: 20, sessionReset: false))
        assertInvalid(c.state)
    }

    func testLooseMountGuardIsRetainedAndLoggedAsFixedCategory() {
        let c = calibrated()
        let halfAngle = 35.0 * Double.pi / 360
        let moved = SensorSample(timestamp: 1.02, userAcceleration: SensorVector(x: 0, y: 0, z: 0),
            rotationRate: SensorVector(x: 0, y: 0, z: 0), gravity: SensorVector(x: 0, y: 0, z: 9.81),
            attitude: SensorQuaternion(w: cos(halfAngle), x: sin(halfAngle), y: 0, z: 0), isReliable: true)
        XCTAssertNil(c.frame(from: moved, sequence: 1, elapsedMilliseconds: 20, sessionReset: false))
        XCTAssertEqual(c.state.runtimeFailureCode, 6)
    }

    private func calibrated() -> VehicleAxisCalibrator {
        let c = VehicleAxisCalibrator()
        c.begin()
        for i in 0..<50 { _ = c.acceptForCalibration(sample(Double(i) * 0.02)) }
        return c
    }

    func testUnsupportedMountRejected() {
        let c = VehicleAxisCalibrator()
        c.begin()
        for i in 0..<50 {
            _ = c.acceptForCalibration(SensorSample(timestamp: Double(i) * 0.02,
                userAcceleration: SensorVector(x: 0, y: 0, z: 0),
                rotationRate: SensorVector(x: 0, y: 0, z: 0),
                gravity: SensorVector(x: 0, y: 9.81, z: 0), attitude: .identity, isReliable: true))
        }
        assertInvalid(c.state)
    }

    private func sample(_ timestamp: Double, acceleration: Double = 0, rotation: Double = 0, gravity: Double = 9.81) -> SensorSample {
        SensorSample(timestamp: timestamp, userAcceleration: SensorVector(x: acceleration, y: 0, z: 0),
            rotationRate: SensorVector(x: rotation, y: 0, z: 0), gravity: SensorVector(x: 0, y: 0, z: gravity),
            attitude: .identity, isReliable: true)
    }

    private func assertInvalid(_ state: CalibrationState, file: StaticString = #filePath, line: UInt = #line) {
        guard case .invalid = state else { return XCTFail("Expected invalid, got \(state)", file: file, line: line) }
    }
}
