# Research Mode

Research Mode is pilot instrumentation for controlled MotionCue studies. It is not enabled in the normal consumer UI.

## Open

1. Open Settings.
2. Click `Version 0.1.0-dev` five times.
3. Scroll to `Research Session`.

Use anonymous participant codes such as `P01`; never enter a name, email address, student number, or contact detail.

## Conditions

The currently implemented Research Mode exposes the three engineering conditions below. The planned human-subject protocol has since changed to `No Cue / Static Visual Control / Synchronized Cue`; that change is not yet implemented and must not be represented as available software.

| Condition | Cue behavior |
|---|---|
| No Cue | Cues forced Off for the session |
| Regular | Cues forced On with Regular rendering |
| Dynamic | Cues forced On with Dynamic rendering |

`Regular` and `Dynamic` currently depend on MotionCue's active motion source. Developer simulation is for engineering QA only. A static dot pattern must not be treated as an efficacy intervention; it will become an explicit `Static Visual Control` after the wireless smartphone sensor bridge is implemented.

Research conditions are temporary. A normal stop restores the participant's prior settings. `Emergency stop` and `Ctrl+Shift+F12` immediately end the session and persist Off for safety. Tray and normal Settings changes are ignored while a session is active.

The 60-second FMS interval is the protocol setting and requires a live phone IMU connection. The 10-second interval exists only for engineering QA and may run with virtual SensorFrame replay.

## Output

CSV files are written to:

```text
Documents\MotionCue Research Data
```

The filename contains only UTC start time, anonymous participant code, session ID, and condition. Files are created with `CreateNew` and cannot silently overwrite an earlier session.

## Privacy boundary

The application has no location collection path. The CSV records only:

- UTC time and elapsed time
- anonymous participant/session/protocol identifiers
- research condition
- source availability and source kind
- sample interval and accepted/rejected status
- raw and filtered longitudinal/lateral estimates
- activation confidence and cue state
- FMS ratings and researcher event markers

Do not put personally identifying information or precise locations into the free-text marker field. Route identity should use an approved code such as `R01_START`, not an address.

## CSV data dictionary

| Field | Meaning |
|---|---|
| `recorded_at_utc` | ISO 8601 UTC record time |
| `elapsed_seconds` | Seconds from session start |
| `record_type` | Session, motion, status, FMS, marker, or stop event |
| `participant_code` | Anonymous research code |
| `session_id` | Anonymous session code |
| `protocol_version` | Protocol identifier, initially `MC-PILOT-1` |
| `condition` | NoCue, Regular, or Dynamic |
| `source_name` | Connected phone name or virtual SensorFrame replay |
| `source_availability` | Stopped, Discovering, Connecting, Ready, Disconnected, or Faulted |
| `source_kind` | PhoneImu or Simulation |
| `sample_interval_s` | Sender-frame interval used by the estimator |
| longitudinal/lateral fields | Normalized motion estimates in `[-1, 1]` |
| `activation_confidence` | Automatic activation confidence in `[0, 1]` |
| cue fields | Cue visibility, offset, and intensity |
| `sample_accepted` | Whether the motion sample passed validation |
| `sample_status` | Validation or estimator state |
| `fms_score` | Fast Motion Sickness Scale score, 0–20 |
| `note` | Research event label; must not contain identity/location data |

## Safety and research governance

- Obtain institutional human-research approval before participant testing.
- Use an approved consent form and allow withdrawal at any time without penalty.
- Define protocol-specific symptom and safety stop criteria before recruitment.
- A participant stop request takes priority over completing a route or collecting a rating.
- Use one operator for the vehicle and a separate researcher for ratings and safety monitoring.
- Do not represent MotionCue as a medical device or guaranteed treatment.
