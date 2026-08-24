import Foundation

enum MotionCueProtocol {
    static let serviceUUID = UUID(uuidString: "ab31792d-ffdc-4289-88f2-40e384daacb8")!
    static let sensorFrameUUID = UUID(uuidString: "8d747a89-0992-4d86-8fbe-18d2608edc1c")!
    static let controlUUID = UUID(uuidString: "c64b31d3-4ff6-4237-bf55-5a94df0f4324")!
    static let frameLength = 42
    static let version: UInt8 = 1
}

struct SensorVector: Sendable {
    let x: Double
    let y: Double
    let z: Double

    var isFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
    var magnitude: Double { sqrt(x * x + y * y + z * z) }
}

struct SensorQuaternion: Sendable {
    let w: Double
    let x: Double
    let y: Double
    let z: Double

    static let identity = SensorQuaternion(w: 1, x: 0, y: 0, z: 0)

    var isFinite: Bool { w.isFinite && x.isFinite && y.isFinite && z.isFinite }
    var norm: Double { sqrt(w * w + x * x + y * y + z * z) }

    func normalized() -> SensorQuaternion? {
        let length = norm
        guard isFinite, length > 0.000_001 else { return nil }
        return SensorQuaternion(w: w / length, x: x / length, y: y / length, z: z / length)
    }

    func inverse() -> SensorQuaternion {
        SensorQuaternion(w: w, x: -x, y: -y, z: -z)
    }

    func multiplied(by other: SensorQuaternion) -> SensorQuaternion {
        SensorQuaternion(
            w: w * other.w - x * other.x - y * other.y - z * other.z,
            x: w * other.x + x * other.w + y * other.z - z * other.y,
            y: w * other.y - x * other.z + y * other.w + z * other.x,
            z: w * other.z + x * other.y - y * other.x + z * other.w)
    }
}

struct SensorFrame: Sendable {
    var sequence: UInt32
    var elapsedMilliseconds: UInt32
    var flags: SensorFrameFlags
    var userAcceleration: SensorVector
    var rotationRate: SensorVector
    var gravity: SensorVector
    var orientationFromCalibration: SensorQuaternion
    var accuracy: SensorAccuracy
}

struct SensorFrameFlags: OptionSet, Sendable {
    let rawValue: UInt8

    static let calibrated = SensorFrameFlags(rawValue: 1 << 0)
    static let accelerationSaturated = SensorFrameFlags(rawValue: 1 << 1)
    static let rotationRateSaturated = SensorFrameFlags(rawValue: 1 << 2)
    static let gravitySaturated = SensorFrameFlags(rawValue: 1 << 3)
    static let quaternionValid = SensorFrameFlags(rawValue: 1 << 4)
    static let sensorUnreliable = SensorFrameFlags(rawValue: 1 << 5)
    static let clockReset = SensorFrameFlags(rawValue: 1 << 6)
}

enum SensorAccuracy: UInt8, Sendable {
    case unknown = 0, unreliable, low, medium, high
}
