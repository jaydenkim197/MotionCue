import CoreBluetooth
import Foundation

struct PeripheralStatus: Equatable {
    var bluetoothLabel = "Bluetooth starting"
    var isPoweredOn = false
    var isAdvertising = false
    var connectedCentrals = 0
    var lastNotificationDate: Date?
    var lastError: String?
}

final class PeripheralService: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.motioncue.sensor.peripheral")
    private var manager: CBPeripheralManager!
    private var frameCharacteristic: CBMutableCharacteristic?
    private var latestFrame: Data?
    private var serviceAdded = false
    private var shouldAdvertise = true
    private var subscriberCount = 0

    var onStatusChanged: ((PeripheralStatus) -> Void)?
    private var status = PeripheralStatus()

    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: queue)
    }

    func setAdvertisingEnabled(_ enabled: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            self.shouldAdvertise = enabled
            if !enabled {
                self.manager.stopAdvertising()
                self.status.isAdvertising = false
                self.publishStatus()
            } else {
                self.startAdvertisingIfReady()
            }
        }
    }

    func publishLatest(_ frame: Data) {
        queue.async { [weak self] in
            guard let self else { return }
            self.latestFrame = frame
            self.sendLatestIfPossible()
        }
    }

    private func configureService() {
        manager.removeAllServices()
        let frame = CBMutableCharacteristic(
            type: CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID),
            properties: [.notify],
            value: nil,
            permissions: [])
        let control = CBMutableCharacteristic(
            type: CBUUID(nsuuid: MotionCueProtocol.controlUUID),
            properties: [.read],
            value: Data(),
            permissions: [.readable])
        let service = CBMutableService(type: CBUUID(nsuuid: MotionCueProtocol.serviceUUID), primary: true)
        service.characteristics = [frame, control]
        frameCharacteristic = frame
        serviceAdded = false
        manager.add(service)
    }

    private func startAdvertisingIfReady() {
        guard shouldAdvertise, serviceAdded, manager.state == .poweredOn else { return }
        guard !manager.isAdvertising else { return }
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [CBUUID(nsuuid: MotionCueProtocol.serviceUUID)]])
    }

    private func sendLatestIfPossible() {
        guard subscriberCount > 0, let latestFrame, let frameCharacteristic else { return }
        if manager.updateValue(latestFrame, for: frameCharacteristic, onSubscribedCentrals: nil) {
            status.lastNotificationDate = Date()
            publishStatus()
        }
        // A false result means CoreBluetooth is flow-controlled. The latest frame remains in
        // latestFrame and is retried from peripheralManagerIsReady without growing a queue.
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
        case .poweredOn: "Bluetooth ready"
        case .poweredOff: "Bluetooth is off — turn it on in Settings"
        case .unauthorized: "Bluetooth permission is not available"
        case .unsupported: "Bluetooth LE Peripheral is unsupported"
        case .resetting: "Bluetooth is resetting"
        case .unknown: "Bluetooth state is unknown"
        @unknown default: "Bluetooth state is unavailable"
        }
        status.lastError = nil
        if peripheral.state == .poweredOn {
            configureService()
        } else {
            serviceAdded = false
            status.isAdvertising = false
            status.connectedCentrals = 0
        }
        publishStatus()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error {
            status.lastError = "Could not add MotionCue BLE service: \(error.localizedDescription)"
            serviceAdded = false
        } else {
            serviceAdded = true
            startAdvertisingIfReady()
        }
        publishStatus()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        status.isAdvertising = error == nil && peripheral.isAdvertising
        status.lastError = error?.localizedDescription
        publishStatus()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard characteristic.uuid == CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID) else { return }
        subscriberCount += 1
        status.connectedCentrals = subscriberCount
        publishStatus()
        sendLatestIfPossible()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard characteristic.uuid == CBUUID(nsuuid: MotionCueProtocol.sensorFrameUUID) else { return }
        subscriberCount = max(0, subscriberCount - 1)
        status.connectedCentrals = subscriberCount
        publishStatus()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendLatestIfPossible()
    }
}
