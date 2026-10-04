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

    var shortLabel: String {
        switch self {
        case .ready: "Ready"
        case .collecting: "Checking"
        case .calibrated: "Calibrated"
        case .invalid: "Recalibrate"
        }
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
        guard sample.isReliable, sample.timestamp.isFinite, sample.userAcceleration.isFinite,
              sample.rotationRate.isFinite, sample.gravity.isFinite,
              sample.attitude.normalized() != nil else {
            state = .invalid(reason: "sensor reading is unavailable")
            return state
        }
        if let previous = samples.last {
            guard sample.timestamp > previous.timestamp, sample.timestamp - previous.timestamp <= 0.1 else {
                state = .invalid(reason: "sensor timing interrupted — recalibrate")
                return state
            }
        }
        samples.append(sample)
        if samples.count < requiredSamples {
            state = .collecting(samples: samples.count)
            return state
        }

        let averageAcceleration = samples.map(\.userAcceleration.magnitude).reduce(0, +) / Double(samples.count)
        let averageGravity = samples.map(\.gravity.magnitude).reduce(0, +) / Double(samples.count)
        let averageRotation = samples.map(\.rotationRate.magnitude).reduce(0, +) / Double(samples.count)
        guard averageAcceleration < 0.20, averageRotation < 0.10 else {
            state = .invalid(reason: "keep the vehicle stationary, then recalibrate")
            return state
        }
        guard (8.0...11.5).contains(averageGravity) else {
            state = .invalid(reason: "gravity reading is unreliable")
            return state
        }
        baselineAttitude = samples.last!.attitude.normalized()
        let averageDown = samples.map(\.gravity.z).reduce(0, +) / Double(samples.count)
        guard averageDown / averageGravity >= cos(20 * .pi / 180) else {
            state = .invalid(reason: "mount screen-up, top edge forward, then recalibrate")
            return state
        }
        previousSample = samples.last
        state = .calibrated
        return state
    }

    func frame(from sample: SensorSample, sequence: UInt32, elapsedMilliseconds: UInt32, sessionReset: Bool) -> SensorFrame? {
        guard state.isCalibrated, let baseline = baselineAttitude else { return nil }
        guard sample.isReliable, sample.userAcceleration.isFinite, sample.rotationRate.isFinite,
              sample.gravity.isFinite, let current = sample.attitude.normalized() else {
            state = .invalid(reason: "sensor reading is unavailable")
            return nil
        }

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
