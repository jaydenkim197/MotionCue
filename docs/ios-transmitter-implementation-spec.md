# MotionCue iOS Sensor Transmitter — Implementation Specification

## 1. Purpose and scope

This document is the implementation contract for the first native iPhone companion application, provisionally named **MotionCue Sensor**. It turns a rigidly mounted iPhone 16 Pro into a local motion sensor that sends calibrated inertial frames to the existing Windows MotionCue receiver.

The v1 app is deliberately narrow:

- Platform: iOS, SwiftUI, physical iPhone only
- Sensor source: Core Motion device motion; no GPS, location, route, speed, account, or cloud service
- Transport: Bluetooth Low Energy Peripheral / GATT server
- Receiver: existing Windows MotionCue BLE Central client
- Sampling: obtain device motion at 50 Hz; transmit the latest valid frame at 25 Hz
- Privacy: process in memory; do not persist raw sensor data by default

Android support remains a separate Study A compatibility task. macOS is a development host, not a MotionCue receiver target in this thesis.

## 2. Non-goals for v1

- No GPS/GNSS, Wi-Fi transport, cloud relay, analytics, account, or telemetry
- No medical, anti-nausea, treatment, or effectiveness claim in the app UI
- No background logging or participant-study workflow
- No app-layer pairing code, encryption protocol, fragmentation, or multi-receiver support
- No attempt to silently infer a vehicle axis when the phone is loose or mounted in an unsupported orientation

## 3. Interoperability contract

The app must implement [SensorFrame v1](sensorframe-v1.md) exactly. Do not change these values locally.

| Item | Required value |
|---|---|
| BLE service UUID | `ab31792d-ffdc-4289-88f2-40e384daacb8` |
| SensorFrame notify UUID | `8d747a89-0992-4d86-8fbe-18d2608edc1c` |
| Control UUID | `c64b31d3-4ff6-4237-bf55-5a94df0f4324` |
| Frame version | `1` |
| Frame length | exactly 42 bytes |
| Byte order | little-endian |
| Integrity | CRC-16/CCITT-FALSE over bytes 0–39 |
| Required notification rate | 25 Hz nominal |
| Frame sequence | monotonically incrementing `UInt32`, wrap allowed |
| Frame time | monotonically increasing elapsed session milliseconds, wrap allowed |

The Control characteristic is present for protocol compatibility but has no v1 command. It must not be used to invent an incompatible protocol. The Windows receiver currently expects SensorFrame notifications only.

## 4. Mounting and calibration contract

The v1 physical setup is intentionally constrained so that measurements are interpretable.

1. Fix the iPhone rigidly to the vehicle, not to a person or a loose seat surface.
2. Use one documented standard mount orientation for all tests: screen facing upward and the top edge pointing toward the front of the vehicle.
3. Before driving, stop the vehicle and press **Calibrate**. The app captures a zero-relative orientation and begins a fresh stream.
4. If the observed gravity vector or the relative orientation indicates material mount movement, the app must visibly mark calibration invalid and stop emitting frames marked calibrated.
5. If the mount is moved, the researcher must stop, re-secure it, and calibrate again.

The sender is responsible for transforming platform-native vectors into the canonical vehicle frame before encoding:

- `+X`: vehicle forward
- `+Y`: vehicle right
- `+Z`: vehicle down

Positive yaw around `+Z` means a right turn. `userAcceleration` excludes gravity. The initial implementation must record a brief stationary calibration window and show current gravity/orientation diagnostics during development; final axis signs must be checked with a controlled forward acceleration, braking, left turn, and right turn before any participant study.

## 5. App UI and state machine

Use one compact connection/calibration card. A visible gear opens Details for discovery, screen-awake, calibration help, permission recovery and diagnostics. Short labels stay on one line; detailed prose uses full-width rows.

| State | Visible text | Allowed actions | BLE behavior |
|---|---|---|---|
| Motion permission needed | Explain local motion use | Grant permission | Do not advertise/stream |
| Ready to calibrate | Phone mount checklist | Calibrate | Advertise permitted; no valid frames |
| Calibrated, waiting | `Waiting for Windows MotionCue` | Start/stop advertising, recalibrate | Advertise service |
| Connected and streaming | Rate, frame count, last-send age | Stop, recalibrate | Notify latest valid frame at 25 Hz |
| Disconnected | `Windows disconnected` | Continue advertising, stop | No notification; retain calibration |
| Calibration invalid / sensor unreliable | Clear warning | Recalibrate | Do not mark outgoing data as calibrated |
| Bluetooth unavailable | Clear system-setting guidance | Retry | No advertising |

Main displays truthful short connection/stream/calibration state and Calibrate. Details contains Bluetooth state, central count, enqueue rate/count (not Windows acknowledgments), last notification age, errors and sensor diagnostics. No location display/storage.

## 6. Core Motion implementation requirements

