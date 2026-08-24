# Mac Codex Context Package

## Goal

This package gives a Codex task running on the MacBook enough context to build the iPhone **MotionCue Sensor** transmitter without rediscovering product decisions or changing the Windows protocol.

## Preferred transfer method

Transfer the **entire Git repository**, then open its root in Codex on the Mac. This preserves history, tests, protocol code, and the decision log. Do not copy only a new Xcode project into a separate folder.

Before starting iOS work, the Mac copy should contain these paths:

```text
README.md
docs/
paper/
src/MotionCue.Core/
src/MotionCue.Windows/
tests/MotionCue.Core.Tests/
MotionCue.sln
```

Generated directories such as `artifacts/`, `bin/`, `obj/`, `.tools/`, and `paper/build/` are not needed for iOS development or for Codex context. They may be omitted from a manual transfer.

## Minimum files to upload when a complete repository transfer is impossible

Upload these files and folders together, preserving their relative paths.

### Required decision and protocol context

1. `README.md`
2. `docs/ios-transmitter-implementation-spec.md`
3. `docs/sensorframe-v1.md`
4. `docs/architecture.md`
5. `docs/motion-model.md`
6. `docs/open-decisions.md`
7. `docs/development-log.md`
8. `docs/research-paper-plan.md`

### Required Windows interoperability references

9. `src/MotionCue.Core/Sensors/` — the C# SensorFrame contract, encoder/decoder, flags, and CRC behavior
10. `src/MotionCue.Windows/Sensors/WindowsBleSensorClient.cs` — exact discovery/subscription behavior
11. `src/MotionCue.Windows/AppServices/MotionController.cs` — receiver state and watchdog integration
12. `tests/MotionCue.Core.Tests/` — known expected protocol behavior and safety tests
13. `MotionCue.sln`, `src/MotionCue.Core/MotionCue.Core.csproj`, `src/MotionCue.Windows/MotionCue.Windows.csproj`, and `tests/MotionCue.Core.Tests/MotionCue.Core.Tests.csproj`

### Helpful but not needed to start the iPhone app

14. `docs/research-mode.md`
15. `paper/` — thesis source only; no iOS build dependency

## Mac-side prerequisites the user must provide

- MacBook Air M1 with a current stable Xcode installation
- Apple Account added in Xcode → Settings → Accounts
- iPhone 16 Pro available for first physical deployment, trusted by the Mac, with Developer Mode permitted if prompted
- The exact iPhone iOS version/build from **Settings → General → About**
- The exact macOS and Xcode versions

Temporary Mac–iPhone setup connection is allowed for development/signing. The product requirement remains: at run time, iPhone-to-Windows sensor transfer is wireless BLE only.

## First Mac Codex task prompt

Use this prompt after opening the repository root on the Mac:

```text
Implement the native iOS companion described in docs/ios-transmitter-implementation-spec.md.

Read docs/sensorframe-v1.md, docs/architecture.md, docs/motion-model.md,
docs/open-decisions.md, and docs/development-log.md completely before editing.
Create mobile/ios/MotionCueSensor as a SwiftUI iOS app for the physical iPhone 16 Pro.
It must use Core Motion and CoreBluetooth Peripheral to send exactly SensorFrame v1 over
the existing BLE UUIDs at 25 Hz, with 50 Hz motion acquisition, calibration, visible
connection/permission state, no GPS/Wi-Fi/cloud/storage, and deterministic encoder tests.
Do not modify the Windows UUIDs, 42-byte protocol, or GPS-free privacy boundary.
Record each material change in docs/development-log.md. Build and test on the physical iPhone
when Xcode signing is ready; report any hardware/Apple-account blocker instead of inventing a fallback.
```

## Handoff checks

The Mac Codex task should report these before it is considered ready to hand back:

- Created iOS project paths and the current git diff
- Xcode/iPhone build or signing result
- SensorFrame byte-layout/CRC test result
- BLE advertising and Windows discovery result
- Physical axis-validation status, including any remaining calibration limitation
- Every changed decision or limitation appended to `docs/development-log.md`
