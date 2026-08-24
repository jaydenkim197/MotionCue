using System.Globalization;
using System.Text;

namespace MotionCue.Research;

public static class ResearchCsvFormatter
{
    public const string Header =
        "recorded_at_utc,elapsed_seconds,record_type,participant_code,session_id,protocol_version,condition," +
        "source_name,source_availability,source_kind,sample_interval_s,longitudinal_raw," +
        "longitudinal_filtered,lateral_raw,lateral_filtered,activation_confidence,automatic_active,cue_visible," +
        "cue_horizontal_offset,cue_vertical_offset,cue_intensity,sample_accepted,sample_status,fms_score,note";

    public static string Format(ResearchRecord record)
    {
        var values = new string?[]
        {
            record.RecordedAtUtc.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
            Number(record.ElapsedSeconds),
            record.RecordType.ToString(),
            record.ParticipantCode,
            record.SessionId,
            record.ProtocolVersion,
            record.Condition.ToString(),
            record.SourceName,
            record.SourceAvailability.ToString(),
            record.SourceKind.ToString(),
            Number(record.SampleIntervalSeconds),
            Number(record.LongitudinalRaw),
            Number(record.LongitudinalFiltered),
            Number(record.LateralRaw),
            Number(record.LateralFiltered),
            Number(record.ActivationConfidence),
            Boolean(record.AutomaticActive),
            Boolean(record.CueVisible),
            Number(record.CueHorizontalOffset),
            Number(record.CueVerticalOffset),
            Number(record.CueIntensity),
            Boolean(record.SampleAccepted),
            record.SampleStatus,
            record.FmsScore?.ToString(CultureInfo.InvariantCulture),
            record.Note
        };

        return string.Join(',', values.Select(Escape));
    }

    private static string Number(double? value) => value?.ToString("0.######", CultureInfo.InvariantCulture) ?? string.Empty;

    private static string Boolean(bool? value) => value?.ToString(CultureInfo.InvariantCulture) ?? string.Empty;

    private static string Escape(string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return string.Empty;
        }

        if (value.IndexOfAny([',', '"', '\r', '\n']) < 0)
        {
            return value;
        }

        var builder = new StringBuilder(value.Length + 2);
        builder.Append('"');
        builder.Append(value.Replace("\"", "\"\"", StringComparison.Ordinal));
        builder.Append('"');
        return builder.ToString();
    }
}
