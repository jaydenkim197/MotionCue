# MotionCue architecture

## Current decision

MotionCue is a C# 12, .NET 8, WPF Windows application. Its only live motion source is a rigidly mounted Android or iPhone companion transmitting calibrated inertial data over Bluetooth Low Energy. GNSS, Windows location services, coordinates, and GPS-derived motion estimation are not part of the current product.

WPF provides the transparent, click-through, focus-free edge overlay and tray-first settings surface. The renderer remains isolated so a lower-level renderer can replace it if Study A profiling shows a need.

## Modules

```text
src/
  MotionCue.Core/           SensorFrame protocol, Phone IMU estimator, cue state
  MotionCue.Windows/        BLE client, controller, overlay, tray, settings, research UI
tests/
  MotionCue.Core.Tests/     deterministic protocol, estimator, watchdog, and CSV tests
docs/
paper/
```

The active data path is:

```text
iPhone or Android sensors
    -> platform calibration into vehicle axes
    -> SensorFrame v1 BLE notification
    -> WindowsBleSensorClient
    -> PhoneImuEstimator
    -> MotionState
    -> CuePresentationEngine
    -> WPF edge overlay
```

Developer replay creates the same `SensorFrame` objects and enters at the estimator boundary. It therefore tests cue mapping without claiming to test radio performance or real vehicle sensing.

## BLE and failure handling

The phone is the BLE peripheral/GATT server and Windows is the central/GATT client. The Windows client actively scans advertisements containing the MotionCue service UUID and also lists already paired BLE devices. It can connect to an advertised Bluetooth address without requiring OS-level pairing, then locates the SensorFrame characteristic, verifies notification capacity, decodes CRC-protected frames, and rejects duplicates or out-of-order frames.

Accepted frames nominally arrive at 25 Hz. A controller watchdog forces the cue estimate to neutral after 250 ms without a frame and marks the stream disconnected after one second. Recovery resumes only after a newly accepted frame.

## Motion state and rendering

`PhoneImuEstimator` consumes vehicle-frame user acceleration. It applies per-axis dead zones, time-aware exponential smoothing, normalization, and saturation. Current constants are provisional engineering defaults and must be tuned from replay and Study A measurements before participant testing.

`CuePresentationEngine` depends only on normalized longitudinal and lateral state. It does not know whether input came from a physical phone or deterministic replay.

The current implementation intentionally exposes only Phone IMU and replay inputs. A future maritime branch may add a `UsbImuSource` that converts a rigidly mounted accelerometer/gyroscope dongle into the same canonical SensorFrame boundary. Maritime filtering and six-degree-of-freedom body-axis calibration must remain source-specific; the current vehicle tuning constants must not be reused without validation.

## State and threading

BLE notifications arrive off the WPF UI thread. `MotionController` serializes estimator access, stores immutable states, and posts state, status, and cue-frame notifications to the UI synchronization context. Cancellation tokens stop virtual replay. BLE lifecycle operations are serialized by a semaphore.

## Privacy boundary

The runtime requests no location permission and contains no coordinate or route-data path. Sensor processing is local. There is no account, backend, telemetry, analytics, or cloud relay. Research CSV output contains anonymous identifiers, source status, derived motion/cue values, FMS ratings, and event codes only.

## Packaging direction

The repository can publish an unpackaged self-contained x64 build requiring no separate .NET installation. Release work should add code signing and MSIX packaging after real iPhone and Android BLE behavior has been measured.

## Major risks

1. iOS and Android BLE peripheral behavior, background limits, and reconnection must be verified on the selected devices.
2. Phone mounting and calibration errors can reverse or mix vehicle axes.
3. BLE latency and packet loss may delay cues; Study A must establish acceptance thresholds.
4. Provisional dead zones and gains may be too weak, distracting, or mistimed.
5. Exclusive or protected full-screen surfaces may appear above the overlay.
6. Effectiveness and distraction require field testing; the software must not claim medical treatment.
