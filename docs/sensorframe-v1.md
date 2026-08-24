# MotionCue SensorFrame v1

## Purpose

`SensorFrame v1` is the coordinate-free binary message sent by the Android or iPhone companion app to the Windows laptop. It carries calibrated vehicle motion only. It contains no latitude, longitude, account identifier, device name, route name, or participant identity.

## Transport profile

- GATT service UUID: `ab31792d-ffdc-4289-88f2-40e384daacb8`
- SensorFrame notify characteristic: `8d747a89-0992-4d86-8fbe-18d2608edc1c`
- Control characteristic: `c64b31d3-4ff6-4237-bf55-5a94df0f4324`
- Byte order: little-endian
- Nominal IMU sampling: 50 Hz
- Nominal frame notification rate: 25 Hz
- Encoded frame length: 42 bytes
- Required behavior: inspect the negotiated GATT payload size before streaming; fragmentation is not part of v1 and must not be invented differently on each platform

The first implementation targets a notification payload of at least 42 bytes. If either device exposes a smaller payload, the connection must fail visibly and remain neutral until a later protocol revision defines common fragmentation.

## Vehicle coordinate system

- `+X`: vehicle forward
- `+Y`: vehicle right
- `+Z`: down

The companion app transforms platform-native sensor axes into this frame after the phone is rigidly mounted and calibrated. Positive yaw rate around `+Z` represents a right turn. `user acceleration` excludes gravity. All vector fields are in the vehicle coordinate system.

`orientation from calibration` is the normalized rotation from the pose captured at calibration to the current phone pose, serialized in `W, X, Y, Z` order. It is identity at calibration. Its main v1 purpose is mount-slip detection and engineering validation.

## Binary layout

| Offset | Bytes | Type | Field | Scale or rule |
|---:|---:|---|---|---|
| 0 | 2 | `uint16` | Magic | bytes `M`, `C` |
| 2 | 1 | `uint8` | Protocol version | `1` |
| 3 | 1 | bit field | Flags | see below |
| 4 | 4 | `uint32` | Sequence | increments per transmitted frame; wrap allowed |
| 8 | 4 | `uint32` | Elapsed milliseconds | monotonic session time; wrap allowed |
| 12 | 6 | 3 × `int16` | User acceleration X/Y/Z | value ÷ 4096 m/s² |
| 18 | 6 | 3 × `int16` | Rotation rate X/Y/Z | value ÷ 4096 rad/s |
| 24 | 6 | 3 × `int16` | Gravity X/Y/Z | value ÷ 2048 m/s² |
| 30 | 8 | 4 × `int16` | Orientation W/X/Y/Z | value ÷ 32767 |
| 38 | 1 | `uint8` | Sensor accuracy | `0` unknown, `1` unreliable, `2` low, `3` medium, `4` high |
| 39 | 1 | `uint8` | Reserved | write `0` |
| 40 | 2 | `uint16` | CRC-16/CCITT-FALSE | polynomial `0x1021`, initial value `0xFFFF`, bytes 0–39 |

## Flags

| Bit | Meaning |
|---:|---|
| 0 | Vehicle-axis calibration completed |
| 1 | User acceleration saturated during encoding |
| 2 | Rotation rate saturated during encoding |
| 3 | Gravity saturated during encoding |
| 4 | Quaternion is present and normalized |
| 5 | Platform reported unreliable sensor data |
| 6 | Sender monotonic clock or streaming session reset |
| 7 | Reserved |

## Receiver rules

1. Reject wrong length, magic, version, CRC, accuracy value, or an invalid quaternion.
2. Reject duplicate and out-of-order sequences from cue generation but count them in diagnostics.
3. Count forward sequence gaps as estimated packet loss.
4. At 250 ms without an accepted frame, move cues to neutral.
5. At 1 second without an accepted frame, mark the phone disconnected.
6. Never continue the last non-neutral cue through a stale or disconnected state.
7. Record the phone model, OS version/build, application version, protocol version and negotiated GATT payload size in Study A metadata.

## Deliberate exclusions from v1

- GPS coordinates or route data
- participant identifiers
- Wi-Fi transport framing
- BLE fragmentation
- session-key exchange and control messages
- the cue-mapping filter and gain constants

These exclusions keep the first codec deterministic and testable. Security control messages and any fragmentation revision require one shared specification before Android, iOS and Windows implementations change.
