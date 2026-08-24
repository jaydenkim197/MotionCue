using MotionCue.Sensors;

namespace MotionCue.Motion;

public sealed class PhoneImuEstimator
{
    private readonly PhoneImuTuningOptions _options;
    private uint? _lastElapsedMilliseconds;
    private MotionState _state;

    public PhoneImuEstimator(PhoneImuTuningOptions? options = null)
    {
        _options = options ?? new PhoneImuTuningOptions();
        ValidateOptions(_options);
        _state = MotionState.Empty(DateTimeOffset.UtcNow, "Waiting for phone IMU data");
    }

    public PhoneImuTuningOptions Tuning => _options;
    public MotionState State => _state;

    public MotionState Process(SensorFrame frame, DateTimeOffset receivedAt)
    {
        if (frame.Flags.HasFlag(SensorFrameFlags.ClockReset))
        {
            _lastElapsedMilliseconds = null;
        }

        var validationError = ValidateFrame(frame);
        if (validationError is not null)
        {
            return Reject(receivedAt, validationError);
        }

        var interval = GetSampleInterval(frame.ElapsedMilliseconds);
        if (interval > _options.MaximumAcceptedSampleInterval)
        {
            _lastElapsedMilliseconds = frame.ElapsedMilliseconds;
            return Reject(receivedAt, "Phone IMU sender interval exceeded the accepted limit");
        }

        var acceleration = frame.UserAccelerationMetersPerSecondSquared;
        var longitudinalRaw = Normalize(
            acceleration.X,
            _options.LongitudinalDeadZoneMetersPerSecondSquared,
            _options.MaximumLongitudinalAccelerationMetersPerSecondSquared);
        var lateralRaw = Normalize(
            acceleration.Y,
            _options.LateralDeadZoneMetersPerSecondSquared,
            _options.MaximumLateralAccelerationMetersPerSecondSquared);
        var alpha = 1 - Math.Exp(-interval.TotalSeconds / _options.MotionSmoothingTimeConstantSeconds);
        var longitudinalFiltered = Lerp(_state.LongitudinalFiltered, longitudinalRaw, alpha);
        var lateralFiltered = Lerp(_state.LateralFiltered, lateralRaw, alpha);
        var confidence = AccuracyConfidence(frame.Accuracy);

        _lastElapsedMilliseconds = frame.ElapsedMilliseconds;
        _state = new MotionState(
            receivedAt,
            true,
            "Phone IMU frame accepted; calibration and gains remain provisional until Study A",
            longitudinalRaw,
            lateralRaw,
            longitudinalFiltered,
            lateralFiltered,
            confidence,
            true,
            interval);
        return _state;
    }

    public MotionState Neutralize(DateTimeOffset now, bool disconnected)
    {
        _state = _state with
        {
            Timestamp = now,
            SampleAccepted = false,
            SampleStatus = disconnected
                ? "Phone IMU link disconnected; cues forced to neutral"
                : "Phone IMU frame overdue; cues forced to neutral",
            LongitudinalRaw = 0,
            LateralRaw = 0,
            LongitudinalFiltered = 0,
            LateralFiltered = 0,
            ActivationConfidence = disconnected ? 0 : _state.ActivationConfidence,
            AutomaticCuesActive = !disconnected,
            SampleInterval = null
        };
        return _state;
    }

    public void Reset(DateTimeOffset? timestamp = null)
    {
        _lastElapsedMilliseconds = null;
        _state = MotionState.Empty(timestamp ?? DateTimeOffset.UtcNow, "Waiting for phone IMU data");
    }

    private TimeSpan GetSampleInterval(uint elapsedMilliseconds)
    {
        if (_lastElapsedMilliseconds is null)
        {
            return _options.NominalSampleInterval;
        }

        var delta = unchecked(elapsedMilliseconds - _lastElapsedMilliseconds.Value);
        return delta == 0 ? TimeSpan.Zero : TimeSpan.FromMilliseconds(delta);
    }

    private string? ValidateFrame(SensorFrame frame)
    {
        if (!frame.UserAccelerationMetersPerSecondSquared.IsFinite
            || !frame.RotationRateRadiansPerSecond.IsFinite
            || !frame.GravityMetersPerSecondSquared.IsFinite
            || !frame.OrientationFromCalibration.IsFinite)
        {
            return "Phone IMU frame contains a non-finite value";
        }
        if (!frame.Flags.HasFlag(SensorFrameFlags.Calibrated))
        {
            return "Phone IMU frame is not calibrated to the vehicle axes";
        }
        if (!frame.Flags.HasFlag(SensorFrameFlags.QuaternionValid))
        {
            return "Phone IMU orientation reference is invalid";
        }
        if (frame.Flags.HasFlag(SensorFrameFlags.SensorUnreliable)
            || frame.Flags.HasFlag(SensorFrameFlags.AccelerationSaturated)
            || frame.Accuracy == SensorAccuracy.Unreliable)
        {
            return "Phone IMU acceleration is unreliable";
        }
        return null;
    }

    private MotionState Reject(DateTimeOffset timestamp, string reason)
    {
        _state = _state with
        {
            Timestamp = timestamp,
            SampleAccepted = false,
            SampleStatus = reason
        };
        return _state;
    }

    private static double Normalize(double value, double deadZone, double maximum)
    {
        var magnitude = Math.Abs(value);
        if (magnitude <= deadZone)
        {
            return 0;
        }
        var normalized = (magnitude - deadZone) / (maximum - deadZone);
        return Math.CopySign(Math.Clamp(normalized, 0, 1), value);
    }

    private static double Lerp(double previous, double next, double alpha) =>
        Math.Clamp(previous + ((next - previous) * alpha), -1, 1);

    private static double AccuracyConfidence(SensorAccuracy accuracy) => accuracy switch
    {
        SensorAccuracy.High => 1,
        SensorAccuracy.Medium => 0.8,
        SensorAccuracy.Low => 0.6,
        _ => 0.4
    };

    private static void ValidateOptions(PhoneImuTuningOptions options)
    {
        if (options.LongitudinalDeadZoneMetersPerSecondSquared < 0
            || options.LateralDeadZoneMetersPerSecondSquared < 0
            || options.MaximumLongitudinalAccelerationMetersPerSecondSquared <= options.LongitudinalDeadZoneMetersPerSecondSquared
            || options.MaximumLateralAccelerationMetersPerSecondSquared <= options.LateralDeadZoneMetersPerSecondSquared
            || options.MotionSmoothingTimeConstantSeconds <= 0
            || options.NominalSampleInterval <= TimeSpan.Zero
            || options.MaximumAcceptedSampleInterval <= TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(nameof(options), "Phone IMU tuning constants must be positive and maxima must exceed dead zones.");
        }
    }
}
