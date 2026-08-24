using MotionCue.Motion;
using MotionCue.Sensors;
using MotionCue.Simulation;

namespace MotionCue.Tests;

public sealed class PhoneImuEstimatorTests
{
    private static readonly DateTimeOffset Start = new(2026, 8, 20, 0, 0, 0, TimeSpan.Zero);

    [Fact]
    public void VehicleAxes_MapToLongitudinalAndLateralSignals()
    {
        var estimator = new PhoneImuEstimator(new PhoneImuTuningOptions { MotionSmoothingTimeConstantSeconds = 0.01 });

        var state = estimator.Process(Frame(1, 40, 1.5f, -1.2f), Start);

        Assert.True(state.SampleAccepted);
        Assert.True(state.LongitudinalFiltered > 0);
        Assert.True(state.LateralFiltered < 0);
    }

    [Fact]
    public void DeadZoneSuppressesSmallAccelerationNoise()
    {
        var state = new PhoneImuEstimator().Process(Frame(1, 40, 0.04f, -0.04f), Start);

        Assert.Equal(0, state.LongitudinalRaw);
        Assert.Equal(0, state.LateralRaw);
    }

    [Fact]
    public void UncalibratedFrameIsRejectedWithoutChangingCueSignal()
    {
        var estimator = new PhoneImuEstimator();
        var accepted = estimator.Process(Frame(1, 40, 1.5f, 0), Start);
        var invalid = Frame(2, 80, -1.5f, 0) with { Flags = SensorFrameFlags.QuaternionValid };

        var rejected = estimator.Process(invalid, Start.AddMilliseconds(40));

        Assert.False(rejected.SampleAccepted);
        Assert.Equal(accepted.LongitudinalFiltered, rejected.LongitudinalFiltered);
        Assert.Contains("not calibrated", rejected.SampleStatus, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void NeutralizeImmediatelyClearsResidualMotion()
    {
        var estimator = new PhoneImuEstimator();
        estimator.Process(Frame(1, 40, 1.5f, 0), Start);

        var neutral = estimator.Neutralize(Start.AddMilliseconds(300), disconnected: false);

        Assert.Equal(0, neutral.LongitudinalFiltered);
        Assert.Equal(0, neutral.LateralFiltered);
        Assert.True(neutral.AutomaticCuesActive);
    }

    [Fact]
    public void DisconnectNeutralizesAndDisablesAutomaticCues()
    {
        var estimator = new PhoneImuEstimator();
        estimator.Process(Frame(1, 40, 1.5f, 0), Start);

        var disconnected = estimator.Neutralize(Start.AddSeconds(1), disconnected: true);

        Assert.Equal(0, disconnected.LongitudinalFiltered);
        Assert.False(disconnected.AutomaticCuesActive);
        Assert.Equal(0, disconnected.ActivationConfidence);
    }

    [Fact]
    public void VirtualDropoutProvidesEnoughTimeForBothWatchdogThresholds()
    {
        var frames = PhoneImuSimulationScenarios.Create(PhoneImuSimulationScenario.Dropout);
        var consecutiveMissing = frames.SkipWhile(frame => frame is not null).TakeWhile(frame => frame is null).Count();

        Assert.True(consecutiveMissing * 40 >= 1000);
    }

    private static SensorFrame Frame(uint sequence, uint elapsed, float longitudinal, float lateral) => new(
        sequence,
        elapsed,
        SensorFrameFlags.Calibrated | SensorFrameFlags.QuaternionValid,
        new SensorVector3(longitudinal, lateral, 0),
        new SensorVector3(0, 0, 0),
        new SensorVector3(0, 0, 9.80665f),
        new SensorQuaternion(1, 0, 0, 0),
        SensorAccuracy.High);
}
