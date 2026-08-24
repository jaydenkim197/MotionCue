# MotionCue

MotionCue is an experimental Windows tray utility that draws subtle motion dots at the display edges while a passenger uses a laptop in a moving ground vehicle. A rigidly mounted Android or iPhone companion supplies calibrated vehicle-frame inertial data over Bluetooth Low Energy.

The complete product, engineering, research, and validation history is maintained in [Development Log](docs/development-log.md). New decisions and implementation changes are appended there as they occur.

Pending decisions and their recommended defaults are tracked in [Open Decisions](docs/open-decisions.md).

The coordinate-free phone protocol is specified in [SensorFrame v1](docs/sensorframe-v1.md). The English ICCV-style thesis source is under [paper](paper/README.md), with the current rendered draft at [MotionCue thesis draft](output/pdf/MotionCue_thesis_draft.pdf).

The next implementation boundary—iPhone Core Motion acquisition, vehicle-axis calibration, and BLE Peripheral transmission—is defined in [iOS transmitter implementation specification](docs/ios-transmitter-implementation-spec.md). For moving work to the Mac, use [Mac Codex context package](docs/mac-codex-context.md).

> MotionCue is not a medical device and does not claim to prevent or treat motion sickness.

## Current status

The Windows Phone IMU engineering path is implemented: SensorFrame v1 decoding, nearby-service discovery, BLE/GATT subscription, vehicle-axis cue estimation, fail-safe neutralization, transparent click-through overlay, tray modes, research instrumentation, and deterministic SensorFrame replay. The native iPhone and Android transmitter apps and real-device Study A measurements remain incomplete.

## Requirements

- Windows 11 x64 recommended; Windows 10 19041+ is a compatibility target.
- .NET 8 SDK for building.
- A nearby iPhone or Android phone running the future MotionCue companion for live motion cues.
- Bluetooth Low Energy enabled on Windows.

The current Windows build does not request location permission or use GNSS/GPS. Developer SensorFrame replay remains available without a phone or physical movement.

## Privacy

All processing is local. There is no account, backend, telemetry, analytics, location permission, coordinate path, or location-history storage.

## Build

The repository contains a project-local SDK in `.tools/dotnet8` for this workspace. To use another .NET 8 SDK, replace the executable path below.

```powershell
.\.tools\dotnet8\dotnet.exe restore MotionCue.sln
.\.tools\dotnet8\dotnet.exe build MotionCue.sln -c Release
.\.tools\dotnet8\dotnet.exe test MotionCue.sln -c Release
```

## Run

```powershell
.\.tools\dotnet8\dotnet.exe run --project src\MotionCue.Windows
```

The app starts in the tray. On first run it explains the phone BLE sensor requirement and local processing. Use the tray menu for Automatic, On, Off, Settings, and Quit. In Settings, click the version five times to reveal phone connection controls, diagnostics, and virtual SensorFrame replay.

The same hidden panel includes a pilot Research Mode with anonymous session IDs, No Cue/Regular/Dynamic conditions, timed FMS prompts, event markers, an emergency stop hotkey, and opt-in CSV logging that structurally excludes latitude and longitude. See [Research Mode](docs/research-mode.md).

## Publish a portable Windows build

```powershell
.\.tools\dotnet8\dotnet.exe publish src\MotionCue.Windows -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o artifacts\MotionCue-win-x64
```

The self-contained output does not require a separate .NET installation. Run `artifacts\MotionCue-win-x64\MotionCue.Windows.exe`.

## Limitations

- Primary display only.
- The native iPhone and Android companion transmitters are not implemented yet.
- Phone mounting and vehicle-axis calibration require physical validation.
- Actual usefulness, cue timing, and distraction require physical field tests.
- BLE timing and reconnection vary by phone and Windows Bluetooth hardware.
- Exclusive or protected full-screen surfaces may appear above the overlay.

See [architecture](docs/architecture.md), [motion model](docs/motion-model.md), and the superseded historical [GNSS Phase 0](docs/phase0.md).
