import XCTest
@testable import MotionCueSensor

final class SensorFrameEncoderTests: XCTestCase {
    func testCrc16CcittFalseUsesStandardCheckValue() {
        XCTAssertEqual(Crc16.ccittFalse(Array("123456789".utf8)), 0x29B1)
    }

    func testKnownFrameHasExpectedLittleEndianLayoutAndCrc() throws {
        let frame = SensorFrame(
            sequence: 0x0102_0304,
            elapsedMilliseconds: 0x0A0B_0C0D,
            flags: [.calibrated, .quaternionValid, .clockReset],
            userAcceleration: SensorVector(x: 1.0, y: -0.5, z: 0.25),
            rotationRate: SensorVector(x: 0.125, y: -0.25, z: 0.5),
            gravity: SensorVector(x: 0, y: 0, z: 9.81),
            orientationFromCalibration: .identity,
            accuracy: .high)

        let data = try SensorFrameEncoder.encode(frame)
        let bytes = [UInt8](data)

        XCTAssertEqual(bytes.count, 42)
        XCTAssertEqual(Array(bytes[0..<4]), [0x4D, 0x43, 0x01, 0x51])
        XCTAssertEqual(Array(bytes[4..<12]), [0x04, 0x03, 0x02, 0x01, 0x0D, 0x0C, 0x0B, 0x0A])
        XCTAssertEqual(Array(bytes[12..<18]), [0x00, 0x10, 0x00, 0xF8, 0x00, 0x04])
        XCTAssertEqual(Array(bytes[30..<38]), [0xFF, 0x7F, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(bytes[38], SensorAccuracy.high.rawValue)
        XCTAssertEqual(Array(bytes[40..<42]), [0xAC, 0x73]) // CRC-16/CCITT-FALSE = 0x73AC
        XCTAssertEqual(readUInt16(bytes, at: 40), Crc16.ccittFalse(bytes[0..<40]))
    }

    func testSaturatedAccelerationSetsFlag() throws {
        let frame = fixture(userAcceleration: SensorVector(x: 20, y: 0, z: 0))
        let bytes = [UInt8](try SensorFrameEncoder.encode(frame))
        XCTAssertEqual(bytes[3] & SensorFrameFlags.accelerationSaturated.rawValue, SensorFrameFlags.accelerationSaturated.rawValue)
        XCTAssertEqual(readInt16(bytes, at: 12), Int16.max)
    }

    func testInvalidQuaternionIsRejected() {
        var frame = fixture()
        frame.orientationFromCalibration = SensorQuaternion(w: 0.2, x: 0, y: 0, z: 0)
        XCTAssertThrowsError(try SensorFrameEncoder.encode(frame)) { error in
            XCTAssertEqual(error as? SensorFrameEncoderError, .invalidQuaternion)
        }
    }

    private func fixture(userAcceleration: SensorVector = SensorVector(x: 0, y: 0, z: 0)) -> SensorFrame {
        SensorFrame(sequence: 1, elapsedMilliseconds: 0, flags: [.calibrated, .quaternionValid], userAcceleration: userAcceleration, rotationRate: SensorVector(x: 0, y: 0, z: 0), gravity: SensorVector(x: 0, y: 0, z: 9.81), orientationFromCalibration: .identity, accuracy: .high)
    }

    private func readUInt16(_ bytes: [UInt8], at offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
    }

    private func readInt16(_ bytes: [UInt8], at offset: Int) -> Int16 {
        Int16(bitPattern: readUInt16(bytes, at: offset))
    }
}
