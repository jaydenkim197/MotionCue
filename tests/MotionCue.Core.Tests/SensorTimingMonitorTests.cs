using MotionCue.Sensors;

namespace MotionCue.Core.Tests;

public sealed class SensorTimingMonitorTests
{
    [Fact]
    public void EmptySnapshotHasNoMeasurements()
    {
        var s = new SensorTimingMonitor().Snapshot();
        Assert.Equal(0, s.WindowIntervals);
        Assert.Equal(0, s.SequenceGapRate);
    }

    [Fact]
    public void MeasuresReceptionSpacingAndSequenceGaps()
    {
        var m = new SensorTimingMonitor();
        m.Observe(0, 0, true);
        m.Observe(0.04, 0, false);
        m.Observe(0.12, 1, false);
        m.Reject();
        var s = m.Snapshot();
        Assert.Equal(3UL, s.AcceptedFrames);
        Assert.Equal(1UL, s.MissingFrames);
        Assert.Equal(1UL, s.RejectedFrames);
        Assert.Equal(0.25, s.SequenceGapRate);
        Assert.Equal(40, s.MedianIntervalMilliseconds, 6);
        Assert.Equal(80, s.P95IntervalMilliseconds, 6);
        Assert.Equal(80, s.MaximumIntervalMilliseconds, 6);
        Assert.Equal(20, s.IntervalStandardDeviationMilliseconds, 6);
    }

    [Fact]
    public void ClockResetStartsNewSpacingSegmentWithoutLosingCounters()
    {
        var m = new SensorTimingMonitor();
        m.Observe(0, 0, true);
        m.Observe(10, 0, true);
        m.Observe(10.04, 0, false);
        Assert.Equal(1, m.Snapshot().WindowIntervals);
        Assert.Equal(40, m.Snapshot().MaximumIntervalMilliseconds, 6);
        Assert.Equal(3UL, m.Snapshot().AcceptedFrames);
    }

    [Fact]
    public void WindowIsBounded()
    {
        var m = new SensorTimingMonitor();
        for (var i = 0; i < 2000; i++) { m.Observe(i * 0.04, 0, false); }
        Assert.Equal(1500, m.Snapshot().WindowIntervals);
        Assert.Equal(2000UL, m.Snapshot().AcceptedFrames);
    }

    [Fact]
    public void ResetClearsAllMeasurements()
    {
        var m = new SensorTimingMonitor();
        m.Observe(0, 1, false);
        m.Reject();
        m.Reset();
        Assert.Equal(default(SensorTimingSnapshot), m.Snapshot());
    }

    [Fact]
    public void NonfiniteClockIsRejected()
    {
        var m = new SensorTimingMonitor();
        Assert.Throws<ArgumentOutOfRangeException>(() => m.Observe(double.NaN, 0, false));
    }
}
