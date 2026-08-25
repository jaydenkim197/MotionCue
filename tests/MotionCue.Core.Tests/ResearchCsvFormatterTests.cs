using MotionCue.Motion;
using MotionCue.Research;

namespace MotionCue.Tests;

public sealed class ResearchCsvFormatterTests
{
    [Fact]
    public void Schema_CannotContainPreciseCoordinates()
    {
        Assert.DoesNotContain("latitude", ResearchCsvFormatter.Header, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("longitude", ResearchCsvFormatter.Header, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Format_UsesInvariantNumbersAndEscapesFreeText()
    {
        var record = CreateRecord() with
        {
            LongitudinalFiltered = 0.3456789,
            Note = "turn, right\nconfirmed"
        };

        var csv = ResearchCsvFormatter.Format(record);

        Assert.Contains("0.345679", csv, StringComparison.Ordinal);
        Assert.Contains("\"turn, right\nconfirmed\"", csv, StringComparison.Ordinal);
    }

    [Theory]
    [InlineData("P01", "S01")]
    [InlineData("pilot-01", "route_A")]
    public void SessionConfig_AcceptsAnonymousIdentifiers(string participant, string session)
    {
        var config = new ResearchSessionConfig(participant, session, ResearchCondition.SynchronizedCue, TimeSpan.FromMinutes(1));
        config.Validate();
    }

    [Theory]
    [InlineData("Jane Doe")]
    [InlineData("홍길동")]
    [InlineData("")]
    public void SessionConfig_RejectsNamesAndUnsafeIdentifiers(string participant)
    {
        var config = new ResearchSessionConfig(participant, "S01", ResearchCondition.SynchronizedCue, TimeSpan.FromMinutes(1));
        Assert.Throws<ArgumentException>(config.Validate);
    }

    private static ResearchRecord CreateRecord() => new(
        DateTimeOffset.Parse("2026-08-19T00:00:00Z"),
        1.25,
        ResearchRecordType.MotionState,
        "P01",
        "S01",
        "MC-PILOT-2",
        ResearchCondition.SynchronizedCue,
        "Developer simulation",
        MotionSourceAvailability.Ready,
        MotionSourceKind.Simulation,
        0.04,
        0.2,
        0.1,
        -0.3,
        -0.2,
        1,
        true,
        true,
        0.2,
        -0.1,
        0.4,
        true,
        "Valid motion sample",
        null,
        string.Empty);
}
