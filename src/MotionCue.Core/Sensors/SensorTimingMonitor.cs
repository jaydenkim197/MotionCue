namespace MotionCue.Sensors;

public readonly record struct SensorTimingSnapshot(
    ulong AcceptedFrames,
    ulong MissingFrames,
    ulong RejectedFrames,
    int WindowIntervals,
    double MedianIntervalMilliseconds,
    double P95IntervalMilliseconds,
    double MaximumIntervalMilliseconds,
    double IntervalStandardDeviationMilliseconds)
{
    // Sequence gaps also include sender-side drops; this is not radio-only loss.
    public double SequenceGapRate => AcceptedFrames + MissingFrames == 0
        ? 0 : (double)MissingFrames / (AcceptedFrames + MissingFrames);
}

/// Bounded, coordinate-free diagnostics. Call under the owner's stream lock.
/// Reception spacing is not one-way latency (phone/PC clocks are not synchronized).
public sealed class SensorTimingMonitor
{
    private const int WindowCapacity = 1500;
    private readonly Queue<double> _intervals = new();
    private double? _previousReception;
    private ulong _accepted;
    private ulong _missing;
    private ulong _rejected;
    private double _maximumInterval;

    public void Observe(double monotonicSeconds, uint missingBeforeFrame, bool clockReset)
    {
        if (!double.IsFinite(monotonicSeconds))
        {
            throw new ArgumentOutOfRangeException(nameof(monotonicSeconds));
        }
        _accepted++;
        _missing += missingBeforeFrame;
        if (!clockReset && _previousReception is { } previous && monotonicSeconds >= previous)
        {
            var milliseconds = (monotonicSeconds - previous) * 1000;
            _maximumInterval = Math.Max(_maximumInterval, milliseconds);
            _intervals.Enqueue(milliseconds);
            if (_intervals.Count > WindowCapacity) { _intervals.Dequeue(); }
        }
        _previousReception = monotonicSeconds;
    }

    public void Reject() => _rejected++;

    public void Reset()
    {
        _intervals.Clear();
        _previousReception = null;
        _accepted = _missing = _rejected = 0;
        _maximumInterval = 0;
    }

    public SensorTimingSnapshot Snapshot()
    {
        var sorted = _intervals.Order().ToArray();
        var mean = sorted.Length == 0 ? 0 : sorted.Average();
        var deviation = sorted.Length == 0 ? 0
            : Math.Sqrt(sorted.Average(value => Math.Pow(value - mean, 2)));
        double Percentile(double fraction) => sorted.Length == 0 ? 0
            : sorted[Math.Max(0, (int)Math.Ceiling(fraction * sorted.Length) - 1)];
        return new(_accepted, _missing, _rejected, sorted.Length,
            Percentile(0.5), Percentile(0.95), _maximumInterval, deviation);
    }
}
