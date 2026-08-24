using System.Buffers.Binary;

namespace MotionCue.Sensors;

public enum SensorFrameDecodeError
{
    None,
    InvalidLength,
    InvalidMagic,
    UnsupportedVersion,
    CrcMismatch,
    InvalidAccuracy,
    InvalidQuaternion
}

public static class SensorFrameCodec
{
    public const int EncodedLength = 42;
    public const byte ProtocolVersion = 1;
    public const ushort Magic = 0x434D; // Little-endian bytes: 'M', 'C'.

    private const float AccelerationScale = 4096f;
    private const float RotationRateScale = 4096f;
    private const float GravityScale = 2048f;
    private const float QuaternionScale = 32767f;

    public static byte[] Encode(SensorFrame frame)
    {
        Validate(frame);
        var bytes = new byte[EncodedLength];
        var span = bytes.AsSpan();
        BinaryPrimitives.WriteUInt16LittleEndian(span, Magic);
        span[2] = ProtocolVersion;

        var flags = frame.Flags;
        BinaryPrimitives.WriteUInt32LittleEndian(span[4..], frame.Sequence);
        BinaryPrimitives.WriteUInt32LittleEndian(span[8..], frame.ElapsedMilliseconds);

        if (WriteVector(span[12..18], frame.UserAccelerationMetersPerSecondSquared, AccelerationScale))
        {
            flags |= SensorFrameFlags.AccelerationSaturated;
        }
        if (WriteVector(span[18..24], frame.RotationRateRadiansPerSecond, RotationRateScale))
        {
            flags |= SensorFrameFlags.RotationRateSaturated;
        }
        if (WriteVector(span[24..30], frame.GravityMetersPerSecondSquared, GravityScale))
        {
            flags |= SensorFrameFlags.GravitySaturated;
        }

        WriteQuaternion(span[30..38], frame.OrientationFromCalibration);
        span[3] = (byte)flags;
        span[38] = (byte)frame.Accuracy;
        span[39] = 0;
        BinaryPrimitives.WriteUInt16LittleEndian(span[40..], ComputeCrc16Ccitt(span[..40]));
        return bytes;
    }

    public static bool TryDecode(
        ReadOnlySpan<byte> bytes,
        out SensorFrame frame,
        out SensorFrameDecodeError error)
    {
        frame = default;
        if (bytes.Length != EncodedLength)
        {
            error = SensorFrameDecodeError.InvalidLength;
            return false;
        }
        if (BinaryPrimitives.ReadUInt16LittleEndian(bytes) != Magic)
        {
            error = SensorFrameDecodeError.InvalidMagic;
            return false;
        }
        if (bytes[2] != ProtocolVersion)
        {
            error = SensorFrameDecodeError.UnsupportedVersion;
            return false;
        }
        if (BinaryPrimitives.ReadUInt16LittleEndian(bytes[40..]) != ComputeCrc16Ccitt(bytes[..40]))
        {
            error = SensorFrameDecodeError.CrcMismatch;
            return false;
        }
        if (bytes[38] > (byte)SensorAccuracy.High)
        {
            error = SensorFrameDecodeError.InvalidAccuracy;
            return false;
        }

        var quaternion = ReadQuaternion(bytes[30..38]);
        var flags = (SensorFrameFlags)bytes[3];
        if (flags.HasFlag(SensorFrameFlags.QuaternionValid)
            && quaternion.Norm is < 0.9f or > 1.1f)
        {
            error = SensorFrameDecodeError.InvalidQuaternion;
            return false;
        }

        frame = new SensorFrame(
            BinaryPrimitives.ReadUInt32LittleEndian(bytes[4..]),
            BinaryPrimitives.ReadUInt32LittleEndian(bytes[8..]),
            flags,
            ReadVector(bytes[12..18], AccelerationScale),
            ReadVector(bytes[18..24], RotationRateScale),
            ReadVector(bytes[24..30], GravityScale),
            quaternion,
            (SensorAccuracy)bytes[38]);
        error = SensorFrameDecodeError.None;
        return true;
    }

    public static ushort ComputeCrc16Ccitt(ReadOnlySpan<byte> bytes)
    {
        ushort crc = 0xFFFF;
        foreach (var value in bytes)
        {
            crc ^= (ushort)(value << 8);
            for (var bit = 0; bit < 8; bit++)
            {
                crc = (ushort)((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1);
            }
        }
        return crc;
    }

    private static void Validate(SensorFrame frame)
    {
        if (!frame.UserAccelerationMetersPerSecondSquared.IsFinite
            || !frame.RotationRateRadiansPerSecond.IsFinite
            || !frame.GravityMetersPerSecondSquared.IsFinite)
        {
            throw new ArgumentException("Sensor vectors must contain finite values.", nameof(frame));
        }
        if (!frame.OrientationFromCalibration.IsFinite)
        {
            throw new ArgumentException("Quaternion must contain finite values.", nameof(frame));
        }
        if (frame.Flags.HasFlag(SensorFrameFlags.QuaternionValid)
            && frame.OrientationFromCalibration.Norm is < 0.9f or > 1.1f)
        {
            throw new ArgumentException("A valid quaternion flag requires a normalized quaternion.", nameof(frame));
        }
        if (frame.Accuracy > SensorAccuracy.High)
        {
            throw new ArgumentOutOfRangeException(nameof(frame), "Sensor accuracy value is unsupported.");
        }
    }

    private static bool WriteVector(Span<byte> destination, SensorVector3 vector, float scale)
    {
        var saturated = false;
        saturated |= WriteQuantized(destination, vector.X, scale);
        saturated |= WriteQuantized(destination[2..], vector.Y, scale);
        saturated |= WriteQuantized(destination[4..], vector.Z, scale);
        return saturated;
    }

    private static SensorVector3 ReadVector(ReadOnlySpan<byte> source, float scale) => new(
        BinaryPrimitives.ReadInt16LittleEndian(source) / scale,
        BinaryPrimitives.ReadInt16LittleEndian(source[2..]) / scale,
        BinaryPrimitives.ReadInt16LittleEndian(source[4..]) / scale);

    private static void WriteQuaternion(Span<byte> destination, SensorQuaternion quaternion)
    {
        WriteQuantized(destination, quaternion.W, QuaternionScale);
        WriteQuantized(destination[2..], quaternion.X, QuaternionScale);
        WriteQuantized(destination[4..], quaternion.Y, QuaternionScale);
        WriteQuantized(destination[6..], quaternion.Z, QuaternionScale);
    }

    private static SensorQuaternion ReadQuaternion(ReadOnlySpan<byte> source) => new(
        BinaryPrimitives.ReadInt16LittleEndian(source) / QuaternionScale,
        BinaryPrimitives.ReadInt16LittleEndian(source[2..]) / QuaternionScale,
        BinaryPrimitives.ReadInt16LittleEndian(source[4..]) / QuaternionScale,
        BinaryPrimitives.ReadInt16LittleEndian(source[6..]) / QuaternionScale);

    private static bool WriteQuantized(Span<byte> destination, float value, float scale)
    {
        var scaled = MathF.Round(value * scale);
        var clamped = Math.Clamp(scaled, short.MinValue, short.MaxValue);
        BinaryPrimitives.WriteInt16LittleEndian(destination, (short)clamped);
        return clamped != scaled;
    }
}
