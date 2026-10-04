import CoreBluetooth
import Foundation

struct PeripheralStatus: Equatable {
    var bluetoothLabel = "Bluetooth starting"
    var isPoweredOn = false
    var advertisingEnabled = true
    var isAdvertising = false
    var connectedCentrals = 0
    var applicationState = "Foreground"
    var lastNotificationDate: Date?
    var notificationCount = 0
    var droppedFrameCount = 0
    var lastError: String?
}

final class PeripheralService: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.motioncue.sensor.peripheral")
    private var manager: CBPeripheralManager!
    private var frameCharacteristic: CBMutableCharacteristic?
    private var pendingFrame: PendingSensorFrame?
    private var serviceAdded = false
    private var serviceAdding = false
    private var subscribers: Set<UUID> = []
    private var status = PeripheralStatus()

    var onStatusChanged: ((PeripheralStatus) -> Void)?
    // Accepted by CoreBluetooth, not an acknowledgment of reception by Windows.
    var onFrameQueued: ((UUID) -> Void)?

    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: queue,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: "com.motioncue.sensor.peripheral"])
    }

    func setApplicationBackgrounded(_ isBackgrounded: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self.status.applicationState = isBackgrounded ? "Background" : "Foreground"
            self.publishStatus()
        }
    }

    func setAdvertisingEnabled(_ enabled: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self.status.advertisingEnabled = enabled
            if !enabled {
                self.manager.stopAdvertising()
                self.status.isAdvertising = false
            } else {
                self.startAdvertisingIfReady()
            }
            self.publishStatus()
        }
    }

    func clearPending() {
        queue.async { [weak self] in self?.pendingFrame = nil }
    }

    func publishLatest(_ frame: PendingSensorFrame) {
        queue.async { [weak self] in
            guard let self else { return }
            if self.pendingFrame != nil { self.status.droppedFrameCount += 1 }
            self.pendingFrame = frame
            self.sendLatestIfPossible()
        }
    }

    private func configureServiceIfNeeded() {
        guard !serviceAdded, !serviceAdding else { return }
        let frame = CBMutableCharacteristic(type: CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID),
            properties: [.notify], value: nil, permissions: [])
        let control = CBMutableCharacteristic(type: CBUUID(nsuuid: MotionCueProtocol.controlUUID),
            properties: [.read], value: Data(), permissions: [.readable])
        let service = CBMutableService(type: CBUUID(nsuuid: MotionCueProtocol.serviceUUID), primary: true)
        service.characteristics = [frame, control]
        frameCharacteristic = frame
        serviceAdding = true
        manager.add(service)
    }

    private func startAdvertisingIfReady() {
        guard status.advertisingEnabled, serviceAdded, manager.state == .poweredOn,
              !manager.isAdvertising else { return }
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [CBUUID(nsuuid: MotionCueProtocol.serviceUUID)]])
    }

    private func sendLatestIfPossible() {
        guard let frame = pendingFrame else { return }
        guard frame.isFresh(now: ProcessInfo.processInfo.systemUptime) else {
            pendingFrame = nil
            status.droppedFrameCount += 1
            publishStatus()
            return
        }
        guard manager.state == .poweredOn, !subscribers.isEmpty, let frameCharacteristic else {
            pendingFrame = nil
            return
        }
        if manager.updateValue(frame.data, for: frameCharacteristic, onSubscribedCentrals: nil) {
            pendingFrame = nil
            status.lastNotificationDate = Date()
            status.notificationCount += 1
            publishStatus()
            DispatchQueue.main.async { [weak self] in self?.onFrameQueued?(frame.session) }
        }
        // False: retain one replaceable frame, retry only while the sample is fresh.
    }

    private func publishStatus() {
        let snapshot = status
        DispatchQueue.main.async { [weak self] in self?.onStatusChanged?(snapshot) }
    }
}

extension PeripheralService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        status.isPoweredOn = peripheral.state == .poweredOn
        status.bluetoothLabel = switch peripheral.state {
        case .poweredOn: "Ready"
        case .poweredOff: "Off — enable Bluetooth in Settings"
        case .unauthorized: "Permission denied — check Settings"
        case .unsupported: "BLE peripheral unsupported"
        case .resetting: "Resetting"
        case .unknown: "Starting"
        @unknown default: "Unavailable"
        }
        status.lastError = nil
        if peripheral.state == .poweredOn {
            configureServiceIfNeeded()
            startAdvertisingIfReady()
            status.isAdvertising = peripheral.isAdvertising
        } else {
            serviceAdded = false
            serviceAdding = false
            frameCharacteristic = nil
            pendingFrame = nil
            subscribers.removeAll()
            status.isAdvertising = false
            status.connectedCentrals = 0
        }
        publishStatus()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        serviceAdding = false
        serviceAdded = error == nil
        status.lastError = error.map { "BLE service: \($0.localizedDescription)" }
        if serviceAdded { startAdvertisingIfReady() }
        publishStatus()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        status.isAdvertising = error == nil && peripheral.isAdvertising
        status.lastError = error?.localizedDescription
        publishStatus()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard characteristic.uuid == CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID) else { return }
        subscribers.insert(central.identifier)
        pendingFrame = nil
        status.connectedCentrals = subscribers.count
        publishStatus()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard characteristic.uuid == CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID) else { return }
        subscribers.remove(central.identifier)
        pendingFrame = nil
        status.connectedCentrals = subscribers.count
        publishStatus()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendLatestIfPossible()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] ?? []
        let service = services.first { $0.uuid == CBUUID(nsuuid: MotionCueProtocol.serviceUUID) }
        frameCharacteristic = service?.characteristics?.first {
            $0.uuid == CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID)
        } as? CBMutableCharacteristic
        serviceAdded = frameCharacteristic != nil
        subscribers = Set(frameCharacteristic?.subscribedCentrals?.map(\.identifier) ?? [])
        status.connectedCentrals = subscribers.count
        status.applicationState = "BLE restored — recalibrate"
        pendingFrame = nil
        // Calibration is deliberately not persisted across process termination.
        publishStatus()
    }
}
