namespace MotionCue.Motion;

public sealed record MotionState(
    DateTimeOffset Timestamp,
    bool SampleAccepted,
    string SampleStatus,
    double LongitudinalRaw,
    double LateralRaw,
    double LongitudinalFiltered,
    double LateralFiltered,
    double ActivationConfidence,
    bool AutomaticCuesActive,
    TimeSpan? SampleInterval)
{
    public static MotionState Empty(DateTimeOffset timestamp, string status = "Waiting for motion data") =>
        new(timestamp, false, status, 0, 0, 0, 0, 0, false, null);
}

public sealed record CueFrame(
    double HorizontalOffset,
    double VerticalOffset,
    double Intensity,
    bool Visible,
    DateTimeOffset Timestamp);
