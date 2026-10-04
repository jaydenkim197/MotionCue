import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var calibrationState: CalibrationState = .ready
    @Published private(set) var peripheralStatus = PeripheralStatus()
    @Published private(set) var motionAvailable = false
    @Published private(set) var sampleIsFresh = false
    @Published private(set) var latestAcceleration = SensorVector(x: 0, y: 0, z: 0)
    @Published private(set) var transmitRate = 0.0
    @Published private(set) var statusMessage = "Keep the mounted phone still for calibration."
    @Published private(set) var diagnosticExportURL: URL?
    @Published private(set) var diagnosticExportFailed = false
    @Published private(set) var lockedSession = SensorSessionSnapshot()
    @Published var keepScreenAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenAwake, forKey: "keepScreenAwake")
            updateIdleTimer()
        }
    }

    var sentFrameCount: Int { peripheralStatus.notificationCount }
    private let motionProvider = DeviceMotionProvider()
    private let calibrator = VehicleAxisCalibrator()
    private let peripheral = PeripheralService()
    private let diagnostics = RuntimeDiagnostics()
    private let sensorSession = LockedSensorSession()
    private var backgroundTransmissionBlocked = false
    private var transmitTimer: Timer?
    private var freshness = SampleFreshnessGate()
    private var sessionStart: TimeInterval?
    private var session = UUID()
    private var sequence: UInt32 = 0
    private var clockResetPending = true
    private var rateWindowStart = ProcessInfo.processInfo.systemUptime
    private var rateWindowCount = 0
    private var isForeground = true
    private var runtimeState: RuntimeState = .active
    private var tickWindow = RuntimeTickWindow()
    private var lastSummary = ProcessInfo.processInfo.systemUptime

    init() {
        keepScreenAwake = UserDefaults.standard.object(forKey: "keepScreenAwake") as? Bool ?? true
        motionProvider.onAvailabilityChanged = { [weak self] available in
            DispatchQueue.main.async {
                guard let self, self.motionAvailable != available else { return }
                self.motionAvailable = available
                self.diagnostics.record(RuntimeRecord(event: .motion,
                    state: available ? .available : .unavailable))
            }
        }
        motionProvider.onError = { [weak self] message in
            DispatchQueue.main.async { self?.statusMessage = message }
        }
        motionProvider.onSample = { [weak self] sample in
            DispatchQueue.main.async { self?.consume(sample) }
        }
        peripheral.onStatusChanged = { [weak self] status in
            guard let self else { return }
            if (status.connectedCentrals > 0) != (self.peripheralStatus.connectedCentrals > 0) {
                self.resetTransmission()
            }
            let old = self.peripheralStatus
            if status.connectedCentrals != old.connectedCentrals || status.isPoweredOn != old.isPoweredOn
                || status.isAdvertising != old.isAdvertising || status.applicationState != old.applicationState
                || status.lastError != old.lastError {
                self.diagnostics.record(RuntimeRecord(event: .bluetooth, state: self.runtimeState,
                    metrics: [.centrals: Double(status.connectedCentrals), .powered: status.isPoweredOn ? 1 : 0,
                              .advertising: status.isAdvertising ? 1 : 0, .errorPresent: status.lastError == nil ? 0 : 1]))
            }
            self.peripheralStatus = status
            if !status.isPoweredOn || status.connectedCentrals == 0 { self.sensorSession.interrupt() }
            self.updateIdleTimer()
        }
        peripheral.onFrameQueued = { [weak self] session in
            guard let self, session == self.session else { return }
            self.clockResetPending = false
            self.sensorSession.frameQueued()
        }
        sensorSession.onUpdate = { [weak self] snapshot in
            guard let self else { return }
            if snapshot.state != self.lockedSession.state {
                self.diagnostics.record(RuntimeRecord(event: .sensorSession,
                    state: snapshot.state.runtimeState, metrics: snapshot.runtimeMetrics))
            }
            self.lockedSession = snapshot
        }
        sensorSession.onEnd = { [weak self] in
            guard let self else { return }
            self.peripheral.clearPending()
            self.backgroundTransmissionBlocked = !self.isForeground
        }
        diagnostics.record(RuntimeRecord(event: .launch, metrics: [
            .build: Double(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0]))
    }

    func start() {
        guard transmitTimer == nil else { return }
        motionProvider.start()
        transmitTimer = Self.installTransmitTimer { [weak self] in self?.transmitLatest() }
    }

    static func installTransmitTimer(action: @escaping @MainActor () -> Void) -> Timer {
        let timer = Timer(timeInterval: 1.0 / 25.0, repeats: true) { _ in
            // The timer is installed only on the main run loop. Avoid an extra queued Task per tick.
            MainActor.assumeIsolated { action() }
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    func calibrate() {
        guard motionAvailable, sampleIsFresh else {
            statusMessage = "No fresh motion data. Check permissions in iOS Settings."
            return
        }
        sensorSession.interrupt()
        calibrator.begin()
        calibrationState = calibrator.state
        resetTransmission()
        updateIdleTimer()
        statusMessage = "Keep the mounted phone and vehicle still for one second."
        diagnostics.record(RuntimeRecord(event: .calibration, state: .collecting))
    }

    func setAdvertising(_ enabled: Bool) { peripheral.setAdvertisingEnabled(enabled) }

    var canStartLockedSession: Bool {
        isForeground && calibrationState.isCalibrated && sampleIsFresh
            && peripheralStatus.isPoweredOn && peripheralStatus.connectedCentrals > 0
            && !lockedSession.state.isBusy
    }

    func startLockedSession() {
        guard canStartLockedSession else { return }
        backgroundTransmissionBlocked = false
        resetTransmission()
        sensorSession.start(eligible: true)
    }

    func stopLockedSession() { sensorSession.stop() }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isForeground = true
            backgroundTransmissionBlocked = false
            runtimeState = .active
            motionProvider.start()
            peripheral.setApplicationBackgrounded(false)
        case .background:
            isForeground = false
            runtimeState = .background
            peripheral.setApplicationBackgrounded(true)
        case .inactive:
            isForeground = false
            runtimeState = .inactive
        @unknown default: break
        }
        updateIdleTimer()
        diagnostics.record(RuntimeRecord(event: .lifecycle, state: runtimeState, metrics: runtimeMetrics()))
    }

    func prepareDiagnosticExport() async {
        recordSummary()
        do {
            diagnosticExportURL = try await diagnostics.export()
            diagnosticExportFailed = false
        } catch { diagnosticExportFailed = true }
    }

    private func runtimeMetrics() -> [RuntimeMetric: Double] {
        var metrics = tickWindow.metrics
        metrics.merge([
            .centrals: Double(peripheralStatus.connectedCentrals), .queued: Double(sentFrameCount),
            .dropped: Double(peripheralStatus.droppedFrameCount), .fresh: sampleIsFresh ? 1 : 0,
            .rateHz: transmitRate, .screenAwake: UIApplication.shared.isIdleTimerDisabled ? 1 : 0,
            .queueP50Ms: peripheralStatus.queueP50Ms, .queueP95Ms: peripheralStatus.queueP95Ms,
            .queueMaxMs: peripheralStatus.queueMaxMs, .queueSampleAgeMs: peripheralStatus.queueSampleAgeMs,
            .backpressure: Double(peripheralStatus.backpressureCount)
        ], uniquingKeysWith: { _, new in new })
        metrics.merge(sensorSession.snapshot.runtimeMetrics, uniquingKeysWith: { _, new in new })
        if let sample = motionProvider.currentSample() {
            metrics[.sampleAgeMs] = max(0, (ProcessInfo.processInfo.systemUptime - sample.timestamp) * 1_000)
        }
        return metrics
    }

    private func recordSummary() {
        diagnostics.record(RuntimeRecord(event: .summary, state: runtimeState, metrics: runtimeMetrics()))
        lastSummary = ProcessInfo.processInfo.systemUptime
    }

    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = keepScreenAwake && isForeground
            && calibrationState.isCalibrated && peripheralStatus.connectedCentrals > 0
    }

    private func resetTransmission() {
        peripheral.clearPending()
        session = UUID()
        sessionStart = nil
        sequence = 0
        clockResetPending = true
        freshness = SampleFreshnessGate()
    }

    private func consume(_ sample: SensorSample) {
        latestAcceleration = sample.userAcceleration
        if case .collecting = calibrator.state {
            calibrationState = calibrator.acceptForCalibration(sample)
            switch calibrationState {
            case .calibrated:
                resetTransmission()
                statusMessage = "Calibration complete."
                diagnostics.record(RuntimeRecord(event: .calibration, state: .calibrated))
            case .invalid(let reason):
                statusMessage = reason
                diagnostics.record(RuntimeRecord(event: .calibration, state: .invalid))
            default: break
            }
            updateIdleTimer()
        }
    }

    private func transmitLatest() {
        let now = ProcessInfo.processInfo.systemUptime
        if let gap = tickWindow.tick(now), gap >= 250 {
            diagnostics.record(RuntimeRecord(event: .runtimeGap, state: runtimeState, metrics: [.gapMs: gap]))
        }
        if now - lastSummary >= 10 { recordSummary() }
        let rateElapsed = now - rateWindowStart
        if rateElapsed >= 1 {
            transmitRate = Double(sentFrameCount - rateWindowCount) / rateElapsed
            rateWindowCount = sentFrameCount
            rateWindowStart = now
        }
        let sample = motionProvider.currentSample()
        let fresh = sample.map {
            $0.isReliable && SampleFreshnessGate.isFresh(timestamp: $0.timestamp, now: now)
        } ?? false
        if fresh != sampleIsFresh {
            sampleIsFresh = fresh
            diagnostics.record(RuntimeRecord(event: .stream, state: runtimeState, metrics: [.fresh: fresh ? 1 : 0]))
        }
        sensorSession.pulse(streamEligible: calibrationState.isCalibrated && peripheralStatus.isPoweredOn
            && peripheralStatus.connectedCentrals > 0)
        guard !backgroundTransmissionBlocked else { peripheral.clearPending(); return }
        guard sampleIsFresh, let sample else {
            peripheral.clearPending()
            return
        }
        guard calibrationState.isCalibrated, peripheralStatus.isPoweredOn,
              peripheralStatus.connectedCentrals > 0,
              freshness.accept(timestamp: sample.timestamp, now: now, reliable: sample.isReliable) else { return }
        if sessionStart == nil { sessionStart = sample.timestamp }
        let elapsed = UInt32(clamping: Int((sample.timestamp - sessionStart!) * 1_000))
        guard let frame = calibrator.frame(from: sample, sequence: sequence,
            elapsedMilliseconds: elapsed, sessionReset: clockResetPending) else {
            calibrationState = calibrator.state
            sensorSession.interrupt()
            peripheral.clearPending()
            if case .invalid(let reason) = calibrationState { statusMessage = reason }
            diagnostics.record(RuntimeRecord(event: .calibration, state: .invalid))
            updateIdleTimer()
            return
        }
        do {
            peripheral.publishLatest(PendingSensorFrame(data: try SensorFrameEncoder.encode(frame),
                sampleTimestamp: sample.timestamp, session: session))
            sequence &+= 1
        } catch {
            statusMessage = "Frame encoding: \(error.localizedDescription)"
            peripheral.clearPending()
        }
    }
}
