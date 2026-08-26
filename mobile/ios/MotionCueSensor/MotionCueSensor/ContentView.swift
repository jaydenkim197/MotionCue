import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                connectionCard
                sendingCard
                helpCard
                diagnostics
                privacyNote
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color("Canvas").ignoresSafeArea())
        .tint(Color("Accent"))
        .animation(.easeOut(duration: 0.18), value: model.peripheralStatus.connectedCentrals)
        .animation(.easeOut(duration: 0.18), value: model.calibrationState.label)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color("Accent"))
                Text("M").font(.system(size: 21, weight: .bold, design: .rounded)).foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("MotionCue").font(.system(size: 24, weight: .semibold, design: .rounded)).foregroundStyle(Color("Text"))
                Text("Phone motion sensor").font(.subheadline).foregroundStyle(Color("TextMuted"))
            }
            Spacer(minLength: 8)
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle().fill(Color("Accent")).frame(width: 8, height: 8)
            Text(connectionShortLabel).font(.caption.weight(.semibold)).foregroundStyle(Color("Text"))
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color("Surface"), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var connectionCard: some View {
        MotionCueCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PHONE SENSOR").sectionLabel()
                    Text(connectionTitle).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color("Text"))
                }
                Spacer()
                Image(systemName: model.peripheralStatus.connectedCentrals > 0 ? "checkmark.circle.fill" : "iphone.radiowaves.left.and.right")
                    .font(.title3).foregroundStyle(Color("Accent")).accessibilityHidden(true)
            }
            Text(connectionHelp).font(.subheadline).foregroundStyle(Color("TextSecondary")).fixedSize(horizontal: false, vertical: true)
            Divider().overlay(Color("Border"))
            HStack(spacing: 12) {
                Button("Calibrate") { model.calibrate() }
                    .buttonStyle(MotionCuePrimaryButtonStyle()).disabled(!model.motionAvailable)
                    .accessibilityHint("Keep the mounted iPhone still for one second.")
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.calibrationState.label).font(.subheadline.weight(.semibold)).foregroundStyle(Color("Text"))
                    Text(model.motionAvailable ? "Keep the phone mounted and still." : "Motion permission is needed.")
                        .font(.caption).foregroundStyle(Color("TextMuted"))
                }
            }
        }
    }

    private var sendingCard: some View {
        MotionCueCard {
            Text("SENDING").sectionLabel()
            Text(sendingTitle).font(.system(size: 17, weight: .semibold)).foregroundStyle(Color("Text"))
            Text(sendingHelp).font(.subheadline).foregroundStyle(Color("TextSecondary")).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                metric("WINDOWS", "\(model.peripheralStatus.connectedCentrals)")
                metric("RATE", rateText)
                metric("ADVERTISING", model.peripheralStatus.isAdvertising ? "On" : "Off")
            }
            Toggle("Allow nearby Windows MotionCue to connect", isOn: advertisingBinding)
                .font(.subheadline.weight(.medium)).foregroundStyle(Color("TextSecondary")).tint(Color("Accent"))
                .accessibilityHint("Turns MotionCue Bluetooth advertising on or off.")
        }
    }

    private var helpCard: some View {
        MotionCueCard {
            HStack(spacing: 10) {
                Image(systemName: "info.circle").foregroundStyle(Color("AccentStrong")).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Need to reconnect?").font(.subheadline.weight(.semibold)).foregroundStyle(Color("Text"))
                    Text("Keep this app open, then use Scan and Connect in Windows MotionCue.")
                        .font(.subheadline).foregroundStyle(Color("TextSecondary")).fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("With the phone locked, iOS keeps the Bluetooth connection when possible. Motion updates may pause until the phone is unlocked.")
                .font(.caption).foregroundStyle(Color("TextMuted")).fixedSize(horizontal: false, vertical: true)
        }
        .background(Color("AccentSoft"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var diagnostics: some View {
        DisclosureGroup {
            VStack(spacing: 10) {
                diagnosticRow("Bluetooth", model.peripheralStatus.bluetoothLabel)
                diagnosticRow("App state", model.peripheralStatus.applicationState)
                diagnosticRow("Frames encoded", "\(model.sentFrameCount)")
                diagnosticRow("Last notification", lastNotificationText)
                diagnosticRow("Vehicle acceleration", String(format: "%+.3f, %+.3f, %+.3f m/s²", model.latestAcceleration.x, model.latestAcceleration.y, model.latestAcceleration.z))
                if let error = model.peripheralStatus.lastError {
                    Text(error).font(.caption).foregroundStyle(Color("Danger")).frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(model.statusMessage).font(.caption).foregroundStyle(Color("TextMuted")).frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.top, 12)
        } label: {
            Label("Diagnostics", systemImage: "waveform.path.ecg").font(.subheadline.weight(.semibold)).foregroundStyle(Color("TextSecondary"))
        }
        .padding(18)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color("Border"), lineWidth: 1))
    }

    private var privacyNote: some View {
        Text("Local processing · no account · no telemetry")
            .font(.caption).foregroundStyle(Color("TextMuted")).frame(maxWidth: .infinity).padding(.vertical, 2)
    }

    private var advertisingBinding: Binding<Bool> {
        Binding(get: { model.peripheralStatus.isAdvertising }, set: { model.setAdvertising($0) })
    }
    private var connectionShortLabel: String { model.peripheralStatus.connectedCentrals > 0 ? "Connected" : "Waiting" }
    private var connectionTitle: String {
        if model.peripheralStatus.connectedCentrals > 0 { return "Windows connected" }
        return model.motionAvailable ? "Waiting for Windows MotionCue" : "Motion access needed"
    }
    private var connectionHelp: String {
        if model.peripheralStatus.connectedCentrals > 0 { return "Your phone is sharing motion data with the nearby Windows app." }
        return model.motionAvailable ? "Open Windows MotionCue and select Scan to find this phone." : "Allow Motion & Fitness access, then return to MotionCue."
    }
    private var sendingTitle: String { model.peripheralStatus.connectedCentrals > 0 ? "Sending motion data automatically" : "Ready to send motion data" }
    private var sendingHelp: String { model.peripheralStatus.connectedCentrals > 0 ? "MotionCue sends only to the connected Windows app." : "Advertising is on so Windows MotionCue can connect when it is ready." }
    private var rateText: String { String(format: "%.0f Hz", model.transmitRate) }
    private var lastNotificationText: String {
        guard let date = model.peripheralStatus.lastNotificationDate else { return "None" }
        return String(format: "%.1f seconds ago", max(0, -date.timeIntervalSinceNow))
    }
    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).sectionLabel()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Color("Text"))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color("SurfaceSubtle"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Color("TextMuted"))
            Spacer(minLength: 12)
            Text(value).font(.caption.monospaced()).foregroundStyle(Color("TextSecondary")).multilineTextAlignment(.trailing)
        }
    }
}

private struct MotionCueCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(20).background(Color("Surface"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color("Shadow").opacity(0.09), radius: 18, y: 3)
    }
}

private struct MotionCuePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).foregroundStyle(.white).frame(minHeight: 44).padding(.horizontal, 16)
            .background(Color("Accent").opacity(configuration.isPressed ? 0.84 : 1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.94 : 1)
    }
}

private extension View {
    func sectionLabel() -> some View {
        font(.caption2.weight(.bold)).tracking(0.8).foregroundStyle(Color("AccentStrong"))
    }
}

#Preview { ContentView(model: AppModel()) }
