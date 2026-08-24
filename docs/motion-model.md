# Phone IMU motion model

## Input convention

`SensorFrame v1` contains a monotonic sender timestamp, flags, user acceleration, rotation rate, gravity, orientation from calibration, and sensor accuracy. Before transmission, the mobile companion transforms platform-native axes into the canonical vehicle frame:

- `+X`: forward
- `+Y`: right
- `+Z`: down

The Windows estimator does not accept GPS, coordinates, speed, or course.

## Validation

A frame is excluded from cue updates when it contains non-finite values, lacks the calibrated or valid-quaternion flags, reports unreliable or saturated acceleration, arrives as a duplicate/out-of-order packet, or has an implausibly long sender interval. A rejected frame does not overwrite the last valid filtered signal; the link watchdog still forces neutral if accepted data do not resume.

## Longitudinal and lateral signals

Vehicle-frame user acceleration `X` drives the longitudinal signal. Positive values represent acceleration and negative values braking. Vehicle-frame user acceleration `Y` drives the lateral signal. Positive values represent rightward acceleration and negative values leftward acceleration.

Each axis applies a small dead zone, maps its configured vehicle-scale maximum to magnitude one, and clamps the result to `[-1, 1]`. The current dead zone is 0.08 m/s² and the current normalization maximum is 3.0 m/s² for both axes. These are provisional engineering defaults, not validated effect parameters.

## Filtering

The estimator uses time-aware first-order exponential smoothing:

```text
alpha = 1 - exp(-dt / tau)
filtered = previous + alpha * (raw - previous)
```

The current time constant is 0.20 seconds. The nominal frame interval is 40 ms (25 Hz). Study A must evaluate latency and noise before these constants are frozen.

## Automatic mode

A calibrated, reliable phone stream enables Automatic mode even when the current acceleration is neutral. This avoids pretending that acceleration alone can prove whether a vehicle is moving at constant speed. Disconnecting the sensor disables Automatic cues.

## Dropout

The last non-neutral cue is never held indefinitely. After 250 ms without an accepted frame, longitudinal and lateral signals are forced exactly to neutral. After one second, the source becomes disconnected and Automatic mode is disabled. A later valid frame can restore the stream.

## Cue direction

The horizontal screen offset opposes estimated lateral acceleration. The vertical screen offset follows the current longitudinal mapping used by the overlay. Both are clamped to the presentation range, and intensity is derived from the two-dimensional offset magnitude.

## Known limitations

- The current estimator uses user acceleration but does not yet fuse yaw rate into the displayed lateral signal.
- A loose or moved phone mount invalidates the assumed vehicle axes.
- Platform sensor fusion and sampling differ between iOS and Android.
- Virtual replay validates software flow, not sensor validity, BLE timing, or motion-sickness effectiveness.
