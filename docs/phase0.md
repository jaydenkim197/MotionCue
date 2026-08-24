# Phase 0 technical validation — historical GNSS investigation (superseded)

> This document preserves the discarded GNSS-only investigation. The current application contains no GNSS code and does not use Windows location services.

Date: 2026-08-19

## Result

Satellite-source detection is technically viable through `Windows.Devices.Geolocation`. Each `Geocoordinate` exposes `PositionSource`; MotionCue accepts only `Satellite` and rejects Cellular, Wi-Fi, IP address, Default, Obfuscated, and Unknown.

The current development laptop has Windows location service running and location access allowed, but Plug and Play enumeration shows no GPS/GNSS sensor. The live probe returned a `WiFi` position with 100 m horizontal accuracy, altitude available, and both speed and heading absent. MotionCue correctly rejected that fix and reported `GPS unavailable`; it did not silently fall back to network-derived location.

## Obtainable fields

| Field | Availability |
|---|---|
| Latitude / longitude | present on a position result |
| Horizontal accuracy | present |
| Timestamp | present |
| PositionSource | present and required to equal Satellite |
| Speed | nullable |
| Heading | nullable |
| Altitude / altitude accuracy | nullable and not used by MVP estimation |
| Satellite data | only meaningful for satellite-derived samples; device dependent |

## Probe

Run:

```powershell
.\.tools\dotnet8\dotnet.exe run --project tools\MotionCue.GnssProbe
```

The probe requests location access, waits a bounded period for one fix, prints capability/status and non-sensitive derived field availability, and exits non-zero when no Satellite fix exists. Precise coordinates are omitted by default.

Observed on the development laptop:

```text
Location access: Allowed
Position source: WiFi
Satellite source: False
Horizontal accuracy available: True (100.0 m)
Reported speed available: False
Reported heading available: False
Altitude available: True
GPS unavailable: the returned fix is not Satellite. Motion cues remain disabled.
```

## Exact next step

Run the probe and MotionCue application on at least three physical Windows devices that claim GNSS support. Capture source kind, accuracy, update interval, speed/heading availability, and signal loss behavior without retaining coordinates. If no suitable tester device is available, continue overlay and estimator work in simulation while treating GNSS field validation as a release blocker.
