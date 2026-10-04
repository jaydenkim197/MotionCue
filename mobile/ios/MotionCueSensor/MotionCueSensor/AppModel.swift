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
    private var transmitTimer: Timer?
    private var freshness = SampleFreshnessGate()
    private var sessionStart: TimeInterval?
    private var session = UUID()
    private var sequence: UInt32 = 0
    private var clockResetPending = true
    private var rateWindowStart = ProcessInfo.processInfo.systemUptime
    private var rateWindowCount = 0
    private var isForeground = true

    init() {
        keepScreenAwake = UserDefaults.standard.object(forKey: "keepScreenAwake") as? Bool ?? true
        motionProvider.onAvailabilityChanged = { [weak self] available in
            DispatchQueue.main.async { self?.motionAvailable = available }
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
            self.peripheralStatus = status
            self.updateIdleTimer()
        }
        peripheral.onFrameQueued = { [weak self] session in
            guard let self, session == self.session else { return }
            self.clockResetPending = false
        }
    }

    func start() {
        guard transmitTimer == nil else { return }
        motionProvider.start()
        transmitTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 25.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.transmitLatest() }
        }
    }

    func calibrate() {
        guard motionAvailable, sampleIsFresh else {
            statusMessage = "No fresh motion data. Check permissions in iOS Settings."
            return
        }
        calibrator.begin()
        calibrationState = calibrator.state
        resetTransmission()
        updateIdleTimer()
        statusMessage = "Keep the mounted phone and vehicle still for one second."
    }

    func setAdvertising(_ enabled: Bool) { peripheral.setAdvertisingEnabled(enabled) }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isForeground = true
            motionProvider.start()
            peripheral.setApplicationBackgrounded(false)
        case .background:
            isForeground = false
            peripheral.setApplicationBackgrounded(true)
        case .inactive:
            isForeground = false
        @unknown default: break
        }
        updateIdleTimer()
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
            case .invalid(let reason): statusMessage = reason
            default: break
            }
            updateIdleTimer()
        }
    }

    private func transmitLatest() {
        let now = ProcessInfo.processInfo.systemUptime
        let rateElapsed = now - rateWindowStart
        if rateElapsed >= 1 {
            transmitRate = Double(sentFrameCount - rateWindowCount) / rateElapsed
            rateWindowCount = sentFrameCount
            rateWindowStart = now
        }
        let sample = motionProvider.currentSample()
        sampleIsFresh = sample.map {
            $0.isReliable && SampleFreshnessGate.isFresh(timestamp: $0.timestamp, now: now)
        } ?? false
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
            peripheral.clearPending()
            if case .invalid(let reason) = calibrationState { statusMessage = reason }
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
