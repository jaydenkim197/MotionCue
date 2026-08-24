using MotionCue.Sensors;

namespace MotionCue.Tests;

public sealed class SensorStreamMonitorTests
{
    [Fact]
    public void SequenceTracker_ReportsGapDuplicateAndOutOfOrderFrames()
    {
        var tracker = new SensorSequenceTracker();

        Assert.Equal(SensorFrameDisposition.Accepted, tracker.Observe(10).Disposition);
        var gap = tracker.Observe(13);
        var duplicate = tracker.Observe(13);
        var old = tracker.Observe(12);

        Assert.Equal(SensorFrameDisposition.AcceptedWithGap, gap.Disposition);
        Assert.Equal(2u, gap.MissingBeforeFrame);
        Assert.Equal(2ul, gap.AcceptedFrames);
        Assert.Equal(2ul, gap.MissingFrames);
        Assert.Equal(0.5, gap.EstimatedPacketLossRate, 6);
        Assert.Equal(SensorFrameDisposition.Duplicate, duplicate.Disposition);
        Assert.Equal(SensorFrameDisposition.OutOfOrder, old.Disposition);
    }

    [Fact]
    public void SequenceTracker_AcceptsUInt32Wraparound()
    {
        var tracker = new SensorSequenceTracker();

        tracker.Observe(uint.MaxValue);
        var wrapped = tracker.Observe(0);

        Assert.Equal(SensorFrameDisposition.Accepted, wrapped.Disposition);
        Assert.Equal(0ul, wrapped.MissingFrames);
    }

    [Fact]
    public void Watchdog_NeutralizesAt250MsAndDisconnectsAtOneSecond()
    {
        var start = new DateTimeOffset(2026, 8, 19, 0, 0, 0, TimeSpan.Zero);
        var watchdog = new SensorLinkWatchdog();

        Assert.Equal(SensorLinkState.Waiting, watchdog.Evaluate(start));
        watchdog.Observe(start);
        Assert.Equal(SensorLinkState.Streaming, watchdog.Evaluate(start.AddMilliseconds(249)));
        Assert.Equal(SensorLinkState.Neutralizing, watchdog.Evaluate(start.AddMilliseconds(250)));
        Assert.Equal(SensorLinkState.Neutralizing, watchdog.Evaluate(start.AddMilliseconds(999)));
        Assert.Equal(SensorLinkState.Disconnected, watchdog.Evaluate(start.AddSeconds(1)));
    }
}
