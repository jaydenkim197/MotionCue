import Foundation

enum SensorFrameEncoderError: Error, Equatable {
    case nonFiniteValue
    case invalidQuaternion
}

enum SensorFrameEncoder {
    private static let accelerationScale = 4096.0
    private static let rotationRateScale = 4096.0
    private static let gravityScale = 2048.0
    private static let quaternionScale = 32767.0

    static func encode(_ frame: SensorFrame) throws -> Data {
        guard frame.userAcceleration.isFinite, frame.rotationRate.isFinite, frame.gravity.isFinite,
              frame.orientationFromCalibration.isFinite else {
            throw SensorFrameEncoderError.nonFiniteValue
        }
        guard !frame.flags.contains(.quaternionValid) || (0.9...1.1).contains(frame.orientationFromCalibration.norm) else {
            throw SensorFrameEncoderError.invalidQuaternion
        }

        var bytes = [UInt8](repeating: 0, count: MotionCueProtocol.frameLength)
        bytes[0] = 0x4D // M
        bytes[1] = 0x43 // C
        bytes[2] = MotionCueProtocol.version
        var flags = frame.flags
        writeUInt32(frame.sequence, to: &bytes, offset: 4)
        writeUInt32(frame.elapsedMilliseconds, to: &bytes, offset: 8)
        flags.formUnion(write(vector: frame.userAcceleration, scale: accelerationScale, to: &bytes, offset: 12, saturation: .accelerationSaturated))
        flags.formUnion(write(vector: frame.rotationRate, scale: rotationRateScale, to: &bytes, offset: 18, saturation: .rotationRateSaturated))
        flags.formUnion(write(vector: frame.gravity, scale: gravityScale, to: &bytes, offset: 24, saturation: .gravitySaturated))
        _ = writeQuaternion(frame.orientationFromCalibration, to: &bytes, offset: 30)
        bytes[3] = flags.rawValue
        bytes[38] = frame.accuracy.rawValue
        let crc = Crc16.ccittFalse(bytes[0..<40])
        writeUInt16(crc, to: &bytes, offset: 40)
        return Data(bytes)
    }

    private static func write(vector: SensorVector, scale: Double, to bytes: inout [UInt8], offset: Int, saturation: SensorFrameFlags) -> SensorFrameFlags {
        let didSaturate = writeInt16(vector.x, scale: scale, to: &bytes, offset: offset)
            || writeInt16(vector.y, scale: scale, to: &bytes, offset: offset + 2)
            || writeInt16(vector.z, scale: scale, to: &bytes, offset: offset + 4)
        return didSaturate ? saturation : []
    }

    private static func writeQuaternion(_ quaternion: SensorQuaternion, to bytes: inout [UInt8], offset: Int) -> Bool {
        writeInt16(quaternion.w, scale: quaternionScale, to: &bytes, offset: offset)
            || writeInt16(quaternion.x, scale: quaternionScale, to: &bytes, offset: offset + 2)
            || writeInt16(quaternion.y, scale: quaternionScale, to: &bytes, offset: offset + 4)
            || writeInt16(quaternion.z, scale: quaternionScale, to: &bytes, offset: offset + 6)
    }

    @discardableResult
    private static func writeInt16(_ value: Double, scale: Double, to bytes: inout [UInt8], offset: Int) -> Bool {
        let rounded = (value * scale).rounded()
        let clamped = min(max(rounded, Double(Int16.min)), Double(Int16.max))
        let raw = Int16(clamped)
        let unsigned = UInt16(bitPattern: raw)
        bytes[offset] = UInt8(unsigned & 0x00FF)
        bytes[offset + 1] = UInt8(unsigned >> 8)
        return clamped != rounded
    }

    private static func writeUInt16(_ value: UInt16, to bytes: inout [UInt8], offset: Int) {
        bytes[offset] = UInt8(value & 0x00FF)
        bytes[offset + 1] = UInt8(value >> 8)
    }

    private static func writeUInt32(_ value: UInt32, to bytes: inout [UInt8], offset: Int) {
        bytes[offset] = UInt8(value & 0x000000FF)
        bytes[offset + 1] = UInt8((value >> 8) & 0x000000FF)
        bytes[offset + 2] = UInt8((value >> 16) & 0x000000FF)
        bytes[offset + 3] = UInt8((value >> 24) & 0x000000FF)
    }
}
