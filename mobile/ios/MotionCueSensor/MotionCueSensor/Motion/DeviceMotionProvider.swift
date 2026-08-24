import CoreMotion
import Foundation

final class DeviceMotionProvider: @unchecked Sendable {
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let stateQueue = DispatchQueue(label: "com.motioncue.sensor.motion-state")
    private var latestSample: SensorSample?

    var onSample: ((SensorSample) -> Void)?
    var onAvailabilityChanged: ((Bool) -> Void)?

    init() {
        queue.name = "com.motioncue.sensor.motion"
        queue.maxConcurrentOperationCount = 1
    }

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else {
            onAvailabilityChanged?(false)
            return
        }
        manager.deviceMotionUpdateInterval = 1.0 / 50.0
        // Z is aligned with gravity; this makes stationary mounting diagnostics stable.
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            let sample = self.makeSample(from: motion)
            self.stateQueue.async {
                self.latestSample = sample
            }
            self.onSample?(sample)
        }
        onAvailabilityChanged?(true)
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
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
            timestamp: ProcessInfo.processInfo.systemUptime,
            userAcceleration: vehicleAcceleration(motion.userAcceleration),
            rotationRate: vehicle(motion.rotationRate),
            gravity: vehicleAcceleration(motion.gravity),
            attitude: SensorQuaternion(w: attitude.w, x: attitude.x, y: attitude.y, z: attitude.z),
            isReliable: motion.attitude.quaternion.w.isFinite)
    }
}
