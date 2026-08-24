namespace MotionCue.Sensors;

[Flags]
public enum SensorFrameFlags : byte
{
    None = 0,
    Calibrated = 1 << 0,
    AccelerationSaturated = 1 << 1,
    RotationRateSaturated = 1 << 2,
    GravitySaturated = 1 << 3,
    QuaternionValid = 1 << 4,
    SensorUnreliable = 1 << 5,
    ClockReset = 1 << 6
}

public enum SensorAccuracy : byte
{
    Unknown = 0,
    Unreliable = 1,
    Low = 2,
    Medium = 3,
    High = 4
}

public readonly record struct SensorVector3(float X, float Y, float Z)
{
    public bool IsFinite => float.IsFinite(X) && float.IsFinite(Y) && float.IsFinite(Z);
}

public readonly record struct SensorQuaternion(float W, float X, float Y, float Z)
{
    public bool IsFinite => float.IsFinite(W) && float.IsFinite(X) && float.IsFinite(Y) && float.IsFinite(Z);

    public float Norm => MathF.Sqrt((W * W) + (X * X) + (Y * Y) + (Z * Z));
}

public readonly record struct SensorFrame(
    uint Sequence,
    uint ElapsedMilliseconds,
    SensorFrameFlags Flags,
    SensorVector3 UserAccelerationMetersPerSecondSquared,
    SensorVector3 RotationRateRadiansPerSecond,
    SensorVector3 GravityMetersPerSecondSquared,
    SensorQuaternion OrientationFromCalibration,
    SensorAccuracy Accuracy);

public static class SensorGattProfile
{
    public static readonly Guid ServiceUuid = new("ab31792d-ffdc-4289-88f2-40e384daacb8");
    public static readonly Guid SensorFrameCharacteristicUuid = new("8d747a89-0992-4d86-8fbe-18d2608edc1c");
    public static readonly Guid ControlCharacteristicUuid = new("c64b31d3-4ff6-4237-bf55-5a94df0f4324");
}
