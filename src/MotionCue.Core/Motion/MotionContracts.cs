namespace MotionCue.Motion;

public enum MotionSourceKind
{
    PhoneImu,
    Simulation
}

public enum MotionSourceAvailability
{
    Stopped,
    Discovering,
    Connecting,
    Ready,
    Disconnected,
    Faulted
}

public enum MotionCueMode
{
    Automatic,
    On,
    Off
}

public enum CuePattern
{
    Regular,
    Dynamic
}

public sealed record MotionSourceStatus(
    MotionSourceAvailability Availability,
    MotionSourceKind SourceKind,
    string Message,
    DateTimeOffset Timestamp);
