namespace MotionCue.Motion;

public sealed record PhoneImuTuningOptions
{
    public double LongitudinalDeadZoneMetersPerSecondSquared { get; init; } = 0.08;
    public double LateralDeadZoneMetersPerSecondSquared { get; init; } = 0.08;
    public double MaximumLongitudinalAccelerationMetersPerSecondSquared { get; init; } = 3.0;
    public double MaximumLateralAccelerationMetersPerSecondSquared { get; init; } = 3.0;
    public double MotionSmoothingTimeConstantSeconds { get; init; } = 0.20;
    public TimeSpan NominalSampleInterval { get; init; } = TimeSpan.FromMilliseconds(40);
    public TimeSpan MaximumAcceptedSampleInterval { get; init; } = TimeSpan.FromSeconds(1);
}
