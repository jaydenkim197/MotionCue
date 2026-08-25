import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Setup") {
                    Label(model.motionAvailable ? "Motion sensor available" : "Motion permission or device motion needed", systemImage: model.motionAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(model.motionAvailable ? .green : .orange)
                    Text("Mount the iPhone rigidly with its screen facing upward and its top edge pointing toward the front of the vehicle.")
                        .font(.footnote)
                    Button("Calibrate (keep stationary for 1 second)") { model.calibrate() }
                        .disabled(!model.motionAvailable)
                }

                Section("MotionCue connection") {
                    statusRow("Bluetooth", model.peripheralStatus.bluetoothLabel)
                    statusRow("Calibration", model.calibrationState.label)
                    statusRow("Windows centrals", "\(model.peripheralStatus.connectedCentrals)")
                    statusRow("Advertising", model.peripheralStatus.isAdvertising ? "On" : "Off")
                    statusRow("App state", model.peripheralStatus.applicationState)
                    Button(model.peripheralStatus.isAdvertising ? "Stop advertising" : "Start advertising") {
                        model.setAdvertising(!model.peripheralStatus.isAdvertising)
                    }
                    if let error = model.peripheralStatus.lastError {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }

                Section("Streaming") {
                    statusRow("Transmit rate", String(format: "%.1f Hz", model.transmitRate))
                    statusRow("Frames encoded", "\(model.sentFrameCount)")
                    statusRow("Last notification", lastNotificationText)
                    Text(model.statusMessage).font(.footnote)
                    Text("When the phone is locked, iOS preserves the BLE peripheral connection when possible. Continuous sensor transmission while locked is controlled by iOS and is not guaranteed.")
                        .font(.footnote)
                }

                Section("Sensor diagnostic") {
                    statusRow("Vehicle acceleration X", String(format: "%+.3f m/s²", model.latestAcceleration.x))
                    statusRow("Vehicle acceleration Y", String(format: "%+.3f m/s²", model.latestAcceleration.y))
                    statusRow("Vehicle acceleration Z", String(format: "%+.3f m/s²", model.latestAcceleration.z))
                    Text("Diagnostics are displayed only; no sensor or location data is saved or sent outside the nearby BLE connection.")
                        .font(.footnote)
                }
            }
            .navigationTitle("MotionCue Sensor")
        }
    }

    private var lastNotificationText: String {
        guard let date = model.peripheralStatus.lastNotificationDate else { return "None" }
        return String(format: "%.1f seconds ago", max(0, -date.timeIntervalSinceNow))
    }

    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).multilineTextAlignment(.trailing).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView(model: AppModel())
}
