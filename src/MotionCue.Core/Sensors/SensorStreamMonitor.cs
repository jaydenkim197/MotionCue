namespace MotionCue.Sensors;

public enum SensorFrameDisposition
{
    Accepted,
    AcceptedWithGap,
    Duplicate,
    OutOfOrder
}

public readonly record struct SensorStreamObservation(
    SensorFrameDisposition Disposition,
    uint MissingBeforeFrame,
    ulong AcceptedFrames,
    ulong MissingFrames,
    ulong DuplicateFrames,
    ulong OutOfOrderFrames)
{
    public double EstimatedPacketLossRate => AcceptedFrames + MissingFrames == 0
        ? 0
        : (double)MissingFrames / (AcceptedFrames + MissingFrames);
}

public sealed class SensorSequenceTracker
{
    private uint? _lastAcceptedSequence;
    private ulong _accepted;
    private ulong _missing;
    private ulong _duplicates;
    private ulong _outOfOrder;

    public SensorStreamObservation Observe(uint sequence)
    {
        if (_lastAcceptedSequence is null)
        {
            _lastAcceptedSequence = sequence;
            _accepted++;
            return Create(SensorFrameDisposition.Accepted, 0);
        }

        var last = _lastAcceptedSequence.Value;
        if (sequence == last)
        {
            _duplicates++;
            return Create(SensorFrameDisposition.Duplicate, 0);
        }

        var expected = unchecked(last + 1);
        var forwardDistance = unchecked(sequence - expected);
        if (forwardDistance < 0x80000000u)
        {
            _lastAcceptedSequence = sequence;
            _accepted++;
            _missing += forwardDistance;
            return Create(
                forwardDistance == 0 ? SensorFrameDisposition.Accepted : SensorFrameDisposition.AcceptedWithGap,
                forwardDistance);
        }

        _outOfOrder++;
        return Create(SensorFrameDisposition.OutOfOrder, 0);
    }

    public void Reset()
    {
        _lastAcceptedSequence = null;
        _accepted = 0;
        _missing = 0;
        _duplicates = 0;
        _outOfOrder = 0;
    }

    private SensorStreamObservation Create(SensorFrameDisposition disposition, uint missingBeforeFrame) =>
        new(disposition, missingBeforeFrame, _accepted, _missing, _duplicates, _outOfOrder);
}

public enum SensorLinkState
{
    Waiting,
    Streaming,
    Neutralizing,
    Disconnected
}

public sealed class SensorLinkWatchdog
{
    private DateTimeOffset? _lastFrameReceivedAt;

    public SensorLinkWatchdog(TimeSpan? neutralAfter = null, TimeSpan? disconnectedAfter = null)
    {
        NeutralAfter = neutralAfter ?? TimeSpan.FromMilliseconds(250);
        DisconnectedAfter = disconnectedAfter ?? TimeSpan.FromSeconds(1);
        if (NeutralAfter <= TimeSpan.Zero || DisconnectedAfter <= NeutralAfter)
        {
            throw new ArgumentOutOfRangeException(nameof(neutralAfter), "Disconnect threshold must be greater than the positive neutral threshold.");
        }
    }

    public TimeSpan NeutralAfter { get; }
    public TimeSpan DisconnectedAfter { get; }

    public void Observe(DateTimeOffset receivedAt) => _lastFrameReceivedAt = receivedAt;

    public SensorLinkState Evaluate(DateTimeOffset now)
    {
        if (_lastFrameReceivedAt is null)
        {
            return SensorLinkState.Waiting;
        }
        var age = now - _lastFrameReceivedAt.Value;
        if (age >= DisconnectedAfter)
        {
            return SensorLinkState.Disconnected;
        }
        return age >= NeutralAfter ? SensorLinkState.Neutralizing : SensorLinkState.Streaming;
    }

    public void Reset() => _lastFrameReceivedAt = null;
}
