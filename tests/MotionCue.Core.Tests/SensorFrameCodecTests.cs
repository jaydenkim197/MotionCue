using MotionCue.Sensors;

namespace MotionCue.Tests;

public sealed class SensorFrameCodecTests
{
    [Fact]
    public void Frame_RoundTripsWithinQuantizationTolerance()
    {
        var original = Frame(42, 1234) with
        {
            UserAccelerationMetersPerSecondSquared = new SensorVector3(1.25f, -0.75f, 0.125f),
            RotationRateRadiansPerSecond = new SensorVector3(0.02f, -0.04f, 0.5f),
            GravityMetersPerSecondSquared = new SensorVector3(0.1f, -0.2f, 9.81f),
            OrientationFromCalibration = new SensorQuaternion(0.9238795f, 0, 0, 0.3826834f)
        };

        var bytes = SensorFrameCodec.Encode(original);
        var decoded = SensorFrameCodec.TryDecode(bytes, out var actual, out var error);

        Assert.True(decoded);
        Assert.Equal(SensorFrameDecodeError.None, error);
        Assert.Equal(SensorFrameCodec.EncodedLength, bytes.Length);
        Assert.Equal(original.Sequence, actual.Sequence);
        Assert.Equal(original.ElapsedMilliseconds, actual.ElapsedMilliseconds);
        AssertVector(original.UserAccelerationMetersPerSecondSquared, actual.UserAccelerationMetersPerSecondSquared, 1f / 4096);
        AssertVector(original.GravityMetersPerSecondSquared, actual.GravityMetersPerSecondSquared, 1f / 2048);
        Assert.InRange(Math.Abs(original.OrientationFromCalibration.W - actual.OrientationFromCalibration.W), 0, 1f / 32767);
    }

    [Fact]
    public void CorruptedFrame_IsRejectedByCrc()
    {
        var bytes = SensorFrameCodec.Encode(Frame(1, 0));
        bytes[18] ^= 0x40;

        var decoded = SensorFrameCodec.TryDecode(bytes, out _, out var error);

        Assert.False(decoded);
        Assert.Equal(SensorFrameDecodeError.CrcMismatch, error);
    }

    [Fact]
    public void OutOfRangeAcceleration_IsClampedAndMarkedSaturated()
    {
        var bytes = SensorFrameCodec.Encode(Frame(1, 0) with
        {
            UserAccelerationMetersPerSecondSquared = new SensorVector3(20, 0, 0)
        });

        Assert.True(SensorFrameCodec.TryDecode(bytes, out var decoded, out _));
        Assert.True(decoded.Flags.HasFlag(SensorFrameFlags.AccelerationSaturated));
        Assert.InRange(decoded.UserAccelerationMetersPerSecondSquared.X, 7.99f, 8.01f);
    }

    [Fact]
    public void InvalidQuaternion_IsRejectedBeforeEncoding()
    {
        var invalid = Frame(1, 0) with
        {
            OrientationFromCalibration = new SensorQuaternion(0.2f, 0, 0, 0)
        };

        Assert.Throws<ArgumentException>(() => SensorFrameCodec.Encode(invalid));
    }

    private static SensorFrame Frame(uint sequence, uint elapsedMilliseconds) => new(
        sequence,
        elapsedMilliseconds,
        SensorFrameFlags.Calibrated | SensorFrameFlags.QuaternionValid,
        new SensorVector3(0, 0, 0),
        new SensorVector3(0, 0, 0),
        new SensorVector3(0, 0, 9.81f),
        new SensorQuaternion(1, 0, 0, 0),
        SensorAccuracy.High);

    private static void AssertVector(SensorVector3 expected, SensorVector3 actual, float tolerance)
    {
        Assert.InRange(Math.Abs(expected.X - actual.X), 0, tolerance);
        Assert.InRange(Math.Abs(expected.Y - actual.Y), 0, tolerance);
        Assert.InRange(Math.Abs(expected.Z - actual.Z), 0, tolerance);
    }
}
