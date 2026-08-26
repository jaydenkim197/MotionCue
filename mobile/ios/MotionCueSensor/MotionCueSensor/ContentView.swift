import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var showingDetails = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                connectionCard
                privacyNote
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color("Canvas").ignoresSafeArea())
        .tint(Color("Accent"))
        .animation(.easeOut(duration: 0.18), value: model.peripheralStatus.connectedCentrals)
        .animation(.easeOut(duration: 0.18), value: model.calibrationState.label)
        .sheet(isPresented: $showingDetails) { detailsSheet }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("Accent"))
                Text("M")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            .accessibilityHidden(true)

            Text("MotionCue")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("Text"))
                .lineLimit(1)

            Spacer()

            Button { showingDetails = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(width: 44, height: 44)
                    .background(Color("Surface"), in: Circle())
            }
            .accessibilityLabel("Connection settings and diagnostics")
        }
    }

    private var connectionCard: some View {
        MotionCueCard {
            HStack(spacing: 14) {
                Image(systemName: connectionIcon)
                    .font(.title2)
                    .foregroundStyle(Color("Accent"))
                    .frame(width: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(connectionTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("Text"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(connectionHint)
                        .font(.subheadline)
                        .foregroundStyle(Color("TextMuted"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Divider().overlay(Color("Border"))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Calibration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("TextMuted"))
                        .lineLimit(1)
                    Text(model.calibrationState.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("Text"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 8)
                Button("Calibrate") { model.calibrate() }
                    .buttonStyle(MotionCuePrimaryButtonStyle())
                    .disabled(!model.motionAvailable)
                    .accessibilityHint("Keep the mounted iPhone still for one second.")
            }

        }
    }

    private var detailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    DetailCard(title: "Windows connection") {
                        Toggle("Available to Windows", isOn: advertisingBinding)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("TextSecondary"))
                            .tint(Color("Accent"))
                            .lineLimit(1)
                        Text(model.peripheralStatus.isAdvertising ? "Ready for Scan." : "Discovery is off.")
                            .font(.caption)
                            .foregroundStyle(Color("TextMuted"))
                            .lineLimit(1)
                    }

                    DetailCard(title: "Background") {
                        Label("Bluetooth available while locked", systemImage: "lock.open")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextSecondary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("Motion updates may pause until unlock.")
                            .font(.caption)
                            .foregroundStyle(Color("TextMuted"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    DetailCard(title: "Diagnostics") {
                        VStack(spacing: 11) {
                            diagnosticRow("Bluetooth", model.peripheralStatus.bluetoothLabel)
                            diagnosticRow("App", model.peripheralStatus.applicationState)
                            diagnosticRow("Windows", "\(model.peripheralStatus.connectedCentrals)")
                            diagnosticRow("Advertising", model.peripheralStatus.isAdvertising ? "On" : "Off")
                            diagnosticRow("Rate", String(format: "%.1f Hz", model.transmitRate))
                            diagnosticRow("Frames", "\(model.sentFrameCount)")
                            diagnosticRow("Last send", lastNotificationText)
                            diagnosticRow(
                                "Acceleration",
                                String(
                                    format: "%+.2f, %+.2f, %+.2f",
                                    model.latestAcceleration.x,
                                    model.latestAcceleration.y,
                                    model.latestAcceleration.z))
                        }
                        if let error = model.peripheralStatus.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color("Danger"))
                                .lineLimit(2)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color("Canvas").ignoresSafeArea())
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingDetails = false }
                }
            }
        }
    }

    private var privacyNote: some View {
        Text("Local only · no account · no telemetry")
            .font(.caption)
            .foregroundStyle(Color("TextMuted"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
    }

    private var advertisingBinding: Binding<Bool> {
        Binding(
            get: { model.peripheralStatus.isAdvertising },
            set: { model.setAdvertising($0) })
    }

    private var connectionIcon: String {
        if model.peripheralStatus.connectedCentrals > 0 { return "checkmark.circle.fill" }
        if !model.motionAvailable { return "exclamationmark.triangle.fill" }
        return "iphone.radiowaves.left.and.right"
    }

    private var connectionTitle: String {
        if model.peripheralStatus.connectedCentrals > 0 { return "Windows connected" }
        if !model.motionAvailable { return "Motion access needed" }
        if !model.peripheralStatus.isAdvertising { return "Connection off" }
        return "Ready to connect"
    }

    private var connectionHint: String {
        if model.peripheralStatus.connectedCentrals > 0 {
            return String(format: "Sending motion data · %.0f Hz", model.transmitRate)
        }
        if !model.motionAvailable { return "Allow Motion & Fitness access." }
        if !model.peripheralStatus.isAdvertising { return "Turn it on in Details." }
        return "Tap Scan in Windows MotionCue."
    }

    private var lastNotificationText: String {
        guard let date = model.peripheralStatus.lastNotificationDate else { return "None" }
        return String(format: "%.1f seconds ago", max(0, -date.timeIntervalSinceNow))
    }

    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("TextMuted"))
                .lineLimit(1)
            Spacer(minLength: 12)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(Color("TextSecondary"))
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
    }
}

private struct DetailCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("Text"))
                .lineLimit(1)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MotionCueCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .padding(20)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color("Shadow").opacity(0.09), radius: 18, y: 3)
    }
}

private struct MotionCuePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(minHeight: 44)
            .padding(.horizontal, 16)
            .background(
                Color("Accent").opacity(configuration.isPressed ? 0.84 : 1),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview { ContentView(model: AppModel()) }