- Use `CMMotionManager` device-motion updates on a dedicated serial queue.
- Check device-motion availability before enabling calibration or streaming.
- Request the system motion permission with a truthful `NSMotionUsageDescription`, for example: `MotionCue uses motion data locally to synchronize visual cues on your Windows laptop.`
- Keep Core Motion acquisition at 50 Hz when active. Never use a UI timer as the sensor timestamp.
- Use a monotonic local clock for the `elapsed milliseconds` field; reset it and set the session-reset flag when a new streaming session starts.
- Validate finite values, normalize the outgoing quaternion, clamp fixed-point values safely, and set saturation flags when clamping occurs.
- Map unavailable, stale, or unreliable readings to the protocol's reliability flag/accuracy rather than sending apparently valid motion.
- Retain only the latest accepted sensor sample for the 25 Hz BLE scheduler. Do not queue an unbounded backlog.

## 7. CoreBluetooth implementation requirements

- Use `CBPeripheralManager` on a dedicated serial queue; do not use Central APIs.
- Publish the MotionCue service with the SensorFrame characteristic configured for `.notify` and the Control characteristic configured as declared by the shared protocol.
- Start advertising only after `CBManagerState.poweredOn` and after services have been added.
- Respect `peripheralManagerIsReady(toUpdateSubscribers:)`. If `updateValue` returns `false`, discard stale frames and send the most recent current frame when ready; do not buffer a long queue.
- When there are no subscribed centrals, keep advertising but do not treat this as a sensor or calibration failure.
- Calibration or zero/nonzero subscriber transition starts a new stream with sequence/time reset. Do not reset an ongoing stream when an extra subscriber joins/leaves. Multi-receiver behavior is not a v1 support claim.
- Never reuse a timestamp or cached sample older than 100 ms. Clear accepted frames; expire flow-controlled frames before retry.
- Treat app backgrounding, Bluetooth state loss, and subscriber loss as observable lifecycle events. Background behavior is an engineering test item, not an assumed v1 guarantee.

The app needs an `NSBluetoothAlwaysUsageDescription` string that accurately explains that Bluetooth sends local sensor data to the nearby Windows MotionCue app. The v1 app declares the `bluetooth-peripheral` background mode so an already subscribed Windows central can remain connected while the phone is locked. This does not guarantee the 25 Hz application timer or Core Motion delivery while locked; iOS decides when background execution is available.

Acceptance test: connect Windows first, confirm one subscribed central, lock the iPhone for at least 30 seconds, then unlock it. Record whether Windows remained subscribed and whether frames resume without reconnecting. Treat a disconnect as a test result to investigate, not as proof that the background entitlement was ignored.

## 8. Suggested project structure

```text
mobile/ios/MotionCueSensor/
  MotionCueSensor.xcodeproj/
  MotionCueSensor/
    MotionCueSensorApp.swift
    ContentView.swift
    AppModel.swift
    Motion/
      DeviceMotionProvider.swift
      VehicleAxisCalibrator.swift
      SensorSample.swift
    Bluetooth/
      PeripheralService.swift
      SensorFrameEncoder.swift
      Crc16.swift
    Shared/
      MotionCueProtocol.swift
      AppState.swift
    Resources/
      Info.plist
```

Names may vary, but motion acquisition, calibration, binary encoding, BLE lifecycle, and SwiftUI state must remain separately testable.

## 9. Acceptance checklist

### Build and device setup

- [ ] Build succeeds in Xcode on the MacBook Air M1.
- [ ] App runs on the physical iPhone 16 Pro under an Apple Account/Team with automatic signing.
- [ ] `NSMotionUsageDescription` and Bluetooth purpose descriptions are present and permission prompts are comprehensible.

### Protocol and behavior

- [ ] Unit tests encode a known SensorFrame v1 byte vector and CRC exactly as Windows tests expect.
- [ ] App advertises the exact MotionCue service UUID.
- [ ] Windows MotionCue discovers, connects to, and subscribes to the iPhone.
- [ ] Connected iPhone sends 42-byte notifications at approximately 25 Hz.
- [ ] Windows reports real Phone IMU data rather than virtual replay.
- [ ] Forward acceleration, braking, left turn, and right turn produce the expected Windows cue directions after axis validation.
- [ ] Stopping the app/Bluetooth forces Windows cues neutral within 250 ms and disconnects within one second.
- [ ] Reconnection resumes only on a new valid frame; no stale non-neutral cue is held.

### Evidence to retain for Study A

- [ ] iPhone model, iOS version/build, Xcode version, app git commit/version, protocol version
- [ ] Mount orientation, calibration procedure, car/route metadata without coordinates
- [ ] Frame rate, estimated loss, end-to-end latency/jitter method and results
- [ ] Axis-sign validation video or event-marked log

## 10. Implementation order

1. Create the SwiftUI project, signing, purpose descriptions, and static UI states.
2. Add Core Motion permission and a live on-screen diagnostic without BLE.
3. Implement standard mounting validation and calibration state.
4. Implement SensorFrame v1 encoding with deterministic unit tests.
5. Implement BLE service/advertising/subscription and send a deterministic test frame.
6. Connect the real iPhone to Windows MotionCue and validate live frames.
7. Add 50 Hz acquisition / 25 Hz latest-frame transmission, failure states, and diagnostics.
8. Perform stationary and controlled-car axis tests before any participant-facing work.

## 11. Source-of-truth precedence

If this specification conflicts with [SensorFrame v1](sensorframe-v1.md), `SensorFrame v1` governs the wire format. If it conflicts with the active Windows behavior, record the conflict in [Development Log](development-log.md) before changing either side. Do not reintroduce GNSS or Wi-Fi merely to simplify the mobile app.
