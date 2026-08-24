using MotionCue.Motion;

namespace MotionCue.Research;

public enum ResearchCondition
{
    NoCue,
    Regular,
    Dynamic
}

public enum ResearchRecordType
{
    SessionStarted,
    MotionState,
    SourceStatus,
    FmsRating,
    EventMarker,
    SessionEnded,
    EmergencyStop
}

public sealed record ResearchSessionConfig(
    string ParticipantCode,
    string SessionId,
    ResearchCondition Condition,
    TimeSpan FmsInterval,
    string ProtocolVersion = "MC-PILOT-1")
{
    public void Validate()
    {
        ValidateIdentifier(ParticipantCode, nameof(ParticipantCode));
        ValidateIdentifier(SessionId, nameof(SessionId));
        ValidateIdentifier(ProtocolVersion, nameof(ProtocolVersion));
        if (FmsInterval < TimeSpan.FromSeconds(10) || FmsInterval > TimeSpan.FromHours(1))
        {
            throw new ArgumentOutOfRangeException(nameof(FmsInterval), "FMS interval must be between 10 seconds and 1 hour.");
        }
    }

    private static void ValidateIdentifier(string value, string name)
    {
        if (string.IsNullOrWhiteSpace(value) || value.Length > 40 || value.Any(character => !char.IsAsciiLetterOrDigit(character) && character is not '-' and not '_'))
        {
            throw new ArgumentException("Use 1–40 ASCII letters, numbers, hyphens, or underscores. Do not enter a participant name.", name);
        }
    }
}

public sealed record ResearchRecord(
    DateTimeOffset RecordedAtUtc,
    double ElapsedSeconds,
    ResearchRecordType RecordType,
    string ParticipantCode,
    string SessionId,
    string ProtocolVersion,
    ResearchCondition Condition,
    string SourceName,
    MotionSourceAvailability SourceAvailability,
    MotionSourceKind SourceKind,
    double? SampleIntervalSeconds,
    double? LongitudinalRaw,
    double? LongitudinalFiltered,
    double? LateralRaw,
    double? LateralFiltered,
    double? ActivationConfidence,
    bool? AutomaticActive,
    bool? CueVisible,
    double? CueHorizontalOffset,
    double? CueVerticalOffset,
    double? CueIntensity,
    bool? SampleAccepted,
    string SampleStatus,
    int? FmsScore,
    string Note);
