import Foundation

/// Derive 25 Hz opportunities from real 50 Hz acquisition timestamps, not a screen-off UI timer.
/// Late callbacks skip missed slots. They must never create a burst of catch-up frames.
struct SensorSendCadence {
    private(set) var nextDeadline: TimeInterval?
    private var lastTimestamp: TimeInterval?
    private var lastSentTimestamp: TimeInterval?
    static let interval = 1.0 / 25.0
    static let tolerance = 0.002

    mutating func accept(timestamp: TimeInterval, now: TimeInterval, reliable: Bool) -> Bool {
        guard reliable, SampleFreshnessGate.isFresh(timestamp: timestamp, now: now),
              lastTimestamp.map({ timestamp > $0 }) ?? true else { return false }
        lastTimestamp = timestamp
        guard let deadline = nextDeadline else {
            nextDeadline = timestamp + Self.interval
            lastSentTimestamp = timestamp
            return true
        }
        guard timestamp + Self.tolerance >= deadline else { return false }
        guard lastSentTimestamp.map({ timestamp - $0 >= Self.interval - Self.tolerance }) ?? true else { return false }
        let steps = floor(max(0, timestamp - deadline) / Self.interval) + 1
        nextDeadline = deadline + steps * Self.interval
        lastSentTimestamp = timestamp
        return true
    }
}
