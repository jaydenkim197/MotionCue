import CoreMotion
import Foundation

final class DeviceMotionProvider: @unchecked Sendable {
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let stateQueue = DispatchQueue(label: "com.motioncue.sensor.motion-state")
    private var latestSample: SensorSample?

    var onSample: ((SensorSample) -> Void)?
    var onAvailabilityChanged: ((Bool) -> Void)?
    var onError: ((String) -> Void)?

    init() {
        queue.name = "com.motioncue.sensor.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
    }

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard !manager.isDeviceMotionActive else { return }
        guard manager.isDeviceMotionAvailable else {
            onAvailabilityChanged?(false)
            return
        }
        manager.deviceMotionUpdateInterval = 1.0 / 50.0
        // Z is aligned with gravity; this makes stationary mounting diagnostics stable.
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self else { return }
            guard let motion, error == nil else {
                self.stateQueue.async { self.latestSample = nil }
                self.onAvailabilityChanged?(false)
                self.onError?(error?.localizedDescription ?? "Motion data is unavailable.")
                return
            }
            let sample = self.makeSample(from: motion)
            self.stateQueue.async {
                self.latestSample = sample
            }
            self.onSample?(sample)
            self.onAvailabilityChanged?(sample.isReliable)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        stateQueue.async { self.latestSample = nil }
    }

    func currentSample() -> SensorSample? {
        stateQueue.sync { latestSample }
    }

    private func makeSample(from motion: CMDeviceMotion) -> SensorSample {
        // Core Motion expresses CMAcceleration values in g. SensorFrame v1 requires m/s².
        let standardGravity = 9.80665
        // Standard mount: screen up, top edge forward. Device (x right, y top, z screen-out)
        // maps to vehicle (x forward, y right, z down) as (y, x, -z).
        func vehicleAcceleration(_ source: CMAcceleration) -> SensorVector {
            SensorVector(
                x: source.y * standardGravity,
                y: source.x * standardGravity,
                z: -source.z * standardGravity)
        }
        func vehicle(_ source: CMRotationRate) -> SensorVector {
            SensorVector(x: source.y, y: source.x, z: -source.z)
        }
        let attitude = motion.attitude.quaternion
        return SensorSample(
            timestamp: motion.timestamp,
            userAcceleration: vehicleAcceleration(motion.userAcceleration),
            rotationRate: vehicle(motion.rotationRate),
            gravity: vehicleAcceleration(motion.gravity),
            attitude: SensorQuaternion(w: attitude.w, x: attitude.x, y: attitude.y, z: attitude.z),
            isReliable: [attitude.w, attitude.x, attitude.y, attitude.z,
                         motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z,
                         motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z,
                         motion.gravity.x, motion.gravity.y, motion.gravity.z].allSatisfy(\.isFinite))
    }
}
