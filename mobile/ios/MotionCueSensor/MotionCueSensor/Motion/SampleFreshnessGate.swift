import Foundation

/// Use the sensor's monotonic acquisition time, not callback delivery time.
struct SampleFreshnessGate {
    static let maximumAge: TimeInterval = 0.1
    private(set) var lastTimestamp: TimeInterval?

    static func isFresh(timestamp: TimeInterval, now: TimeInterval) -> Bool {
        timestamp.isFinite && now.isFinite && timestamp <= now && now - timestamp <= maximumAge
    }

    mutating func accept(timestamp: TimeInterval, now: TimeInterval, reliable: Bool) -> Bool {
        guard reliable, Self.isFresh(timestamp: timestamp, now: now),
              lastTimestamp.map({ timestamp > $0 }) ?? true else { return false }
        lastTimestamp = timestamp
        return true
    }
}

/// One replaceable frame, never a growing backlog. Expire flow-controlled data.
struct PendingSensorFrame {
    let data: Data
    let sampleTimestamp: TimeInterval
    let session: UUID

    func isFresh(now: TimeInterval) -> Bool {
        SampleFreshnessGate.isFresh(timestamp: sampleTimestamp, now: now)
    }
}
