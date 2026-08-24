import Foundation

struct SensorSample: Sendable {
    let timestamp: TimeInterval
    let userAcceleration: SensorVector
    let rotationRate: SensorVector
    let gravity: SensorVector
    let attitude: SensorQuaternion
    let isReliable: Bool
}
