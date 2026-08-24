using MotionCue.Sensors;

namespace MotionCue.Simulation;

public enum PhoneImuSimulationScenario
{
    FullDemo,
    Accelerate,
    Brake,
    TurnLeft,
    TurnRight,
    Neutral,
    Dropout
}

public static class PhoneImuSimulationScenarios
{
    public static IReadOnlyList<SensorFrame?> Create(PhoneImuSimulationScenario scenario, uint startingSequence = 0)
    {
        var builder = new Builder(startingSequence);
        return scenario switch
        {
            PhoneImuSimulationScenario.FullDemo => builder
                .Frames(0, 0, 15)
                .Frames(1.5f, 0, 30)
                .Frames(0, 0, 12)
                .Frames(0, -1.2f, 30)
                .Frames(0, 1.2f, 30)
                .Frames(-1.5f, 0, 30)
                .Frames(0, 0, 15)
                .Build(),
            PhoneImuSimulationScenario.Accelerate => builder.Frames(1.5f, 0, 50).Build(),
            PhoneImuSimulationScenario.Brake => builder.Frames(-1.5f, 0, 50).Build(),
            PhoneImuSimulationScenario.TurnLeft => builder.Frames(0, -1.2f, 50).Build(),
            PhoneImuSimulationScenario.TurnRight => builder.Frames(0, 1.2f, 50).Build(),
            PhoneImuSimulationScenario.Neutral => builder.Frames(0, 0, 50).Build(),
            PhoneImuSimulationScenario.Dropout => builder.Frames(1.5f, 0, 15).Dropout(30).Frames(0, 0, 15).Build(),
            _ => throw new ArgumentOutOfRangeException(nameof(scenario), scenario, null)
        };
    }

    private sealed class Builder(uint sequence)
    {
        private readonly List<SensorFrame?> _frames = [];
        private uint _sequence = sequence;
        private uint _elapsedMilliseconds;

        public Builder Frames(float longitudinal, float lateral, int count)
        {
            for (var i = 0; i < count; i++)
            {
                _frames.Add(new SensorFrame(
                    _sequence++,
                    _elapsedMilliseconds,
                    SensorFrameFlags.Calibrated | SensorFrameFlags.QuaternionValid,
                    new SensorVector3(longitudinal, lateral, 0),
                    new SensorVector3(0, 0, 0),
                    new SensorVector3(0, 0, 9.80665f),
                    new SensorQuaternion(1, 0, 0, 0),
                    SensorAccuracy.High));
                _elapsedMilliseconds += 40;
            }
            return this;
        }

        public Builder Dropout(int framePeriods)
        {
            for (var i = 0; i < framePeriods; i++)
            {
                _frames.Add(null);
                _elapsedMilliseconds += 40;
            }
            return this;
        }

        public IReadOnlyList<SensorFrame?> Build() => _frames;
    }
}
