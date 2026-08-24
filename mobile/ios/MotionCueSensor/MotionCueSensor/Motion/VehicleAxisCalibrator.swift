import Foundation

enum CalibrationState: Equatable {
    case ready
    case collecting(samples: Int)
    case calibrated
    case invalid(reason: String)

    var label: String {
        switch self {
        case .ready: "Ready to calibrate"
        case .collecting(let samples): "Checking stationary mount (\(samples)/50)"
        case .calibrated: "Calibrated"
        case .invalid(let reason): "Calibration invalid: \(reason)"
        }
    }

    var isCalibrated: Bool {
        if case .calibrated = self { return true }
        return false
    }
}

final class VehicleAxisCalibrator {
    private let requiredSamples = 50
    private var samples: [SensorSample] = []
    private var baselineAttitude: SensorQuaternion?
    private var previousSample: SensorSample?
    private(set) var state: CalibrationState = .ready

    func begin() {
        samples.removeAll(keepingCapacity: true)
        baselineAttitude = nil
        previousSample = nil
        state = .collecting(samples: 0)
    }

    func acceptForCalibration(_ sample: SensorSample) -> CalibrationState {
        guard case .collecting = state else { return state }
        guard sample.isReliable, sample.userAcceleration.isFinite, sample.gravity.isFinite,
              sample.attitude.normalized() != nil else {
            state = .invalid(reason: "sensor reading is unavailable")
            return state
        }
        samples.append(sample)
        if samples.count < requiredSamples {
            state = .collecting(samples: samples.count)
            return state
        }

        let averageAcceleration = samples.map(\.userAcceleration.magnitude).reduce(0, +) / Double(samples.count)
        let averageGravity = samples.map(\.gravity.magnitude).reduce(0, +) / Double(samples.count)
        guard averageAcceleration < 0.20 else {
            state = .invalid(reason: "keep the vehicle stationary, then recalibrate")
            return state
        }
        guard (8.0...11.5).contains(averageGravity) else {
            state = .invalid(reason: "gravity reading is unreliable")
            return state
        }
        baselineAttitude = samples.last!.attitude.normalized()
        previousSample = samples.last
        state = .calibrated
        return state
    }

    func frame(from sample: SensorSample, sequence: UInt32, elapsedMilliseconds: UInt32, sessionReset: Bool) -> SensorFrame? {
        guard state.isCalibrated, let baseline = baselineAttitude,
              sample.isReliable, let current = sample.attitude.normalized() else { return nil }

        // An abrupt orientation jump with almost no measured rotation is characteristic of a loose mount.
        if let previous = previousSample,
           orientationDeltaDegrees(from: previous.attitude, to: current) > 25,
           sample.rotationRate.magnitude < 0.5 {
            state = .invalid(reason: "possible mount movement detected")
            return nil
        }
        previousSample = sample
        let relative = current.multiplied(by: baseline.inverse()).normalized() ?? .identity
        var flags: SensorFrameFlags = [.calibrated, .quaternionValid]
        if sessionReset { flags.insert(.clockReset) }
        return SensorFrame(
            sequence: sequence,
            elapsedMilliseconds: elapsedMilliseconds,
            flags: flags,
            userAcceleration: sample.userAcceleration,
            rotationRate: sample.rotationRate,
            gravity: sample.gravity,
            orientationFromCalibration: relative,
            accuracy: .high)
    }

    private func orientationDeltaDegrees(from old: SensorQuaternion, to new: SensorQuaternion) -> Double {
        guard let old = old.normalized(), let new = new.normalized() else { return .infinity }
        let dot = abs(old.w * new.w + old.x * new.x + old.y * new.y + old.z * new.z)
        return 2 * acos(min(1, max(-1, dot))) * 180 / .pi
    }
}
