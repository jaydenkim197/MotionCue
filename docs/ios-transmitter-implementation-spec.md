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
- No raw/background sensor recording or participant-study workflow. Bounded local runtime diagnostics are allowed for engineering fault analysis; they are not participant data or remote telemetry.
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

### Runtime diagnostics (0.2.0 build 3)

- Transmit Timer uses the main run loop's common modes so Details scrolling does not suppress its nominal 40 ms ticks. This does not keep a suspended process running.
- Record launch/build, scene transitions, motion availability, calibration state, BLE availability/subscriber count, sample freshness changes and observed tick gaps ≥250 ms. Every 10 seconds while executing, record a summary of tick intervals, sample age, CoreBluetooth enqueue intervals/counts, rejected enqueue attempts/backpressure and pending-frame drops.
- Both interval windows are bounded to the latest 250 intervals. They may span lifecycle/session changes; consult event boundaries before interpreting a summary. Tick gaps are observed execution gaps, not proof of OS suspension or crashes. Enqueue intervals are not Windows reception or one-way latency. Rate refers to notifications accepted by CoreBluetooth.
- Local JSONL has an allowlisted schema: event/state enums plus finite numeric metrics, wall time and monotonic uptime. No raw acceleration/quaternion, route/location, account, central/device ID, session UUID, error message or participant ID. No automatic upload; directory is excluded from device backups.
- Two rolling files of at most 128 KiB each; asynchronous utility-queue writes and at most 64 pending log records. Under storage/queue failure diagnostics may be incomplete; sensor transmission must not wait for diagnostic disk I/O. The suspension/crash interval itself cannot write log entries; an observed gap is recorded after execution resumes.
- Details → Local logs → Prepare logs → Share logs exports a snapshot of both files. Preparing/exporting while foreground records a summary and waits for previously queued log writes. Export remains user-controlled.
- A connected Mac can copy only `Library/Application Support/Diagnostics/runtime.jsonl` and `runtime-previous.jsonl` using CoreDevice's `appDataContainer` for `com.motioncue.sensor`; no debugger or whole-phone sysdiagnose is required. Raw artifacts stay outside Git.

Mac collection: `bash tools/collect-ios-runtime-logs.sh <paired-device-id>` (find the ID with `xcrun devicectl list devices`). It copies only the two named app diagnostic files into a unique ignored artifacts folder, without modifying the phone. A missing previous file is normal before the first rotation. Current-log failure stops collection; this helper requires build 3 logs to exist and device file access to be available.

iOS 26+ CoreBluetooth documents Live Activity-related foreground privileges, but this is not a documented guarantee of continuous Core Motion/application execution on a locked, screen-off phone. Apple staff also describe screen-off limitations for background scanning. A Live Activity alone is not used as a fix; no silent audio, location permission or repeated background-task workaround is added. [CoreBluetooth overview](https://developer.apple.com/documentation/corebluetooth), [Apple engineering clarification](https://developer.apple.com/forums/thread/815189).

### Finite locked-session candidate (0.2.0 build 4; physical validation pending)

- Build 3 bench: BLE subscription survives lock, but fresh-frame delivery stops; returning to the app resumes transmission without reconnecting. This is not a Bluetooth disconnect fix.
- Details → Locked session → Start explicitly requests an iOS 26+ `BGContinuedProcessingTask`, after connection and calibration. It targets **45,000 fresh frames actually queued by CoreBluetooth** (~30 minutes at 25 Hz), with a **35-minute ContinuousClock limit including device sleep**. It does not claim Windows acknowledgement or record raw sensor data.
- `processing` and `bluetooth-peripheral` modes; permitted task prefix with one exact handler per job. Default CPU resources only, no GPU entitlement. iOS 27 async submission is off-main; iOS 26 uses the older submission API. `.fail` avoids deferred execution when immediate runtime is unavailable.
- Progress is reported at most once per second while running. Completion requires the real frame goal; clock ticks alone cannot advance progress. The system supplies progress/cancel UI. It is not a standalone ActivityKit keep-alive.
- Stop, OS expiration/cancellation, subscriber/Bluetooth/calibration loss, five seconds without queued progress, launch timeout or hard deadline ends the task. Late callbacks cannot revive an old job. Clear pending frames; after an end in background, transmission stays blocked until foreground. Existing Windows neutral/timeout behavior remains unchanged.
- No automatic restart, renewal, chained tasks or start merely from a preference. Another foreground Start tap is required. Force-quitting/powering off stops transmission; no API makes powered-off hardware send data. Older iOS remains foreground-only.
- Local logs add allowlisted session-state transitions, frame goal/count, elapsed seconds and numeric scheduler errors; no job identifiers or error text. **Simulator state-machine tests do not validate iOS background execution**.
- This is a finite engineering candidate, not a guarantee of indefinite locked operation. Test without debugger/USB for 60 seconds, five minutes and one full session, measuring Windows reception separately. See [build 4 trial guide](bench-ios-build4-lock-session.md).

Apple documents user-started jobs with real progress, sensor analysis/background CPU use and system-controlled termination, but does not specifically guarantee this device's locked CoreMotion→BLE pipeline. [Long-running tasks](https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados), [BGContinuedProcessingTask](https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask).

### Sample-driven send opportunities (build 5 candidate)

Build 4 kept sending in background but measured only8.45 Hz over a7.2-minute snapshot window. A subsequent >1-second gap means continued runtime is not sufficient for the intended rate/continuity. Build 5 derives send opportunities from real Core Motion acquisition timestamps rather than the throttled main run-loop Timer. It tolerates2 ms sample jitter, enforces38 ms minimum spacing between accepted acquisition timestamps, skips late scheduling slots and rejects stale/duplicate/future/unreliable samples. This is not a separate minimum wall-time enqueue guard: delayed MainActor callbacks or BLE backpressure may still batch actual sends. The1 Hz common-mode timer is now only a health/logging watchdog. `tick*` metrics in build5 describe sample-driven send attempts; build3/4 described Timer intervals. Freshness/packet/axis safety rules are unchanged. Motion delivery uses a userInitiated OperationQueue; diagnostic acceleration UI is updated at10 Hz only in foreground. No background UI redraw is needed for that value. Forty-two simulator tests pass. One USB-disconnected locked trial sustained24.929 Hz over310.88 s, and continued background observation reached24.925 Hz over481.28 s. A300 ms transition gap remains; full-session completion/cancellation, repeatability and G1 are unvalidated. Fixed numeric calibration-failure categories aid diagnosis without logging error text. See [build5 evidence](bench-2026-10-04-ios-build5.md).

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
