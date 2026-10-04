import XCTest
import UIKit
@testable import MotionCueSensor

final class RuntimeDiagnosticsTests: XCTestCase {
    func testTickWindowUsesMonotonicIntervals() {
        var window = RuntimeTickWindow()
        XCTAssertNil(window.tick(10))
        XCTAssertEqual(window.tick(10.04)!, 40, accuracy: 0.001)
        XCTAssertEqual(window.tick(11.04)!, 1_000, accuracy: 0.001)
        XCTAssertEqual(window.metrics[.tickP50Ms]!, 40, accuracy: 0.001)
        XCTAssertEqual(window.metrics[.tickP95Ms]!, 1_000, accuracy: 0.001)
    }

    func testTickWindowIsBounded() {
        var window = RuntimeTickWindow()
        for i in 0...1_000 { _ = window.tick(Double(i) * 0.04) }
        XCTAssertEqual(window.intervals.count, RuntimeTickWindow.capacity)
    }

    func testRegressingOrDuplicateTickDoesNotMoveClockBack() {
        var window = RuntimeTickWindow()
        _ = window.tick(10)
        XCTAssertNil(window.tick(9))
        XCTAssertNil(window.tick(10))
        XCTAssertEqual(window.lastTick, 10)
        XCTAssertEqual(window.tick(10.04)!, 40, accuracy: 0.001)
    }

    func testTransmitTimerFiresDuringTrackingMode() async {
        await MainActor.run {
            var fired = false
            let timer = AppModel.installTransmitTimer { fired = true }
            defer { timer.invalidate() }
            let deadline = Date(timeIntervalSinceNow: 0.2)
            while !fired && Date() < deadline {
                _ = RunLoop.main.run(mode: .tracking, before: deadline)
            }
            XCTAssertTrue(fired, "Details scrolling must not suspend the transmit timer")
        }
    }

    func testNonfiniteTicksAndMetricsAreRejected() throws {
        var window = RuntimeTickWindow()
        _ = window.tick(10)
        XCTAssertNil(window.tick(.nan))
        XCTAssertEqual(window.lastTick, 10)
        let record = RuntimeRecord(event: .summary, metrics: [.rateHz: .infinity, .queued: 12])
        XCTAssertNil(record.metrics["rateHz"])
        XCTAssertEqual(record.metrics["queued"], 12)
        XCTAssertNoThrow(try JSONEncoder().encode(record))
    }

    func testRecordsRoundTripWithoutRawSensorOrIdentifiers() throws {
        try withLog { log, directory in
            try log.append(RuntimeRecord(event: .lifecycle, state: .background, metrics: [.centrals: 1]))
            let data = try Data(contentsOf: directory.appendingPathComponent("runtime.jsonl"))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let record = try decoder.decode(RuntimeRecord.self, from: data)
            XCTAssertEqual(record.state, .background)
            XCTAssertEqual(record.metrics, ["centrals": 1])
            let keys = Set(try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any]).keys)
            XCTAssertEqual(keys, ["date", "uptime", "event", "state", "metrics"])
        }
    }

    func testRotationRetainsOnlyTwoBoundedFiles() throws {
        try withLog { log, directory in
            for i in 0..<100 { try log.append(RuntimeRecord(event: .summary, metrics: [.queued: Double(i)])) }
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
            XCTAssertEqual(Set(files.map(\.lastPathComponent)), ["runtime.jsonl", "runtime-previous.jsonl"])
            for url in files {
                let data = try Data(contentsOf: url)
                XCTAssertLessThanOrEqual(data.count, 1_024)
                XCTAssertEqual(data.last, 0x0A)
            }
        }
    }

    func testAsyncExportFlushesPendingEvents() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let log = RuntimeDiagnostics(directory: directory)
        log.record(RuntimeRecord(event: .launch, metrics: [.build: 3]))
        let url = try await log.export()
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("\"event\":\"launch\""))
        XCTAssertTrue(text.contains("\"build\":3"))
    }

    private func withLog(_ body: (RuntimeDiagnostics, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(RuntimeDiagnostics(directory: directory, byteLimit: 1_024), directory)
    }
}
