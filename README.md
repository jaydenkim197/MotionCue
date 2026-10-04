# MotionCue

MotionCue is an experimental Windows tray utility that draws subtle motion dots at the display edges while a passenger uses a laptop in a moving ground vehicle. A rigidly mounted Android or iPhone companion supplies calibrated vehicle-frame inertial data over Bluetooth Low Energy.

The complete product, engineering, research, and validation history is maintained in [Development Log](docs/development-log.md). New decisions and implementation changes are appended there as they occur.

Pending decisions and their recommended defaults are tracked in [Open Decisions](docs/open-decisions.md).

The proposed AI/CV extension and its one- or two-semester scope are documented in [Adaptive MotionCue development roadmap](docs/adaptive-motioncue-development-roadmap.md). It is a proposal and does not replace the current study protocol until explicitly approved.

The reusable [Development documentation skillbook](docs/reusable-development-documentation-skillbook.md) captures the decision logging, verification, documentation, and completion-sync practices used in this project for reuse elsewhere.

The coordinate-free phone protocol is specified in [SensorFrame v1](docs/sensorframe-v1.md). The English ICCV-style thesis source is under [paper](paper/README.md), with the current rendered draft at [MotionCue thesis draft](output/pdf/MotionCue_thesis_draft.pdf).

The implemented iPhone transmitter contract is defined in [iOS transmitter implementation specification](docs/ios-transmitter-implementation-spec.md). Use [pre-field-test readiness](docs/pre-field-test-readiness.md) for the current release gates and Windows handoff. The [Mac Codex context package](docs/mac-codex-context.md) preserves the original setup context.

> MotionCue is not a medical device and does not claim to prevent or treat motion sickness.

## Current status

The Windows Phone IMU engineering path is implemented: SensorFrame v1 decoding, nearby-service discovery, BLE/GATT subscription, vehicle-axis cue estimation, fail-safe neutralization, transparent click-through overlay, tray modes, research instrumentation, and deterministic SensorFrame replay. The native iPhone transmitter is also implemented and its live BLE discovery, connection, subscription, and approximately 25 Hz SensorFrame transfer to Windows have been verified. Android transmission and quantitative in-vehicle Study A measurements remain incomplete.

## Requirements

- Windows 11 x64 recommended; Windows 10 19041+ is a compatibility target.
- .NET 8 SDK for building.
- A nearby iPhone running the MotionCue Sensor companion, or a future compatible Android companion, for live motion cues.
- Bluetooth Low Energy enabled on Windows.

The current Windows build does not request location permission or use GNSS/GPS. Developer SensorFrame replay remains available without a phone or physical movement.

## Privacy

All processing is local. There is no account, backend, telemetry, analytics, location permission, coordinate path, or location-history storage.

## Build

The Windows workspace may contain an ignored project-local SDK in `.tools/dotnet8`; Git does not transfer it. Install/use a .NET 8 SDK if it is absent. The release helper selects the local SDK or `dotnet` on PATH:

```powershell
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\tools\build-windows-release.ps1
```

For individual build steps:

```powershell
.\.tools\dotnet8\dotnet.exe restore MotionCue.sln
.\.tools\dotnet8\dotnet.exe build MotionCue.sln -c Release
.\.tools\dotnet8\dotnet.exe test MotionCue.sln -c Release
```

## Run

```powershell
.\.tools\dotnet8\dotnet.exe run --project src\MotionCue.Windows
```

The app starts in the tray. On first run it explains the phone BLE sensor requirement and local processing. Use the tray menu for Automatic, On, Off, Settings, and Quit. Phone connection controls are on the main Settings surface. Click the version five times to reveal diagnostics and virtual SensorFrame replay.

Settings includes a pilot Research Mode with anonymous session IDs, No Cue/Static Visual Control/Synchronized Cue conditions, timed FMS prompts, event markers, an emergency stop hotkey, and opt-in CSV logging that structurally excludes latitude and longitude. See [Research Mode](docs/research-mode.md).

## Publish a portable Windows build

```powershell
.\.tools\dotnet8\dotnet.exe publish src\MotionCue.Windows -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o artifacts\MotionCue-win-x64
```

The self-contained output does not require a separate .NET installation. Run `artifacts\MotionCue-win-x64\MotionCue.Windows.exe`.

## Limitations

- Primary display only.
- The Android companion transmitter is not implemented yet.
- The iPhone transmitter includes an experimental, user-started finite locked session (iOS 26+, 45,000 queued frames/about 30 minutes, 35-minute cap). Build 4 continued transmitting in background but slowed; build 5 replaces the send timer with sample-driven cadence. Locked 25 Hz operation and vehicle timing still require physical validation. See the [lock-session trial guide](docs/bench-ios-build4-lock-session.md).
- Phone mounting and vehicle-axis calibration require physical validation.
- Actual usefulness, cue timing, and distraction require physical field tests.
- BLE timing and reconnection vary by phone and Windows Bluetooth hardware.
- Exclusive or protected full-screen surfaces may appear above the overlay.

See [architecture](docs/architecture.md), [motion model](docs/motion-model.md), and the superseded historical [GNSS Phase 0](docs/phase0.md).
