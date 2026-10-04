import Foundation

enum RuntimeEvent: String, Codable {
    case launch, lifecycle, calibration, motion, bluetooth, stream, runtimeGap, summary, sensorSession
}

enum RuntimeState: String, Codable {
    case active, inactive, background, ready, collecting, calibrated, invalid, available, unavailable
    case sessionIdle, sessionRequested, sessionRunning, sessionCompleted, sessionStopped, sessionExpired
    case sessionDenied, sessionInterrupted, sessionTimedOut, sessionUnsupported
}

enum RuntimeMetric: String {
    case build, centrals, powered, advertising, queued, dropped, sampleAgeMs, fresh, rateHz
    case ticks, tickP50Ms, tickP95Ms, tickMaxMs, gapMs, screenAwake, errorPresent
    case queueP50Ms, queueP95Ms, queueMaxMs, queueSampleAgeMs, backpressure
    case sessionFrames, sessionGoal, sessionElapsedSeconds, schedulerError
    case calibrationFailure
}

extension SensorSessionState {
    var runtimeState: RuntimeState {
        switch self {
        case .idle: .sessionIdle
        case .requested: .sessionRequested
        case .running: .sessionRunning
        case .completed: .sessionCompleted
        case .stopped: .sessionStopped
        case .expired: .sessionExpired
        case .denied: .sessionDenied
        case .interrupted: .sessionInterrupted
        case .timedOut: .sessionTimedOut
        case .unsupported: .sessionUnsupported
        }
    }
}

extension SensorSessionSnapshot {
    var runtimeMetrics: [RuntimeMetric: Double] {
        var result: [RuntimeMetric: Double] = [.sessionFrames: Double(frames), .sessionGoal: Double(goal),
            .sessionElapsedSeconds: Double(elapsedSeconds)]
        if let schedulerError { result[.schedulerError] = Double(schedulerError) }
        return result
    }
}

struct RuntimeRecord: Codable {
    let date: Date
    let uptime: TimeInterval
    let event: RuntimeEvent
    let state: RuntimeState?
    let metrics: [String: Double]

    init(event: RuntimeEvent, state: RuntimeState? = nil, metrics: [RuntimeMetric: Double] = [:],
         date: Date = Date(), uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        self.date = date
        self.uptime = uptime
        self.event = event
        self.state = state
        // Only allowlisted numeric metrics: no identifiers, coordinates, raw IMU or error text.
        self.metrics = Dictionary(uniqueKeysWithValues: metrics.compactMap {
            $0.value.isFinite ? ($0.key.rawValue, $0.value) : nil
        })
    }
}

struct RuntimeTickWindow {
    private(set) var lastTick: TimeInterval?
    private(set) var intervals: [Double] = []
    static let capacity = 250

    mutating func tick(_ now: TimeInterval) -> Double? {
        guard now.isFinite else { return nil }
        guard let previous = lastTick else { lastTick = now; return nil }
        guard now > previous else { return nil }
        lastTick = now
        let interval = (now - previous) * 1_000
        if intervals.count == Self.capacity { intervals.removeFirst() }
        intervals.append(interval)
        return interval
    }

    var metrics: [RuntimeMetric: Double] {
        let sorted = intervals.sorted()
        guard !sorted.isEmpty else { return [.ticks: 0] }
        func percentile(_ p: Double) -> Double {
            sorted[max(0, Int(ceil(Double(sorted.count) * p)) - 1)]
        }
        return [.ticks: Double(sorted.count), .tickP50Ms: percentile(0.5),
                .tickP95Ms: percentile(0.95), .tickMaxMs: sorted.last!]
    }
}

final class RuntimeDiagnostics: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.motioncue.sensor.runtime-log", qos: .utility)
    private let directory: URL
    private let byteLimit: Int
    private let encoder: JSONEncoder
    private let pendingSlots = DispatchSemaphore(value: 64)

    init(directory: URL? = nil, byteLimit: Int = 128 * 1_024) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory,
            in: .userDomainMask)[0].appendingPathComponent("Diagnostics", isDirectory: true)
        self.byteLimit = max(1_024, byteLimit)
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
    }

    func record(_ record: RuntimeRecord) {
        guard pendingSlots.wait(timeout: .now()) == .success else { return }
        queue.async { [self] in
            defer { pendingSlots.signal() }
            // Diagnostic I/O failure must never stop motion transmission.
            try? append(record)
        }
    }

    func export() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                do {
                    var data = Data()
                    for name in ["runtime-previous.jsonl", "runtime.jsonl"] {
                        let url = directory.appendingPathComponent(name)
                        if FileManager.default.fileExists(atPath: url.path) {
                            data.append(try Data(contentsOf: url))
                        }
                    }
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("MotionCue-runtime.jsonl")
                    try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                    continuation.resume(returning: url)
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    // Internal synchronous entry point for deterministic file-format/rotation tests.
    func append(_ record: RuntimeRecord) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
        var excludedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try excludedDirectory.setResourceValues(values)
        var line = try encoder.encode(record)
        line.append(0x0A)
        guard line.count <= byteLimit else { return }
        let current = directory.appendingPathComponent("runtime.jsonl")
        let previous = directory.appendingPathComponent("runtime-previous.jsonl")
        let existingSize = (try? fm.attributesOfItem(atPath: current.path)[.size] as? NSNumber)?.intValue ?? 0
        if existingSize + line.count > byteLimit {
            if fm.fileExists(atPath: previous.path) { try fm.removeItem(at: previous) }
            if fm.fileExists(atPath: current.path) { try fm.moveItem(at: current, to: previous) }
        }
        if !fm.fileExists(atPath: current.path) {
            guard fm.createFile(atPath: current.path, contents: nil,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: current)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }
}
