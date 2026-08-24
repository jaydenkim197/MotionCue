import Foundation

enum Crc16 {
    /// CRC-16/CCITT-FALSE: poly 0x1021, initial value 0xFFFF, no reflection or final xor.
    static func ccittFalse(_ bytes: some Collection<UInt8>) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = (crc & 0x8000) == 0 ? crc << 1 : (crc << 1) ^ 0x1021
            }
        }
        return crc
    }
}
