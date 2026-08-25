using MotionCue.Motion;

namespace MotionCue.Tests;

public sealed class CuePresentationEngineTests
{
    [Fact]
    public void OffMode_IsNeverVisible()
    {
        var frame = new CuePresentationEngine().CreateFrame(State(active: true), MotionCueMode.Off);
        Assert.False(frame.Visible);
    }

    [Fact]
    public void OnMode_IsVisibleAtNeutral()
    {
        var frame = new CuePresentationEngine().CreateFrame(State(active: false), MotionCueMode.On);
        Assert.True(frame.Visible);
    }

    [Fact]
    public void LateralCue_OpposesEstimatedMotion()
    {
        var frame = new CuePresentationEngine().CreateFrame(State(active: true, lateral: 0.6), MotionCueMode.Automatic);
        Assert.True(frame.HorizontalOffset < 0);
    }

    [Fact]
    public void StaticFrame_IsVisibleButHasNoMotionOffset()
    {
        var frame = new CuePresentationEngine().CreateStaticFrame(State(active: true, lateral: 0.6), MotionCueMode.On);

        Assert.True(frame.Visible);
        Assert.Equal(0, frame.HorizontalOffset);
        Assert.Equal(0, frame.VerticalOffset);
        Assert.Equal(0, frame.Intensity);
    }

    private static MotionState State(bool active, double lateral = 0) => new(
        DateTimeOffset.UtcNow, true, "test", 0, lateral, 0, lateral, 1, active, TimeSpan.FromMilliseconds(40));
}
