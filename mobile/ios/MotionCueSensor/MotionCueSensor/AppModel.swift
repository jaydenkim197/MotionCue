import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var calibrationState: CalibrationState = .ready
    @Published private(set) var peripheralStatus = PeripheralStatus()
    @Published private(set) var motionAvailable = false
    @Published private(set) var latestAcceleration = SensorVector(x: 0, y: 0, z: 0)
    @Published private(set) var transmitRate = 0.0
    @Published private(set) var sentFrameCount = 0
    @Published private(set) var statusMessage = "Preparing local sensors"

    private let motionProvider = DeviceMotionProvider()
    private let calibrator = VehicleAxisCalibrator()
    private let peripheral = PeripheralService()
    private var transmitTimer: Timer?
    private var sessionStart: TimeInterval?
    private var sequence: UInt32 = 0
    private var clockResetPending = true
    private var rateWindowStart = Date()
    private var framesInRateWindow = 0

    init() {
        motionProvider.onAvailabilityChanged = { [weak self] available in
            DispatchQueue.main.async { self?.motionAvailable = available }
        }
        motionProvider.onSample = { [weak self] sample in
            DispatchQueue.main.async { self?.consume(sample) }
        }
        peripheral.onStatusChanged = { [weak self] status in
            self?.peripheralStatus = status
        }
    }

    func start() {
        motionProvider.start()
        transmitTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 25.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.transmitLatest() }
        }
    }

    func calibrate() {
        guard motionAvailable else {
            statusMessage = "This iPhone does not provide device motion."
            return
        }
        calibrator.begin()
        calibrationState = calibrator.state
        sessionStart = nil
        clockResetPending = true
        statusMessage = "Keep the mounted phone and vehicle stationary for one second."
    }

    func setAdvertising(_ enabled: Bool) {
        peripheral.setAdvertisingEnabled(enabled)
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            peripheral.setApplicationBackgrounded(false)
        case .background:
            peripheral.setApplicationBackgrounded(true)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func consume(_ sample: SensorSample) {
        latestAcceleration = sample.userAcceleration
        if case .collecting = calibrator.state {
            calibrationState = calibrator.acceptForCalibration(sample)
            switch calibrationState {
            case .calibrated:
                sessionStart = sample.timestamp
                sequence = 0
                clockResetPending = true
                statusMessage = "Calibrated. Waiting for Windows MotionCue."
            case .invalid(let reason):
                statusMessage = "Calibration stopped: \(reason)"
            default: break
            }
        }
    }

    private func transmitLatest() {
        guard let sample = motionProvider.currentSample(), let sessionStart else { return }
        let elapsed = UInt32(clamping: Int((sample.timestamp - sessionStart) * 1_000))
        guard let frame = calibrator.frame(from: sample, sequence: sequence, elapsedMilliseconds: elapsed, sessionReset: clockResetPending) else {
            calibrationState = calibrator.state
            if case .invalid(let reason) = calibrationState { statusMessage = "Streaming stopped: \(reason)" }
            return
        }
        do {
            peripheral.publishLatest(try SensorFrameEncoder.encode(frame))
            sequence &+= 1
            clockResetPending = false
            sentFrameCount += 1
            framesInRateWindow += 1
            let elapsedRate = Date().timeIntervalSince(rateWindowStart)
            if elapsedRate >= 1 {
                transmitRate = Double(framesInRateWindow) / elapsedRate
                framesInRateWindow = 0
                rateWindowStart = Date()
            }
        } catch {
            statusMessage = "Frame encoding failed: \(error.localizedDescription)"
        }
    }
}
